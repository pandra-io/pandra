# Agent Definition File Specification

This document defines the normative agent definition file format for Pandra API version `pandra.io/v1`.

An agent definition file is an `Agent` YAML document in an agent project. Its conventional filename is `agent.yaml`.

Field names are case-sensitive. Unknown fields are invalid.

## Document shape

```yaml
apiVersion: pandra.io/v1
kind: Agent
metadata:
  name: string
  version: string
spec:
  prompt: []
  systemPrompt: []
  skills: []
  mcps: []
  envs: []
```

`apiVersion`, `kind`, and `metadata.name` are required.

`apiVersion` must be `pandra.io/v1`.

`kind` must be `Agent`.

`metadata.name` must be a non-empty string.

`metadata.version` is optional. If omitted or empty, it defaults to `latest`.

Example:

```yaml
apiVersion: pandra.io/v1
kind: Agent
metadata:
  name: hello-world
spec:
  prompt:
    - text: |
        say hi!
```

The machine-readable [JSON Schema](agent.schema.json) applies to this document.

## Agent specification

### Prompt

`spec.systemPrompt` declares standing instructions that define the agent's purpose and character. If absent, the harness default applies. 

`spec.prompt` declares the initial task for the agent. 

`spec.prompt` and `spec.systemPrompt` are optional ordered lists of [source objects](#sources). Each source must resolve to a file.

The build process joins the contents of all resolved prompts. Prompts are trimmed for trailing whitespace. Prompts are joined with two newline characters in list order. The result is materialized as one package asset.

Empty text is valid content.

A [one-shot run](/CONTRIBUTING.md#run) must obtain a prompt from `spec.prompt` or a run override. TUI and ACP runs ignore it.

```yaml
spec:
  prompt:
    - text: |
        summarize the files in the workspace
  systemPrompt:
    - http:
        url: https://corp/shared/base-system-prompt.md
    - fs:
        path: prompts/system.md
```

### Skills

`spec.skills` is an optional list of [source objects](#sources). Each source must resolve to one skill directory.

A skill directory must contain `SKILL.md`, and its skill name is the `name` field in that file's YAML front matter.

Skill names must be unique within `spec.skills`. Each name must be a single path segment: it cannot contain `/` or `\` and cannot be exactly `.` or `..`.

```yaml
spec:
  skills:
    - fs:
        path: shared/world-greetings
```

### MCP servers

`spec.mcps` is an optional list of MCP server registrations. Each registration requires a non-empty, unique `name` and exactly one transport: `stdio` or `http`.

```yaml
spec:
  mcps:
    - name: time
      stdio:
        command: ["uv", "tool", "run", "mcp-server-time"]
```

```yaml
spec:
  mcps:
    - name: search
      http:
        url: https://example.com/mcp
        headers:
          - name: Authorization
            env: SEARCH_MCP_AUTH
```

For `stdio`, `command` is required and must be a non-empty string array. `envs` is optional:

```yaml
stdio:
  command: ["tool"]
  envs:
    - name: EXAMPLE
      value: value
    - name: GITHUB_PERSONAL_ACCESS_TOKEN
```

MCP `envs` entries follow the same rules as [`spec.envs`](#environment). A literal value is stored in the package. When `value` is absent, the entry's `name` is required at run time.

For `http`, `url` is required. `headers` is optional. Each header entry requires `name` and exactly one of `value` or `env`. A literal `value` is stored in the package and must not contain the internal token prefix `__PANDRA_REF_`. `env` names an environment variable that is required at run time and may be supplied in any supported method. An empty value is valid.

A header `name` must be non-empty. `env` follows the environment-variable name rules in [`spec.envs`](#environment).

MCP commands run in the same environment as the harness. Pandra registers MCP servers but does not install them.

Claude Code performs its own `${VAR}` expansion on some `mcp.json` fields after Pandra renders them, so a literal or resolved run-time value containing `${...}` may be expanded again by Claude Code.

### Environment

`spec.envs` is an optional list of environment variables for the agent.

```yaml
spec:
  envs:
    - name: LOG_LEVEL
      value: info
    - name: GITHUB_TOKEN
```

Each entry requires `name`. `value` is optional.

When `value` is present, it is a literal default stored in the package. The default is applied only when the variable is not already set.

When `value` is absent, the variable is unknown at build time and is required at run time. The agent definition file does not specify how the run supplies it.

`name` must match `[A-Za-z_][A-Za-z0-9_]*`.

A literal `value` must not contain the internal token prefix `__PANDRA_REF_`.

## Sources

A source object declares how an agent asset is supplied. An external source object declares the asset's origin and resolution strategy. Exactly one source type must be set.

Assets resolution determines the final source map and accurate versioned references. Assets materialization then fetches external sources and organizes the resulting agent assets in the package dir. Inline content is written directly.

### Text source

`text` embeds literal content.

```yaml
text: |
  say hi
```

### Filesystem source

`fs` reads from the build machine's filesystem. Exactly one path field must be set.

```yaml
fs:
  path: assets/content.md
```

```yaml
fs:
  absolutePath: /opt/pandra/content.md
```

`path` is relative to the directory containing the agent definition file. `absolutePath` is an absolute path on the build machine.

### Git source

`git` reads from a Git repository.

```yaml
git:
  url: https://github.com/example/repo.git/path/in/repo
  ref: main
```

`url` is required and must start with a repository location using an HTTP or SSH scheme. Append `//path/in/repo` to select a file or directory inside the repository; the separator is the last `//` in the URL.

GitHub URLs also accept `github.com/OWNER/REPO/path/in/repo`. A GitHub browser URL ending in `/tree/BRANCH/path/in/repo` selects the path from `BRANCH`. `BRANCH` is one URL path segment. An explicit `ref` or `commit` overrides the branch in a browser URL.

Exactly one of `ref` or `commit` may be set. If neither is set, Pandra uses the remote default branch at build time.

A `ref` or remote default branch resolves to the exact commit fetched for that build.

Sources without `commit` use shallow clones. A `commit` source first tries a shallow clone and shallow fetch of the requested commit, then falls back to a full clone if the remote does not support fetching by commit.

`git` CLI is not required. HTTPS Git credential helpers are not consulted. SSH authentication uses the SSH agent and standard SSH config and known-hosts files.

### HTTP source

`http` reads from a URL.

```yaml
http:
  url: https://example.com/content.md
```

```yaml
http:
  url: https://example.com/skill.tar.gz
  archive: true
```

`url` is required. `archive` is optional and defaults to `false`.

When `archive` is `false`, the response body is used as one file. When it is `true`, the response body is extracted.

Supported archive formats are `zip`, `tar`, `tar.gz`, and `tgz`. The format is detected from the URL suffix first, then by common magic bytes such as zip and gzip when the URL has no useful extension.

Archive extraction writes only directories and regular files. Symlinks and other special entries are skipped. Materialized directories and executable files use mode `0700`. Other materialized files use mode `0600`.

HTTP redirects are followed. A fetch must complete within 60 seconds, its response must be at most 100 MiB, and its HTTP status must be in the 2xx range. An archive may contain at most 100,000 entries and 512 MiB of regular-file content.

## Discovery

Discovery populates agent assets from conventional project paths during build. It runs after the agent definition file is read and before validation, assets resolution, and assets materialization.

Prompt assets are discovered only when their list in `spec` is absent or empty. An explicit non-empty prompt-source list wins, and discovery never appends to it. List assets such as skills append discovered entries after explicit entries. Each discovered asset becomes an `fs` source with a `path` locator.

`prompt.md` is discovered as `spec.prompt`:

```yaml
spec:
  prompt:
    - fs:
        path: prompt.md
```

`system-prompt.md` is discovered as `spec.systemPrompt` under the same rule.

To compose a conventional prompt file with other sources, declare it explicitly as `fs.path: prompt.md`. It may appear at any position in the ordered list.

Each `skills/<name>` directory is discovered as a `spec.skills` entry. Discovered skills are sorted by path, and discovery does not recurse below `skills/*`.

Discovery skips a conventional skill that is already declared by `fs.path` or by an `fs.absolutePath` inside the agent project.
