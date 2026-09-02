# Pandra Manual

This document covers the complete product usage and features. Other documents complement it by covering specific topics in depth:

- For installation instructions, see the [installation guide](install.md).
- For an overview of the CLI usage by example, see the [CLI cheat sheet](cheat-sheets/cli.sh).
- For an overview of the agent definition YAML by example, see the [agent definition cheat sheet](cheat-sheets/agent.yaml).
- For detailed product specifications, see the documents under [reference](reference).
- For developer guidance (agents or humans), see the [Contribution Guide](/CONTRIBUTING.md).

## Orientation

1. A developer creates an agent project, which is a directory with an agent definition file, typically `agent.yaml`.
2. The developer authors this agent definition YAML file to define the behavior and features of the agent.
3. Agent assets (markdown) may be embedded in the agent definition file, provided as files in the agent project, or sourced from external locations.
4. A build resolves assets (determine the precise origin of each asset), and materializes them (fetch and prepare assets) into the package dir.
5. The package dir is an intermediary runnable artifact. A package (or package archive) is the primary build artifact and stable form for distribution.
6. The user (or the system) selects an execution target consisting of a harness, LLM provider, and model, usually through a run profile that may contain additional preferences.
7. At run time, the portable package is adapted to the selected target, an isolated ephemeral harness configuration environment is created, and the harness is started in the selected workspace.
8. Users can install remote or local packages in the local agent inventory for convenient repeated runs.

## Command map

- `pandra build`: build a package
- `pandra run`: run an agent
- `pandra agents`: manage the agent inventory
    - `pandra install`: alias for `pandra agents set`
    - `pandra ls`: alias for `pandra agents list`
    - `pandra rm`: alias for `pandra agents remove`
- `pandra ps`: list running agents
- `pandra profiles`: manage run profiles
- `pandra version`: print the CLI version

The [CLI cheat sheet](cheat-sheets/cli.sh) shows every command and flag by example.

## Agent project

An agent project is a directory with an agent definition file, typically `agent.yaml`. The file defines the composition of an agent.

The [agent definition file specification](reference/agent.md) defines the complete document shape, source rules, discovery behavior, and validation. The [agent definition cheat sheet](cheat-sheets/agent.yaml) shows every field by example.

Example:

```yaml
apiVersion: pandra.io/v1
kind: Agent
metadata:
  name: hello-world
  version: v0.0.1
spec:
  prompt:
    - text: | # inline asset
        say hi!
  systemPrompt:
    - git: # git-sourced asset
        url: https://github.com/pandra-io/pandra/docs/examples/test-sys-prompt.md
  # Skills may be discovered from skills/*.
  mcps: # MCP servers are configured but not installed.
    - name: time-mcp
      stdio:
        command: ["uv", "tool", "run", "mcp-server-time"]
```

## Agent package

Building an agent project produces a portable package dir and a deterministic `.tar.gz` package. The package dir is a runnable intermediary artifact. The package is the stable form for distribution.

The [package specification](reference/package.md) defines the package manifest, deterministic package format, parsing rules, and validation.

### Build a package dir

`pandra build --dir` accepts an agent definition file through `--file`, or auto-detects an agent project through `--path` or the first positional argument:

```bash
pandra build --dir
pandra build --dir --file reviewer.yaml
pandra build --dir --path ./reviewer --output ./dist/reviewer
```

