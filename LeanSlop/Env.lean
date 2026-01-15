import Lean
import Lean.Elab
open Lean Elab Meta

namespace LeanSlop.Env

def printName (id: Name) : MetaM String := do
  let env <- getEnv
  let (.some cinfo) := env.find? id | return ""
  if cinfo.isInductive then
    let elts := cinfo.inductiveVal!
    let ctors <-
      elts.ctors.mapM fun name => do
        let (.some cinfo) := env.find? name | return ""
        let tyfmt <- PrettyPrinter.ppExpr cinfo.type
        return s!"  | {name} : {tyfmt}"
    let ctors := ctors.intersperse "\n" |> String.join
    let ctors := if ctors != "" then "\n" ++ ctors else ""
    return s!"inductive {id} where {ctors}"
  else
    let defn := cinfo.value?
    let defnfmt <- defn.mapM PrettyPrinter.ppExpr
    let defnfmt := defnfmt.getD ("sorry -- hidden")
    let tyfmt <- PrettyPrinter.ppExpr cinfo.type
    return s!"def {id} : {tyfmt} := {defnfmt}"

def getEvalContext (goal: MVarId) : MetaM String := do
  let used : Std.HashSet Name ←
    Widget.withGoalCtx goal (fun lctx mctx => do
      Meta.withLCtx lctx mctx.localInstances do
        let mut acc := {}
        for decl in lctx do
          acc := acc.insert decl.userName
        for c in mctx.type.getUsedConstants do
          acc := acc.insert c
        return acc)
  let defs <- used.toList.mapM (fun name => printName name)
  let defs := defs.intersperse "\n" |> String.join
  return defs


end LeanSlop.Env

