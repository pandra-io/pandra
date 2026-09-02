# Agent Run Profile Specification

This document defines the normative run-profile format for Pandra API version `pandra.io/v1`.

A run profile is an `AgentRunProfile` YAML document containing user preferences for running an agent, including harness, LLM, and environment settings.

Field names are case-sensitive. Unknown fields are invalid.

## Document shape

```yaml
apiVersion: pandra.io/v1
kind: AgentRunProfile
metadata:
  name: example
spec:
  harness:
    claudecode: {}
  llm:
    anthropic:
      model: claude-haiku-4-5
  envs:
    - name: ANTHROPIC_API_KEY
      value: "ant-..."
```

`apiVersion`, `kind`, and `metadata.name` are required.

`apiVersion` must be `pandra.io/v1`.

`kind` must be `AgentRunProfile`.

`metadata.name` must contain at least one non-whitespace character, must contain at most 128 characters, and must not contain control characters.

The machine-readable [JSON Schema](agent.schema.json) applies to this document.

A profile file used directly may omit the harness, provider, or model when explicit flags supply the missing fields. A registered profile must define a complete execution target with a supported [harness/provider combination](harness.md#validation).

## Harness

`spec.harness` is an object value that selects one harness used to run the agent. The key selects the harness, the value is an object with optional harness-specific configuration.

For example:

```yaml
  harness:
    claudecode: {}
```

Supported harnesses:
- `claudecode`
- `codex`
- `pi`

Supported harness-specific configuration:

Claude Code:
- `bare` is a boolean field that controls whether the Claude Code harness runs in [bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode).

## LLM

`spec.llm` is an object value that selects one LLM provider and model that the selected harness should use. The key selects the provider, the value is an object with optional provider-specific configuration.

For example:

```yaml
  llm:
    anthropic: {}
```

Not all harnesses support all providers. 

Supported providers:

| Harness | Provider profile key |
| --- | --- |
| Claude Code | `anthropic` |
| Codex | `openai` |
| Pi | `anthropic`, `openai`, or `openrouter` |

The [harness adapter reference](harness.md#validation) defines the complete compatibility rules.

Model is selected with the optional `model` field in the provider-specific configuration.

For example:

```yaml
  llm:
    anthropic:
      model: "claude-haiku-4-5"
```

Models are referred to by their "api name", not a display name. 

Model names are not validated by Pandra. Use each provider's documentation to find the available models.

## Environment Variables

`spec.envs` is an optional list of run-time environment values. It is used to supply credentials for the LLM provider, but may also be used to supply other configuration values to the agent.

Each `spec.envs` entry requires `name` and exactly one of `value`, `hostEnv`, or `keychain`.

`name` may satisfy a required agent environment variable, MCP environment variable, or environment variable referenced by an MCP HTTP header.

`value` supplies a literal run-time value.

`hostEnv` is the name of a variable in the host environment. Its value is copied to `name` before the agent starts. The host variable must be set, although its value may be empty.

`keychain` loads a generic-password item from macOS Keychain when the run starts. It requires `service` and `account`.

`keychain.service` must be `pandra`. This restriction prevents a run profile from directing Pandra to read Keychain items owned by another service.

`keychain.account` must contain at least one non-whitespace character, must contain at most 255 characters, and must not contain control characters. Pandra reads the item with service `pandra` and this account from the default Keychain search list.

Keychain entries are valid on every platform so profiles can be loaded and registered without resolving their values. A run that must resolve one outside macOS fails. An explicit run environment value with the same `name` overrides the profile entry and skips Keychain access.

Variable names must match `[A-Za-z_][A-Za-z0-9_]*`.

A literal `value` must not contain the internal token prefix `__PANDRA_REF_`.

Profile environment values override defaults from the agent definition file. They are used only at run time and may appear in private harness configuration.
