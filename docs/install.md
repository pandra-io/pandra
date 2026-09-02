# Installation

## Prerequisites

- Supported harness installed.
- API Key or Subscription for LLM provider.

## Installation

Check out the [releases](https://github.com/pandra-io/pandra/releases) page for downloadable artifacts.

To quickly install on macOS with Apple Silicon:

```bash
curl -sSfL https://github.com/pandra-io/pandra/releases/latest/download/pandra_darwin_arm64.tar.gz | sudo tar xz -C /usr/local/bin pandra
```

Verify:

```bash
pandra --help
```

Before you can run agents, you need to create a [Run profile](manual.md#run-profiles):

```bash
pandra profiles new --default
```

## LLM Provider Credentials

Credentials are provided as regular environment variables. The expected name of the variable is determined by the harness, but most harnesses support the same common environment variable names for each provider.

| Provider | Environment variable | How to obtain it |
| --- | --- | --- |
| Anthropic | `ANTHROPIC_API_KEY` | [Claude Console](https://console.anthropic.com/settings/keys) |
| Claude Subscription | `CLAUDE_CODE_OAUTH_TOKEN` | [Generate a long-lived token](https://code.claude.com/docs/en/authentication#generate-a-long-lived-token) |
| OpenAI | `OPENAI_API_KEY` | [OpenAI Dashboard](https://platform.openai.com/api-keys) |
| Codex Subscription | `CODEX_ACCESS_TOKEN` | [Codex access tokens](https://developers.openai.com/codex/enterprise/access-tokens)
| OpenRouter | `OPENROUTER_API_KEY` | [OpenRouter settings](https://openrouter.ai/settings/keys) |
