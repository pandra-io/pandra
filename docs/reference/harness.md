# Harness Adapter Reference

A harness adapter maps a portable package into harness configuration for an execution target.

The examples below use symbolic values enclosed in angle brackets that are descriptive and are not literal paths or argument values.

## Validation

The resolved target's harness and provider must form a supported combination:

| Provider | Claude Code | Codex | Pi |
| --- | --- | --- | --- |
| `anthropic` | Supported | Unsupported | Supported |
| `openai` | Unsupported | Supported | Supported |
| `openrouter` | Unsupported | Unsupported | Supported |

Target resolution and harness preparation reject unsupported combinations.

The following combinations are also unsupported:

- `harness: pi` with a non-empty `mcps` list;
- `harness: claudecode` and `bare: true` with a non-empty `assets.skills`; and
- `harness: claudecode` and `bare: true` with `CLAUDE_CODE_OAUTH_TOKEN` supplied by the run profile, run environment, or package environment declaration.

## Harness mappings

### Harness configuration

The harness configuration directory is designed to replace the entire harness configuration at runtime. The harness is configured to use it exclusively. It is ephemeral and may contain sensitive information.

| Harness | Config environment |
| --- | --- |
| Claude Code | `HOME=<config>/claudecode/home` |
| Codex | `HOME=<config>/codex/home`; `CODEX_HOME=<config>/codex/home/.codex` |
| Pi | `PI_CODING_AGENT_DIR=<config>/pi/home` |

### Skills

| Harness | Mapping |
| --- | --- |
| Claude Code | Copy each skill unchanged to `<config>/claudecode/home/.claude/skills/<skill-name>/`. |
| Codex | Copy each skill unchanged to `<config>/codex/home/.agents/skills/<skill-name>/`. |
| Pi | Add `--skill <package>/skills/<skill-name>` for each skill without copying it into the harness configuration. |

### Provider and credentials

| Harness | Mapping |
| --- | --- |
| Claude Code | Pass `<model>` with `--model`. Anthropic credentials remain in `ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`. `ANTHROPIC_API_KEY` takes precedence when both are set. Subscription authentication is incompatible with bare mode. |
| Codex | Pass `<model>` with `--model`. If `CODEX_ACCESS_TOKEN` is set, remove `CODEX_API_KEY` from the harness environment. Otherwise, when `CODEX_API_KEY` is unset and `OPENAI_API_KEY` is set, copy its value to `CODEX_API_KEY`. |
| Pi | Pass `<provider>` with `--provider` and `<model>` with `--model`. Provider credentials remain in `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, or `OPENROUTER_API_KEY`. |

Before a Codex TUI or local ACP harness starts, Pandra prepares login state under the per-run `CODEX_HOME` when credentials are available. It runs `codex login --with-access-token` with `CODEX_ACCESS_TOKEN`, or `codex login --with-api-key` with the effective `CODEX_API_KEY`. Codex one-shot authentication remains environment-based.

Credential values must not be persisted outside the harness configuration.

### Permissions

| Harness | Mapping |
| --- | --- |
| Claude Code | Use harness-native permission defaults in TUI mode. Add `--dangerously-skip-permissions` in one-shot and ACP modes. |
| Codex | Use harness-native approval and sandbox defaults in TUI mode. Add `--dangerously-bypass-approvals-and-sandbox` in one-shot and ACP modes. |
| Pi | No permission flag. |

### System prompt

| Harness | Mapping |
| --- | --- |
| Claude Code | Add `--system-prompt-file <package>/<system-prompt-asset>`. |
| Codex | Set `model_instructions_file` in rendered `config.toml` to `<package>/<system-prompt-asset>`. |
| Pi | Add `--system-prompt <system-prompt>`. |

The mapping is omitted when `assets.systemPrompt` is absent.

Append-system-prompt behavior is not part of the agent definition file schema.

### MCP servers

When MCP servers are declared, Claude Code writes `<config>/claudecode/mcp.json` and receives:

```text
--mcp-config <config>/claudecode/mcp.json --strict-mcp-config
```

Codex writes MCP configuration into its private `config.toml`.

Pi does not support MCP declarations and has no harness configuration file.

## Configuration formats

### Claude Code

Claude Code uses a configuration file only for MCP servers. Other settings are supplied through flags, files, and environment variables.

The Claude Code MCP configuration has this JSON shape:

```json
{
  "mcpServers": {
    "time": {
      "type": "stdio",
      "command": "uv",
      "args": ["tool", "run", "mcp-server-time"],
      "env": {
        "TOKEN": "<environment-value>"
      }
    },
    "search": {
      "type": "http",
      "url": "https://example.com/mcp",
      "headers": {
        "Authorization": "<environment-value>"
      }
    }
  }
}
```

For a `stdio.command` array, the first item becomes `command` and the remaining items become `args`.

### Codex

Codex always writes `<config>/codex/home/.codex/config.toml`:

```toml
project_doc_max_bytes = 0
model_instructions_file = "<package>/system-prompt.md"

[projects."<workspace>"]
trust_level = "trusted"

[mcp_servers.time]
command = "uv"
args = ["tool", "run", "mcp-server-time"]

[mcp_servers.time.env]
TOKEN = "<environment-value>"

