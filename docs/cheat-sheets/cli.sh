pandra --help # show help and usage
# --log-level LEVEL is global and accepts debug, info, warn, or error. The default is info.
# --color MODE is global and accepts auto, always, or never. The default is auto.
# --color MODE and --color=MODE are equivalent and may appear anywhere except as another flag's value.
# auto colors Pandra diagnostic output when standard error is an interactive terminal.
# Redirection, TERM=dumb, or a non-empty NO_COLOR value disables styling in auto mode.
# always colors Pandra diagnostic output regardless of those conditions. never disables color.
# NO_COLOR is consulted only in auto mode, so always overrides it.
# --color applies only to Pandra diagnostic output. It is not forwarded to the harness
# or used to alter the harness environment.
# Pandra passes harness standard error through unchanged.
# --debug is global and may appear anywhere except as another flag's value. It
# enables Pandra debug records and streams one-shot harness standard error.
# An explicit --log-level overrides only the level selected by --debug.
# --log-level=debug alone does not stream harness standard error.

# Build and publish a package dir, then stop.
# pandra build --dir [--file PATH | --path PATH | PATH] [--output DIR] [--debug] [--log-level LEVEL] [--color MODE]
pandra build --dir \
    --file agent.yaml \
    --output ./dist/pandra_package # default: <project-root>/pandra_package

# Build a package. Auto-path prefers a package dir over an agent project.
# pandra build [--package PATH | --file PATH | --path PATH | PATH] [--output FILE] [--debug] [--log-level LEVEL] [--color MODE]
pandra build \
    --package ./pandra_package \
    --output agent.tar.gz # default: ./agent.tar.gz
# Project input builds or refreshes <project-root>/pandra_package before creating the package.
# --file forces project input even when that package dir already exists.

# Run an agent project, package dir, package, registered agent, or Git URL.
# pandra run [NAME|PATH|GIT_URL] [--file PATH | --package PATH | --path PATH]
#     [--tui | --acp] [--prompt TEXT] [--prompt-append TEXT | --input TEXT]... [--profile REF] [--harness HARNESS]
#     [--provider PROVIDER] [--model MODEL] [--claudecode.bare[=BOOL]]
#     [--workspace DIR | --ws DIR] [--env NAME=VALUE]
#     [--env-host NAME=HOSTNAME] [--keep-harness-config] [--debug] [--log-level LEVEL] [--color MODE]
pandra run \
    --path . \
    --profile profile.yaml \ # existing path first, otherwise registered profile
    --harness claudecode \ # profile override: claudecode, codex, or pi
    --provider anthropic \ # profile override: anthropic, openai, or openrouter
    --model claude-sonnet-4-5 \ # profile model override
    --claudecode.bare=false \ # disable Claude Code bare mode; accepted as a no-op for Codex and Pi
    --tui \ # harness terminal; mutually exclusive with --acp and both prompt flags
    --acp \ # ACP over stdio; mutually exclusive with --tui, both prompt flags, and --workspace
    --prompt "say hi" \ # replace the one-shot prompt; mutually exclusive with --tui and --acp
    --prompt-append "about MSFT" \ # append to the one-shot prompt; repeat this flag or its --input alias to append in order; mutually exclusive with --tui and --acp
    --workspace /path/to/dir \ # existing workspace directory; alias: --ws
    --env NAME=VALUE \ # highest-precedence literal environment value
    --env-host NAME=HOSTNAME \ # copy a host variable with the same precedence
    --debug \ # stream agent stderr and enable Pandra debug records
    --keep-harness-config # retain the generated harness configuration
# The retained path is reported at INFO. The directory has private permissions
# and may contain sensitive data.

pandra run # auto-detects . and uses the global default profile
pandra run myagent # registered agent; existing paths win over registered names
pandra run ./pandra_package
pandra run agent.tar.gz
pandra run https://github.com/my/repo//agents/myagent
pandra run https://github.com/my/repo/agents/myagent # GitHub shorthand for //agents/myagent
pandra run https://github.com/my/repo/tree/main/agents/myagent # GitHub browser URL; branch main
# Git runs use the default branch unless a GitHub browser URL selects one.
# // selects a subdirectory. GitHub URLs also accept a single slash after the repository.
# The selected path is detected as package, package dir, then agent project.
# A profile path is always local. Other revision selection and clone caching are not supported.
# Environment precedence is --env/--env-host, profile env, inherited env, then
# agent definition file defaults.

# Profile section order: explicit run profile, stored agent profile, then
# global default. Harness, provider, model, and --claudecode.bare flags override the selected profile.
# Create and register a profile interactively. --file also writes the profile
# document. --default also selects it as the global default.
# pandra profiles new [--file FILE] [--default] [--debug] [--log-level LEVEL] [--color MODE]
pandra profiles new --file profile.yaml --default
pandra profiles set \
    --name work \ # optional override; otherwise uses profile metadata.name
    --file profile.yaml \
    --default \ # replace the one global default
    --debug
pandra profiles list # alias: pandra profiles ls
pandra profiles get --name work
pandra profiles remove --name work
pandra run --file agent.yaml --profile work

# Named local agents. Artifact selectors snapshot the resulting package and profile.
# pandra install is an alias for pandra agents set.
# pandra agents set [--name NAME] [--file PATH | --package PATH | --path PATH | PATH | GIT_URL]
#     [--profile REF] [--harness HARNESS] [--provider PROVIDER] [--model MODEL] [--claudecode.bare[=BOOL]]
#     [--debug] [--log-level LEVEL] [--color MODE]
pandra agents set \
    --name myagent \ # optional; inferred from agent metadata
    --package ./pandra_package \
    --profile profile.yaml \
    --model claude-sonnet-4-5 # optional override stored in the snapshot
pandra agents set https://github.com/my/repo/agents/myagent
pandra install https://github.com/my/repo/agents/myagent
pandra run myagent \
    --profile work \ # explicit profile replaces the snapshotted profile
    --tui \
    --acp \
    --prompt "say hi" \
    --prompt-append "about MSFT" \
    --workspace /path/to/dir \
    --env NAME=VALUE \
    --env-host NAME=HOSTNAME \
    --debug
pandra agents list # aliases: pandra agents ls, pandra ls
pandra agents get --name myagent
pandra agents remove --name myagent # alias: pandra rm --name myagent

pandra ps --debug # list local package runs currently running through pandra; show the runs directory
pandra version
