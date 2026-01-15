-- This module serves as the root of the `LeanSlop` library.
-- Import modules here that should be built as part of the library.
import LeanSlop.Eval
open Lean Elab Meta

def evalAndRefineLLMPrompt  (cheap: Bool :=False)
  (attempts: Nat)
  (prompt : List LeanSlop.Message)
  (env: Environment)
  : Tactic.TacticM String := do
    let result ← LeanSlop.Eval.attemptTactic cheap env prompt
    if let (.success leanCode) := result then
      return leanCode
    if attempts > 0 then
      dbg_trace s!"failed with {repr result}"
      let newPrompt := LeanSlop.Prompt.appendErrorFeedback prompt result
      evalAndRefineLLMPrompt cheap (attempts - 1) newPrompt env
    else
      logInfo "leanSlop? had errors, but returning suggestion"
      match result with
      | .tacticError code _ => return code
      | .parseError code _ => return code
      | _ => throwError "leanSlop failed to produce any useful output"


elab_rules : tactic
| `(tactic| slop?) => do
  let env <- getEnv
  let stx <- getRef
  let prompt <- LeanSlop.Prompt.makeUserPromptAtPoint
  let maxAttempts := slop.max_refine_attempts.get (<- getOptions)
  let leanCode <- evalAndRefineLLMPrompt False maxAttempts prompt env
  Tactic.TryThis.addSuggestion stx ({
     suggestion:=.string leanCode
     }: Tactic.TryThis.Suggestion)
  return


elab_rules : tactic
| `(tactic| plap?) => do
  let env <- getEnv
  let stx <- getRef
  let prompt <- LeanSlop.Prompt.makeUserPromptAtPoint
  let leanCode <- evalAndRefineLLMPrompt True 0 prompt env
  Tactic.TryThis.addSuggestion stx ({
     suggestion:=.string leanCode
     }: Tactic.TryThis.Suggestion)
  let (.ok newStx) :=
      Parser.runParserCategory
        env `tactic leanCode
    | throwError "failed to parse"
  Tactic.evalTactic newStx

