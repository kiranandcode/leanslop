import Lean

register_option slop.max_refine_attempts : Nat := {
   defValue := 3
   group := "slop"
   descr := "maximum number of times to recursively call the llm to fix broken proofs"
}


register_option slop.model : String := {
   defValue := "claude-sonnet-4-5-20250929"
   group := "slop"
   descr := "model name to use for the model"
}

register_option slop.cheap_model : String := {
   defValue := "claude-haiku-4-5-20251001"
   group := "slop"
   descr := "model name to use for the model"
}

register_option slop.system_prompt : String := {
   defValue := "You are an agent helping users complete Lean4 proofs and programs. Users will provide a prefix of a program ending with a proof script. You can NOT change the proof script prefix, and must return ONLY a completion that will complete the proof. Wrap the code in a SINGLE ```lean ``` markdown code block."
   group := "slop"
   descr := "System prompt to provide as a prefix to the model"
}

register_option slop.cheap_system_prompt : String := {
   defValue := "You are an agent helping users complete Lean4 proofs and programs. Users will provide a prefix of a program ending with a proof script. You can NOT change the proof script prefix, and must return ONLY a completion corresponding to the next tactics to progress the proof. Wrap the code in a SINGLE ```lean ``` markdown code block."
   group := "slop"
   descr := "System prompt to provide as a prefix to the model"
}

