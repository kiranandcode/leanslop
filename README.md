# LeanSlop: LLM-slop black box automation for the Lean4 theorem prover
LeanSlop is an LLM-powered proof assistant for Lean 4. It integrates
directly into your editor, allowing you to invoke AI models to help
complete proofs without leaving your workflow. 

In essence, LeanSlop works like this:

- Configure your preferred model (OpenAI, Anthropic, or others) via environment variables.
- Call `slop?` within any proof to request AI-generated tactic suggestions.
- LeanSlop analyzes your proof state, queries the model, and returns candidate tactics.
- Review suggestions inline and accept the ones that work.

## Building

With [elan](https://github.com/leanprover/elan) installed, `lake build` should suffice.

## Adding LeanSlop to Your Project

To use LeanSlop in a Lean 4 project, first add this package as a
dependency. Add the following require in your `lakefile.toml`:
```toml
[[require]]
name = "leanslop"
git = "https://github.com/kiranandcode/leanslop"
```

For lake users, instead in your `lakefile.lean`, add

```lean
require leanslop from git "https://github.com/kiranandcode/leanslop"
```

You also need to make sure that your `lean-toolchain` file contains the same version of Lean 4 as LeanSlop's.

Now set your API key as an environment variable:

```bash
export OPENAI_API_KEY="sk-..."
# or
export ANTHROPIC_API_KEY="sk-ant-..."
```

The following test file should now compile:

```lean
import LeanSlop

example : α → α := by
  slop?
```

## Quickstart

Here's a simple example demonstrating LeanSlop in action:

```lean
import LeanSlop

-- Set the model (ensure the appropriate API key is set in your environment)
set_option slop.model "gpt-4.1"

def sum_upto : Nat → Nat
  | 0 => 0
  | n + 1 => n + 1 + sum_upto n

example : 2 * sum_upto n = n * (n + 1) := by
  slop?
```

When you invoke `slop?`, LeanSlop will:

1. Serialize the current proof state (hypotheses, goal, and relevant context).
2. Query your configured LLM with a prompt designed for Lean 4 tactic generation.
3. Parse the model's response and display suggested tactics.
4. If a suggestion closes the goal, it will be highlighted for easy acceptance.

## Configuration

LeanSlop can be configured via Lean options:

| Option                     | Type   | Default                        | Description                                                               |
|----------------------------|--------|--------------------------------|---------------------------------------------------------------------------|
| `slop.model`               | String | `"claude-sonnet-4-5-20250929"` | The model to use for `slop?`                                              |
| `slop.max_refine_attempts` | Int    | `3`                            | The number of times to use Lean compiler feedback to refine LLM responses |
| `slop.cheap_model`         | String | `claude-haiku-4-5-20251001`    | The model to use for the cheaper `plap?` command.                         |
| `slop.system_prompt`       | String | ...It's a good prompt ma'am    | The system prompt to send to the LLM in each request                                                                          |

Example configuration:

```lean
set_option slop.model "claude-sonnet-4-20250514"
set_option slop.max_refine_attempts 3
```

## Supported Models

LeanSlop supports any OpenAI-compatible or Anthropic API. Set the appropriate environment variable:

| Provider  | Environment Variable | Example Models                                       |
|-----------|----------------------|------------------------------------------------------|
| OpenAI    | `OPENAI_API_KEY`     | `gpt-4.1`, `gpt-4o`, `o1`                            |
| Anthropic | `ANTHROPIC_API_KEY`  | `claude-sonnet-4-20250514`, `claude-opus-4-20250514` |

## The `slop?` Tactic

The main entry point is the `slop?` tactic. In its simplest form:

```lean
example : P → P := by
  slop?
```

The LLM is sent:
- the entire prefix of the current file so far
- the definitions of all symbols used in the goal
- the current goal state

This means you can proviude hints to the LLM by inserting comments
into your lean proof:

```lean
example : P ∧ Q → Q ∧ P := by
  -- try using And.intro and And.left/right
  slop?
```

### Accepting Suggestions

When `slop?` returns suggestions, you can:

- Click on a suggestion to replace `slop?` with that tactic
- Copy suggestions to try them manually

## Caveats

- **Cost**: Each `slop?` call makes an API request. Be mindful of usage.
- **Determinism**: LLM outputs are non-deterministic. The same proof state may yield different suggestions across runs.
- **Verification**: All suggestions are type-checked by Lean before being shown, but you should still review them for correctness and style.

## Contributing

Pull requests are welcome! Make sure your changes build!

```bash
lake build
```

## License

MIT
