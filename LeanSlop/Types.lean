import Lean
open Lean

namespace LeanSlop

inductive Role where
| user
| system
| assistant
deriving Repr,BEq,ToJson,FromJson

structure Message where
  role: Role
  content: String
deriving Repr, ToJson,FromJson

structure Request where
  model: String
  max_tokens: Int
  messages: List Message
deriving Repr, ToJson, FromJson

namespace Claude

inductive ContentType where
| text
deriving Repr, ToJson, FromJson

structure Content where
  type: ContentType
  text: String
deriving Repr, ToJson, FromJson

structure Response where
  id : String
  type: String
  role: Role
  content: List Content
  model: String
deriving Repr, ToJson, FromJson

def extractModelResponse (s: String) := do
  let res <- Json.parse s
  let res : Response <- FromJson.fromJson? res
  let res :=
    res.content.map (fun v => Content.text v)
    |> List.intersperse "\\n"
    |> String.join
  return res

end Claude

namespace OpenAI

structure Message where
  content: String
  role: Role
deriving Repr, ToJson, FromJson

structure Choice where
  message: Message
deriving Repr, ToJson, FromJson

structure Response where
  id: String
  choices: List Choice
deriving Repr, ToJson, FromJson

def extractModelResponse (s: String) := do
  let res <- Json.parse s
  let res : Response <- FromJson.fromJson? res
  let (.some choice) := res.choices[0]? | Except.error "empty choices"
  return choice.message.content

end OpenAI

namespace Eval
inductive AttemptResult
  | success (suggestion : String)
  | parseError (code : String) (error : String)
  | tacticError (code : String) (error : String)
  | requestError (error : String)
deriving BEq, Repr, ToJson, FromJson

end Eval
end LeanSlop