[mcp_servers.search]
url = "https://example.com/mcp"
http_headers = { Authorization = "<environment-value>" }
```

`model_instructions_file` is omitted when `assets.systemPrompt` is absent.

MCP tables are omitted when the manifest does not declare MCP servers.

For a `stdio.command` array, the first item becomes `command` and the remaining items become `args`.

The generated `config.toml` sets `project_doc_max_bytes = 0` so workspace `AGENTS.md` files do not change the packaged agent behavior.

It marks `<workspace>` as trusted so Codex does not request trust confirmation.

## Harness commands

The run mode selects the one-shot, TUI, or ACP command mapping.

The target model is used unless the run overrides it.

One-shot mode uses the package prompt unless the run overrides it and requires an effective prompt. TUI and ACP modes start without an initial user message.

Each command below represents an executable and argument array, not a shell command string.

Symbolic values in angle brackets are replaced with real values. There is no shell expansion.

Optional arguments in square brackets are included only when the corresponding feature is relevant.

The tables describe the environment entries and arguments that Pandra adds. They do not repeat inherited provider credentials.

### Claude Code

| Option | Modes | Purpose |
| --- | --- | --- |
| `HOME=<config>/claudecode/home` | All | Isolate Claude Code configuration and skill discovery from the user's home directory. |
| `IS_DEMO=1` | All | Skip onboarding and hide account identity in the header and status output. |
| `--print` | One-shot | Run non-interactively and exit after producing a response. |
| `--output-format stream-json` | ACP | Emit streamed JSON events for the ACP bridge. |
| `--verbose` | ACP | Include full turn-by-turn output in the event stream. |
| `--model <model>` | All | Select the resolved or overridden model. |
| `--dangerously-skip-permissions` | One-shot, ACP | Disable Claude Code permission prompts. |
| `[--bare]` | All | When enabled, disable discovery of hooks, skills, plugins, MCP servers, memory, and `CLAUDE.md`. |
| `[--system-prompt-file <package>/<system-prompt-asset>]` | All | Replace the default system prompt with the packaged system prompt. |
| `[--mcp-config <config>/claudecode/mcp.json]` | All | Load the generated MCP server configuration when MCP servers are declared. |
| `[--strict-mcp-config]` | All | Ignore every MCP configuration source except the generated file. |
| `<prompt>` | One-shot | Supply the effective prompt. |
| `--input-format stream-json` | ACP | Accept streamed JSON input from the ACP bridge. |
| `--include-partial-messages` | ACP | Include partial streaming events in output. |

### Codex

| Option | Modes | Purpose |
| --- | --- | --- |
| `HOME=<config>/codex/home` | All | Isolate general Codex state from the user's home directory. |
| `CODEX_HOME=<config>/codex/home/.codex` | All | Select the private Codex configuration and state directory. |
| `exec` | One-shot | Run Codex non-interactively and exit after the task. |
| `--skip-git-repo-check` | One-shot | Allow the run workspace to be outside a Git repository. |
| `--dangerously-bypass-approvals-and-sandbox` | One-shot, ACP | Disable Codex approval prompts and sandbox restrictions. |
| `--model <model>` | All | Select the resolved or overridden model. |
| `<prompt>` | One-shot | Supply the effective prompt. |
| `app-server` | ACP | Start the JSON-RPC server used by the ACP bridge. |

### Pi

| Option | Modes | Purpose |
| --- | --- | --- |
| `PI_CODING_AGENT_DIR=<config>/pi/home` | All | Select the private Pi configuration and state directory. |
| `-p` | One-shot | Print the response and exit. |
| `--mode rpc` | ACP | Use Pi's RPC protocol over standard input and output. |
| `--provider <provider>` | All | Select the resolved model provider. |
| `--model <model>` | All | Select the resolved or overridden model. |
| `--no-context-files` | All | Disable discovery of workspace `AGENTS.md` and `CLAUDE.md` files. |
| `[--system-prompt <system-prompt>]` | All | Replace the default system prompt with the packaged system prompt. |
| `[--skill <package>/skills/<skill-name>]` | All | Load one packaged skill; repeat once for each skill. |
| `<prompt>` | One-shot | Supply the effective prompt. |

## Upstream references

These upstream harnesses change frequently. When their documented flags or configuration formats change, update this file and the corresponding harness mapping tests.

- Claude Code CLI: <https://code.claude.com/docs/en/cli-reference>
- Claude Code settings: <https://code.claude.com/docs/en/settings>
- Claude Code skills: <https://code.claude.com/docs/en/skills>
- Claude Code MCP: <https://code.claude.com/docs/en/mcp>
- Codex authentication: <https://developers.openai.com/codex/auth>
- Codex access tokens: <https://developers.openai.com/codex/enterprise/access-tokens>
- Codex non-interactive mode: <https://developers.openai.com/codex/noninteractive>
- Codex configuration: <https://developers.openai.com/codex/config-advanced>
- Codex skills: <https://developers.openai.com/codex/skills>
- Codex MCP: <https://developers.openai.com/codex/mcp>
- Codex app-server: <https://developers.openai.com/codex/app-server>
- Pi usage: <https://pi.dev/docs/latest/usage>
- Pi providers: <https://pi.dev/docs/latest/providers>
- Pi RPC: <https://pi.dev/docs/latest/rpc>
