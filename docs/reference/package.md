# Agent Package Specification

This document defines the normative package format for Pandra package version `pandra.io/package/v1`.

A package dir is a generated, portable directory containing a package manifest and materialized agent assets. Its conventional name is `pandra_package`. It is typically built from an agent project but does not depend on the project after it is built.

A package is a `.tar.gz` archive of the package dir. It is the deterministic primary build artifact and stable form for distribution.

Neither representation selects or provisions a harness, provider, model, operating-system packages, or environment values supplied at run time.

The package manifest is valid UTF-8 JSON. It contains exactly one top-level value. Object member names are unique.

Manifest field names are exact and case-sensitive. Readers ignore unknown fields.

An optional field may be added to `pandra.io/package/v1` when existing readers can safely ignore it. A change requires a new package version when existing readers cannot safely interpret the package without understanding it.

## Manifest shape

The package manifest is the required `manifest.json` document at the package-dir root. It is the complete generated agent definition and an index of the content needed at run time.

```json
{
  "packageVersion": "pandra.io/package/v1",
  "agent": {
    "name": "reviewer",
    "version": "1.0"
  },
  "assets": {
    "prompt": "prompt.md",
    "systemPrompt": "system-prompt.md",
    "skills": ["skills/reviewer"]
  },
  "mcps": [
    {
      "name": "time",
      "stdio": {
        "command": ["uv", "tool", "run", "mcp-server-time"]
      }
    }
  ],
  "environment": {
    "defaults": {
      "LOG_LEVEL": "info"
    },
    "required": ["GITHUB_TOKEN"]
  }
}
```

`packageVersion` is required and must be `pandra.io/package/v1`.

Package generators serialize `manifest.json` deterministically with two-space indentation. Required empty maps and arrays are represented as `{}` and `[]`.

`agent.name` and `agent.version` identify the agent. Defaults have already been applied.

`assets` identifies materialized package content:

- `prompt` is the optional one-shot prompt file.
- `systemPrompt` is the optional system-prompt file.
- `skills` is the optional list of skill directories.

Prompt paths and skill paths are canonical package-relative paths. Every skill path is exactly `skills/<skill-name>`, and skill names are unique.

All assets have already been materialized from their original sources. The manifest contains no source tracking or provenance.

`mcps` preserves the agent definition file's normalized MCP declarations using the JSON form of [`pandra.MCP`](agent.md#mcp-servers). It is an empty array when no servers are declared.

`environment.defaults` maps environment-variable names to public literal defaults. `environment.required` is the sorted list of variables declared without a value in the agent definition file. Both fields are required and may be empty. A name cannot appear in both fields.

Every environment-variable name must match `[A-Za-z_][A-Za-z0-9_]*`.

## Package-dir shape

The package-dir root may contain:

```text
manifest.json
prompt.md
system-prompt.md
skills/<skill-name>/...
```

The package manifest is required. Optional assets are omitted when they are not declared.

Package dirs are harness-agnostic and must not contain a run profile or target-specific harness configuration.

## Reproducibility

Identical package dirs produce byte-identical packages and identical SHA-256 digests.

- Package entries are sorted.
- Timestamps are the Unix epoch.
- Archive directory entries use mode `0755`.
- Archive regular-file entries use mode `0644`.
- Archive executable-file entries use mode `0755`.
- Gzip timestamp is zero.

The package digest is the SHA-256 digest of the complete `.tar.gz`, written as `sha256:<64 lowercase hexadecimal characters>`.

Package dirs created or extracted locally use owner-only permissions. Directories and executable files use mode `0700`. Other regular files use mode `0600`. Local filesystem permissions do not affect package contents or the package digest.

## Safety

Every path stored in a package must be canonical, non-empty, package-relative, use `/` separators.

Canonical paths contain no `.` or `..` segments, repeated separators, backslashes, or filesystem volume prefixes.

Readers reject duplicate paths, symlinks, hard links, devices, sockets, and every entry type other than a regular file or directory. Readers also limit package bytes, entry count, and total extracted bytes.

A package dir or package is not a security boundary. Running a package assumes its contents and origin are trusted.

Packages may contain sensitive information in plain text. Do not commit credentials into packages.
