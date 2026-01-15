import Lean
import LeanSlop.API
import LeanSlop.Types
open Lean Elab

namespace LeanSlop.Eval

/-- Attempt to generate a tactic from the LLM and evaluate it -/
def attemptTactic (cheap: Bool :=False) (env : Environment) (prompt : List LeanSlop.Message) : Tactic.TacticM AttemptResult := do
  -- Request code from LLM
  let leanCodeTask ← if cheap then LeanSlop.API.makeCheapRequest prompt else LeanSlop.API.makeRequest prompt
  let (.ok leanCode) := leanCodeTask.get | return .requestError "subtask failed"
  
  -- Try to parse the response
  match Parser.runParserCategory env `tactic leanCode with
  | .error parseErr =>
    return .parseError leanCode parseErr
  | .ok newStx =>
    -- Try to evaluate the tactic
    let savedState ← saveState
    try
      Tactic.evalTactic newStx
      return .success leanCode
    catch e =>
      restoreState savedState
      let errorMsg ← e.toMessageData.toString
      return .tacticError leanCode errorMsg


end LeanSlop.Eval
