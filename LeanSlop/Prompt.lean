-- Utilities for working with the prompt
import Lean.Elab
import LeanSlop.Env
import LeanSlop.Types
open Lean Elab Meta

namespace LeanSlop.Prompt

def extractLeanBlock (s : String) : Option String := do
  let (.some start) := s.find? "```lean" | .none
  let s := start.extract s.endValidPos
  let (.some start) := s.find? "lean" | .none
  let s := start.extract s.endValidPos
  let (.some end_) := s.find? "```" | .none
  let s := s.startValidPos.extract end_
  return s.drop 4 |>.trim

def getPrefix : MetaM String := do
  let stx ← getRef
  let fmap ← getFileMap
  let (.some startPos) := stx.getPos? | throwError "no source info for {stx}"
  let prefix_ := (0: String.Pos.Raw).extract fmap.source startPos
  return prefix_

def makeUserPromptAtPoint : Tactic.TacticM (List LeanSlop.Message) := do
  let state ← get
  let (.some goal) := state.goals.head?
    | throwError "no goals"

  let goalStr ← Meta.ppGoal goal
  let defs_ <- LeanSlop.Env.getEvalContext goal
  let prefix_ <- getPrefix

  return [
    {role:=.user, content:=prefix_},
    {role:=.user, content:=s!"The Lean goal at this point is:\n```lean\n{goalStr}\n```"},
    {role:=.user, content:=s!"Typing context is:\n```lean\n{defs_}\n```"},
    {role:=.system, content:="Complete the proof:"},
  ]

/-- Build an updated prompt with error feedback -/
def appendErrorFeedback (prompt : List LeanSlop.Message) (result : Eval.AttemptResult) : List LeanSlop.Message :=
  match result with
  | .success _ => prompt -- shouldn't happen, but handle gracefully
  | .requestError err =>
    prompt ++ [{role := .user, content := s!"Request failed: {err}\nPlease try again."}]
  | .parseError code err =>
    prompt ++ [
      {role := .assistant, content := code},
      {role := .user, content := s!"Parse error: {err}\nYour response was:\n```lean\n{code}\n```\nPlease provide valid Lean tactic syntax."}
    ]
  | .tacticError code err =>
    prompt ++ [
      {role := .assistant, content := code},
      {role := .user, content := s!"The tactic failed with error:\n```\n{err}\n```\nYour response was:\n```lean\n{code}\n```\nPlease try a different approach."}
    ]


end LeanSlop.Prompt