`--dir` accepts only an agent project because its output is a package dir. Input selection follows the shared [artifact input resolution](#artifact-input-resolution) rules.

Without `--output`, the package dir is written to `<project-root>/pandra_package`.

The package-dir stage validates a complete replacement before publishing it. The destination may be absent or an existing valid package dir; a regular file or invalid existing directory is rejected. A refresh removes stale generated content.

A successful directory build prints `Built <path>` and stops before creating `agent.tar.gz`.

### Build a package

`pandra build` (without `--dir`) accepts a package dir through `--package`, an agent project through `--file`, or an auto-detected path:

```bash
pandra build
pandra build --package ./pandra_package
pandra build --file reviewer.yaml --output reviewer.tar.gz
```

No input means `--path .`. Without `--output`, the package is written to `./agent.tar.gz`.

The package destination may be absent or an existing regular file; a directory is rejected. Pandra writes and validates a temporary package in the destination directory before replacing the destination.

An auto-detected existing package dir takes precedence over an agent project. A project input builds or refreshes `<project-root>/pandra_package`, then builds the package from that published directory. Explicit `--file` forces that project flow even when the conventional package dir already exists. A full project build leaves both `pandra_package/` and `agent.tar.gz`.

With `--dir`, `--output` names a directory; without `--dir`, it names a regular file. The suffix does not select the mode.

A successful package build prints `Built <path>`.

## Artifact input resolution

Artifact input may be explicit or implicit. A dedicated selector explicitly chooses an artifact family. `--path` and the first positional argument accept ambiguous input and detect its form automatically.

Not every command accepts every artifact form:

| Command | Accepted forms in order|
| --- | --- |
| `pandra build --dir` | agent project |
| `pandra build` | package dir, agent project |
| `pandra run` | package, package dir, agent project |
| `pandra agents set`, `pandra install` | package, package dir, agent project |

### Explicit input

Dedicated selectors bypass automatic detection:

- `--file PATH` requires an agent definition file. A file may have any name and makes its parent the project root; a directory resolves `<directory>/agent.yaml`.
- `--package PATH` selects the package family: a `.tar.gz` or gzip file is a package, while a directory is a package dir.

Dedicated selectors are mutually exclusive with one another, `--path`, and the first positional argument.

There is no `--archive` selector.

### Implicit input

`--path PATH` and the first positional argument detect the artifact form. Relative paths resolve from the process working directory.

With no input selector, commands behave as if `--path .` were supplied.

If the path is a file, it is handled as a package when it has a `.tar.gz` suffix or gzip signature; otherwise it is handled as an agent definition file.

If the path is a directory, the command probes its accepted forms in this order:

1. Package: `<directory>/agent.tar.gz`.
2. Package dir: the directory itself when it contains `manifest.json`, then `<directory>/pandra_package`.
3. Agent project: `<directory>/agent.yaml`.

For example, when a directory contains `agent.tar.gz`, `pandra_package`, and `agent.yaml`, a command that accepts all three forms selects the package.

An existing candidate claims its form even when malformed. Validation failure does not fall through to a lower-priority candidate. For example, `pandra run .` fails on a malformed `./agent.tar.gz` instead of using a valid package dir, and `pandra build .` fails on an invalid `./pandra_package` instead of rebuilding from the agent project.

## Run profiles

A run profile is an `AgentRunProfile` YAML document containing user preferences for running an agent, including harness, LLM, and environment settings. Resolving a profile produces the execution target: the `{harness, provider, model}` tuple.

A run profile may be loaded from a YAML file or the local profile registry. Command-line flags may supply missing fields or override selected fields.

Run profiles may be registered for convenient access and to set one global default.

The [run-profile specification](reference/run-profile.md) defines the complete document shape and options.

### Selecting a profile

A run selects one whole profile in this order:

1. The profile passed with `--profile REF`.
2. The profile snapshotted with a registered agent.
3. The global default profile.

`--profile REF` resolves an existing filesystem path first and otherwise a registered profile name.

Profiles are not merged. They are not discovered beside agent definition files or loaded from remote Git repositories.

### Create profiles

`pandra profiles new` interactively creates and registers a complete run profile:

```bash
pandra profiles new
```

The command asks for a profile name that follows the [run-profile `metadata.name` rules](reference/run-profile.md#document-shape), and a harness. An empty profile name becomes `default`. Claude Code and Codex then ask for an authentication type. Pi asks for a provider instead. Every path asks for a model and credential.

On macOS, the credential is stored as a generic-password item in the default Keychain. Its service is `pandra` and its account is `<profile-name>-<environment-name>`. Its label is `Pandra: <account>`, its kind is `Pandra run profile credential`, and its comment is `Created by pandra profiles new`. The generated profile stores only the Keychain reference. Pandra uses the native `security` prompt so the credential is not placed in process arguments.

On other platforms, the credential is read without terminal echo and stored as a literal profile environment value.

The model prompt lists popular models for the selected provider. Enter a listed model number or type any model API name.

| Provider | Popular models |
| --- | --- |
| Anthropic | `claude-haiku-4.5`, `claude-sonnet-5`, `claude-opus-5` |
| OpenAI | `gpt-5.6-luna`, `gpt-5.6-terra`, `gpt-5.6-sol` |
| OpenRouter | `openrouter/free`, `openrouter/auto`, `openrouter/auto-beta`, `openrouter/pareto-code`, `openrouter/fusion` |

The command requires an interactive terminal. Invalid choices and empty required values are prompted again.

`--file FILE` also writes the profile as an `AgentRunProfile` YAML document with file mode `0600`. Its parent directory is validated before prompting and must already exist. The destination must be a regular file, must not be a symlink, and must not be the profile registry. Registration is saved first. If writing the file fails, the error states that the profile remains registered.

`--default` also makes the registered profile the global default. It may be combined with `--file`:

```bash
pandra profiles new --file profile.yaml --default
```

Replacing a registered profile, changing an existing global default, or replacing an existing file requires confirmation. Pressing Enter or answering `y` replaces it. Answering `n` cancels the command without changes.

On macOS, the generated credential is absent from the private profile registry and the generated file. Replacing or removing a profile does not delete its Keychain items. Changing authentication type may leave the previous item unused.

On other platforms, the generated credential remains plaintext in the private profile registry and in the generated file when `--file` is used.

A successful command prints `Set profile <name>`. With `--file`, it also prints `Wrote profile <path>`.

### Register profiles

`pandra profiles set` adds or replaces a profile. `--default` also makes it the one global default:

```bash
pandra profiles set --file profile.yaml --default
```

The registered name is `--name` when provided; otherwise it is the profile's required `metadata.name`. The registered name follows the [run-profile `metadata.name` rules](reference/run-profile.md#document-shape). Setting another default replaces the previous default. A successful set prints `Set profile <name>`.

Registered profiles are snapshots. Later changes to the source YAML do not change the registered profile.

List, get, and remove registered profiles with:

```bash
pandra profiles list # alias: pandra profiles ls
pandra profiles get --name work
pandra profiles remove --name work
```

The list has `NAME`, `DEFAULT`, `HARNESS`, `PROVIDER`, and `MODEL` columns.

Removing the default profile clears the global default.

### Profile overrides

After profile selection, `--harness`, `--provider`, and `--model` override individual target fields. `--claudecode.bare[=BOOL]` overrides the Claude Code bare setting.

Enabling bare mode requires the Claude Code harness. `--claudecode.bare=false` is accepted with another harness and has no effect.

Example:

```bash
pandra run reviewer --model claude-sonnet-4-5
pandra run reviewer --harness codex --provider openai --model gpt-5
```

## Run agents

### Input selection

`pandra run` accepts an agent project, package dir, package, registered agent, or Git URL:

```bash
pandra run
pandra run --file reviewer.yaml
pandra run --package ./pandra_package
pandra run --package ./agent.tar.gz
pandra run --path ./reviewer
pandra run reviewer
pandra run https://github.com/my/repo/agents/reviewer
```

Filesystem inputs follow [Artifact input resolution](#artifact-input-resolution). With no input, `pandra run` detects the artifact from `.`.

The first positional is detected in the following order (higher is earlier):

1. Git URL
2. Filesystem path
3. Registered-agent name

`--path` doesn't accept a registered agent name.

`pandra run`, `pandra agents set`, and `pandra install` accept Git URLs through `--path` or the positional form. `pandra build` does not accept Git URLs. `//subpath` selects a path below the repository root. A `github.com/OWNER/REPO/subpath` URL treats the path after the repository as the subpath. A GitHub browser URL ending in `/tree/BRANCH/subpath` selects the subpath from `BRANCH`. `BRANCH` is one URL path segment.

Pandra shallow-clones the selected branch into temporary storage, applies the same automatic artifact detection, and removes the clone after use. Git subpaths may not traverse or follow symlinks outside the clone. Other revision selection, remote profile discovery, and clone caching are not supported.

### Run flow

An agent run:

1. Resolves and materializes a package dir. An agent project is built in temporary storage, a package dir is used directly, and a package is safely extracted into temporary storage.
2. Uses the selected workspace or creates an empty temporary workspace.
3. Selects a run profile, applies field overrides, and resolves the target.
4. Assembles the environment and generates private harness configuration.
5. Finds the harness on `PATH` and starts it as the current user.
6. Forwards standard streams and signals, preserves the harness exit code, and removes temporary files.

Temporary source, package, and validation files are removed on a best-effort basis. Errors that prevent harness shutdown, run tracking cleanup, or removal of private per-run harness configuration are returned. Such an error changes an otherwise successful exit status to 1. When the harness already exits with a non-zero status, Pandra preserves that exit code.

The selected harness, MCP commands, and other tools must already be installed on the current machine. The run does not read or modify user-level harness configuration, skills, plugins, hooks, or MCP registrations. Only environment-based authentication is guaranteed.

### Run modes

Agent runs support three run modes:

| Mode | Selection | Task source | Lifecycle |
| --- | --- | --- | --- |
| One-shot | default | effective prompt | performs one task and exits |
| TUI | `--tui` | harness terminal | lasts for the terminal session |
| ACP | `--acp` | ACP client messages | controlled by the client |

`--tui` and `--acp` are mutually exclusive. Neither mode accepts `--prompt` or `--prompt-append`.

One-shot mode requires a prompt from the agent definition file, `--prompt`, or a non-empty `--prompt-append`. Piped input is forwarded with that prompt:

```bash
tail -200 app.log | pandra run log-triage
```

TUI mode opens the harness's native interactive terminal without an initial message. The agent definition file's prompt is ignored.

ACP mode exposes the agent to an [Agent Client Protocol](https://agentclientprotocol.com)-compatible client over standard input and output. Each client session starts a separate harness process.

The ACP client supplies the prompt and workspace, so `--prompt`, `--prompt-append`, and `--workspace` (or `--ws`) are rejected. Client-provided MCP servers are also rejected because MCP declarations belong to the packaged agent.

The ACP bridge accepts text and resource-link prompts and supports streamed messages, thoughts, tool calls, cancellation, and close. File resource links inside the session workspace are translated to the corresponding harness workspace path. Closing a session stops its harness, and closing the connection stops all remaining sessions.

### Workspace

Agents start in an empty, ephemeral workspace. Use `--workspace DIR` when the agent needs existing input or its output must persist:

```bash
pandra run reviewer --workspace ./project
```

`--ws` is the short form of `--workspace`. Relative paths are resolved from the current directory.

### Environment

Runtime values may come from the following places in order:

1. Explicit `pandra run` flags:
  1.1. `--env NAME=VALUE` sets a literal value for the run.
  1.2. `--env-host NAME=HOSTNAME` copies `HOSTNAME` from the host environment into `NAME`.
2. Selected [run profile environment](reference/run-profile.md#environment-variables).
3. Inherited parent environment.
4. Environment defaults defined in the [agent definition file](reference/agent.md#environment).

Every environment entry in the agent definition file or an MCP declaration without `value`, and every environment variable referenced by an MCP HTTP header, must exist after the run inputs are assembled. An empty value is valid.

### Authentication

LLM credentials are run-time secrets. Supply them through the run environment or a run profile.

| Provider | Environment variable |
| --- | --- |
| Anthropic | `ANTHROPIC_API_KEY` |
| OpenAI | `OPENAI_API_KEY` |
| OpenRouter | `OPENROUTER_API_KEY` |

For Claude Code, `CLAUDE_CODE_OAUTH_TOKEN` uses a Claude subscription instead of an API key. Generate one with `claude setup-token`.

For Codex, `CODEX_ACCESS_TOKEN` uses ChatGPT-managed subscription or workspace access.

The [harness credential mappings](reference/harness.md#provider-and-credentials) define the exact behavior for each harness.

### Input and output

`--prompt` replaces the packaged prompt in one-shot mode or supplies one when the package has none. 

`--prompt-append`, also available as `--input`, appends invocation-specific text to the prompt. It may be repeated using either name. Values are appended in command-line order. When both flags are present, `--prompt` supplies the base and the appended values follow it. Non-empty parts are joined with one blank line.

`--prompt-append` and `--input` do not consume standard input. Piped input remains available to the harness.

I/O streams depend on the run mode:

| Mode | Standard input | Standard output | Standard error |
| --- | --- | --- | --- |
| One-shot | piped input is forwarded to the harness | harness output | hidden unless `--debug`; printed automatically if the run fails |
| TUI | attached to the terminal | attached to the terminal | attached to the terminal |
| ACP | client protocol messages | protocol messages only | diagnostics |

`--log-level LEVEL` is a global option. It accepts `debug`, `info`, `warn`, or `error`. The default is `info`.

`--color MODE` is a global option. It accepts `auto`, `always`, or `never`. The default is `auto`. The forms `--color MODE` and `--color=MODE` are equivalent. The option may appear anywhere except where it is the value of another option.

Pandra writes diagnostic records to standard error. In `auto` mode, Pandra colors diagnostic output when standard error is an interactive terminal. Styling is disabled when standard error is redirected, `TERM` is `dumb`, or `NO_COLOR` has a non-empty value. `NO_COLOR` is consulted only in `auto` mode. `always` enables color regardless of those conditions. `never` disables color.

`--color` applies only to Pandra diagnostic output. Pandra does not forward it to the harness or alter the harness environment to implement it.

Pandra passes harness standard error through unchanged.

`--debug` is a global option that may appear anywhere in any command except where it is the value of another flag. It sets the Pandra log level to `debug` and streams one-shot harness standard error. An explicit `--log-level` overrides the log level selected by `--debug`. `--log-level=debug` does not stream harness standard error.

`--keep-harness-config` is accepted by `pandra run` only. It retains generated harness configuration and reports its absolute path at `INFO`. The directory has private permissions and may contain sensitive configuration; remove it when it is no longer needed.

One-shot and TUI runs preserve the harness exit code. An ACP run exits when the client closes the protocol connection, and session failures are reported through ACP. Errors detected before the harness starts exit with status 1.

### Running processes

`pandra ps` lists local runs started through `pandra`:

```text
PID    AGENT     MODE  STARTED
12345  reviewer  tui   2026-07-22T10:11:12Z
```

The table is ordered by start time. `AGENT` is the registered name or package path used to start the run. `STARTED` is an RFC 3339 UTC timestamp.

An ACP bridge is one run regardless of its session count.

Run records are stored under `$UserCacheDir/pandra/runs` and removed when the run exits. `pandra ps` also removes records left unlocked by a crash.

## Agents inventory

The agent inventory maps a local name to a snapshotted package.

Add or replace an entry with `pandra agents set` or its `pandra install` alias.

Artifact inputs follow the shared [artifact input resolution](#artifact-input-resolution) rules. Git URL behavior is described under [Run input selection](#input-selection).

```bash
pandra install /path/to/reviewer
pandra install https://github.com/my/repo/agents/reviewer
pandra run reviewer
```

The registered name is `--name` when provided; otherwise it comes from the artifact's agent metadata. Setting the same name replaces the existing entry.

A package registration may select an explicit [run profile](#run-profiles), apply the same [profile overrides](#profile-overrides), and snapshot the result:

```bash
pandra agents set --file reviewer.yaml --profile work
```

Later changes to the source or registered profile do not change the agent registration. Run `pandra agents set` or `pandra install` again to update it.

Pandra prepares and validates a package and its snapshotted profile before replacing an existing entry, then imports the package into internal storage under its SHA-256 digest. An incompatible profile leaves the existing entry unchanged, and identical packages share one internal copy.

A successful set prints `Set <name>`.

List, get, and remove registered agents with:

```bash
pandra agents list # aliases: pandra agents ls, pandra ls
pandra agents get --name reviewer
pandra agents remove --name reviewer # alias: pandra rm --name reviewer
```

List and get use `NAME`, `VERSION`, `HARNESS`, `PROVIDER`, `MODEL`, and `DIGEST` columns. `DIGEST` is the package SHA-256 digest shortened to 12 hexadecimal characters, and unavailable metadata appears as `-`.

Removing a package registration removes its internal copy only when no other entry refers to it.

Profiles and agents share `$UserConfigDir/pandra/registry.json`. Package entries store their internal path in the `"package"` field. Pandra protects the directory with mode `0700` and the registry file with mode `0600`.

Known registry field names are matched without regard to letter case, hyphens, or underscores and are rewritten to their canonical names when Pandra saves the registry.

Internal packages are stored at `$UserConfigDir/pandra/packages/<sha256>.tar.gz`. `$UserConfigDir` is the [OS user configuration directory](https://pkg.go.dev/os#UserConfigDir).

## Containerize an agent

A Pandra package runs directly on the host and expects the harness, MCP servers, and tools to be installed. Container images can be used to package the agent with its operating environment or to provide an isolation boundary.

While agent packages are harness-agnostic, containerized agents tend to be harness-specific (since the harness becomes part of the deployable artifact).

You can use any container management tool. Use one of the provided base images under [`images`](../images/):

- [`claudecode.Dockerfile`](../images/claudecode.Dockerfile): Claude Code harness
- [`codex.Dockerfile`](../images/codex.Dockerfile): Codex harness
- [`pi.Dockerfile`](../images/pi.Dockerfile): Pi harness
- [`pandra.Dockerfile`](../images/pandra.Dockerfile): Pandra CLI. Used as the base image for harness images and as a builder stage.

The following [example](examples/hello-world-image) demonstrates an agent that uses an MCP server to tell the time.

```yaml
apiVersion: pandra.io/v1
kind: Agent
metadata:
  name: hello-world-time
spec:
  prompt:
    - text: |
        say hi! if it's AM time, say good morning.
  mcps:
    - name: time-mcp
      stdio:
        command: ["uv", "tool", "run", "mcp-server-time"]
```

The following Dockerfile demonstrates packing the agent with the MCP dependency into a Claude Code image:

```Dockerfile
FROM ghcr.io/pandra-io/claudecode:latest

# Install MCP server dependencies
RUN apk add --no-cache uv
RUN uv tool install mcp-server-time

# Install the agent package
RUN pandra install https://github.com/pandra-io/pandra/docs/examples/hello-world-image

WORKDIR /agent/workspace
ENTRYPOINT ["pandra","run","hello-world-time","--workspace","/agent/workspace"]
```

Build and run the container:

```bash
docker build -t hello-world-time .
docker run --rm -v "profile.yaml:/run/profile.yaml:ro" hello-world-time --profile /run/profile.yaml
```

The run profile is mounted at run time instead of being included in the image.

To build the agent package from local source:

```Dockerfile
FROM ghcr.io/pandra-io/pandra:latest AS build

WORKDIR /agent/project
COPY agent.yaml .
RUN pandra build --file agent.yaml --output /agent/agent.tar.gz

FROM ghcr.io/pandra-io/claudecode:latest

RUN apk add --no-cache uv
RUN uv tool install mcp-server-time

COPY --from=build /agent/agent.tar.gz /agent/agent.tar.gz

WORKDIR /agent/workspace
ENTRYPOINT ["pandra","run","--package","/agent/agent.tar.gz","--workspace","/agent/workspace"]
```

## Security

A package dir or package is an artifact, not a sandbox. Its instructions and skill scripts may cause arbitrary actions.

A local package run launches the harness as the current user without isolation or approval gates. It inherits the parent environment and may access the user's files, credentials, processes, tools, and network.

Keep secrets out of agent definition files, package dirs, packages, and agent assets. Literal run-profile values remain plaintext in the profile file and registry. macOS Keychain-backed run-profile values store only the service and account reference there.
