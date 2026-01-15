-- This module serves as the root of the `LeanSlop` library.
-- Import modules here that should be built as part of the library.
import LeanSlop.Syntax
import LeanSlop.Types
import LeanSlop.Options
import LeanSlop.Prompt
import Lean.Elab
open Lean Elab Meta

namespace LeanSlop.API

inductive Provider where
| claude
| openai
deriving BEq, Repr

structure APIParameters where
  api_key: String
  url: String
  provider: Provider
deriving BEq, Repr

def getProviderBackend (model: String): MetaM Provider := do
   if model.startsWith "gpt"
   then pure .openai
   else if model.startsWith "claude" ||  model.startsWith "sonnet" || model.startsWith "opus"
   then pure .claude
   else throwError "unknown provider for model {model}"

def getAPIParameters (backend: Provider) : MetaM APIParameters := do
  let is_claude := backend == .claude
  let (api_key_var, api_url) :=
    if is_claude
    then ("ANTHROPIC_API_KEY", "https://api.anthropic.com/v1/messages")
    else ("OPENAI_API_KEY", "https://api.openai.com/v1/chat/completions")
    match ← IO.getEnv api_key_var with
    | some k => pure {provider := backend, api_key:= k, url:=api_url}
    | none => throwError "{api_key_var} not set"

def makeBaseRequest (model: String) (messages: List LeanSlop.Message) : MetaM (Task (Except IO.Error String)) := do
  let provider <- getProviderBackend model
  let params <- getAPIParameters provider
  let messages :=
    if provider == .claude
    then messages.map (fun message => {
       message with
         role :=
           if message.role == .system
           then .assistant
           else message.role
    })
    else messages
  let request : LeanSlop.Request := {
      model:= model,
      max_tokens:=1024,
      messages := messages
   }
  let payload := toJson request
  let mut args := #[
      "-s",
      "-X","POST", params.url,
      "-H",
        if params.provider == .openai
        then s!"Authorization: Bearer {params.api_key}"
        else s!"x-api-key: {params.api_key}",
      "-H","Content-Type: application/json",
      "-d", payload.compress
    ]
  if params.provider == .claude then
    args := args.push "-H"
    args := args.push "anthropic-version: 2023-06-01"
  return <- IO.asTask do
    let resp ← IO.Process.run {
      cmd := "curl"
      args := args
    }
    let (.ok resp) :=
       if params.provider == .claude
       then LeanSlop.Claude.extractModelResponse resp
       else LeanSlop.OpenAI.extractModelResponse resp
      | .error s!"failed to decode response from LLM {resp}"

    let (.some leanCode) := LeanSlop.Prompt.extractLeanBlock resp
      | .error s!"no ```lean block found in response from LLM"

    return (leanCode)

def makeCheapRequest (messages: List LeanSlop.Message) := do
   let opts <- getOptions
   let model := slop.cheap_model.get opts
   let prompt := slop.cheap_system_prompt.get opts
   let messages :=
     [
        ({role:= .system, content:=prompt}: LeanSlop.Message),
      ] ++ messages
   makeBaseRequest model messages

def makeRequest (messages: List LeanSlop.Message) := do
   let opts <- getOptions
   let model := slop.model.get opts
   let prompt := slop.system_prompt.get opts
   let messages :=
     [
        ({role:= .system, content:=prompt}: LeanSlop.Message),
      ] ++ messages
   makeBaseRequest model messages

end LeanSlop.API
