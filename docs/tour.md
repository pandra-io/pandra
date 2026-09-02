<!-- AGENTS: minimize editing to this file. its tone, style and structure were particularly selected by the user. you may fix technical or grammar issues. -->

# A Tour of Pandra

Before getting started, install Pandra and set it up with your preferred harness and LLM provider as described in the [installation documentation](install.md).

## User Experience

Run your first agent:

```bash
pandra run https://github.com/pandra-io/pandra/docs/examples/hello-world-tnega
# Beep!
```

The custom "Hello World" agent speaks "Tnega", a made up language unknown to the underlying model. It runs using your own local agent (claude, codex, etc) that you've selected during installation.

We've taught the agent to speak Tnega using a [skill](https://agentskills.io). As a user, you didn't need to install the skill or even know it existed. This demonstrates one of Pandra's core principles: agents carry their own skills. This pattern streamlines skills management across projects and teams.

If you use the same agent repeatedly, [install](manual.md#agents-inventory) it locally for convenience and efficiency:

```bash
pandra install https://github.com/pandra-io/pandra/docs/examples/hello-world-tnega
# Set hello-world-tnega
pandra run hello-world-tnega
# Beep!
```

You can [override](manual.md#overrides) certain agent properties for a single run. The rest of the agent definition and its skillset remain unchanged. This pattern allows creating and reusing agent templates:

```bash
pandra run hello-world-tnega --prompt "Say bye in Tnega!"
# Boop!
```

Each agent run creates an ephemeral workspace. If you do want the agent to work in a specific or persistent directory, set the workspace for the run:

```bash
mkdir -p /tmp/test && cd /tmp/test
echo "Itay, Teppei" > names
pandra run hello-world-tnega --ws . --prompt 'Say hello to each name in the file "names" in Tnega, and write the result to a new file "greets"'
# Created greets
cat greets
# Beep Itay! Beep Teppei!
```

If you've followed the installation steps you would have set up a default [run profile](manual.md#run-profiles). A run profile selects the target harness, LLM, and credentials for the run. These are user-defined preferences and therefore not part of the agent definition. A run profile is a YAML file with the following shape:

```yaml
apiVersion: pandra.io/v1
kind: AgentRunProfile
metadata:
  name: my
spec:
  harness:
    claudecode: {}
  llm:
    anthropic:
      model: claude-haiku-4-5
  envs:
    - name: ANTHROPIC_API_KEY
      value: 'ant-...'
```

You can set a different run profile for each run, register run profiles for quick access, and set the default run profile:

```bash
# select profile for a run
pandra run hello-world-tnega --profile path/to/another-profile.yaml
# regiser profile for quick access
pandra profiles set --file path/to/another-profile.yaml
# select registered profile
pandra run hello-world-tnega --profile another
# set default profile
pandra profiles set --default --file path/to/another-profile.yaml
pandra run hello-world-tnega
# override profile flags for a run
pandra run hello-world-tnega --harness "claudecode" --provider "anthropic" --model "claude-haiku-4.5"
```

Now that we've seen the basic user experience, lets explore the developer experience.

## Developer Experience

An agent project is a directory with an `agent.yaml`, which defines the agent's name and composition, including prompts, skills and mcp servers.

```yaml
apiVersion: pandra.io/v1
kind: Agent
metadata:
  name: hello-world
spec:
  prompt:
    - text: "say hi!"
```

While it's possible to declare all agent features in the YAML file verbatim, it's more practical to source them from files in the agent project or from remote locations. Let's review our "Hello World" agent from before which demonstrates this:

Project layout:

```
hello-world-tnega/
∟ agent.yaml
∟ prompt.md
∟ skills/
  ∟ tnega
    ∟ SKILL.md
```

`agent.yaml`:

```yaml
apiVersion: pandra.io/v1
kind: Agent
metadata:
  name: hello-world-tnega
spec:
  systemPrompt:
    - git:
        url: https://github.com/pandra-io/pandra/docs/examples/test-sys-prompt.md
```

`prompt.md`:

```yaml
Say Hi in Tnega!
```

Merging the project files with the agent definition yields an agent with the following properties:

1. The agent is identified as "hello-world-tnega".
2. System prompt is fetched from a git repository.
3. Prompt is managed in a file in a local file.
4. Skills are defined in a local directory.

This feels and behaves more like a software project, where code is organized in files, shared code is reused and imported, and everything is tracked and versioned.

To run an agent from its project directory:

```bash
pandra run
# or
pandra run /path/to/project
# or
pandra run https://github.com/my/project
```

Running from source automatically builds the agent for you. Building an agent project performs assets resolution, assets materialization, and packaging.

If you want to avoid rebuilding the agent on every run (to avoid external dependencies, potential failures, and to speed things up), build the agent once and run the artifact instead.

```bash
# Build a package from current project
pandra build
# Run the package in the current directory
pandra run
# Run a pacakge by path
pandra run /path/to/agent.tar.gz
# run a package from a git repo (and build it if necessary)
pandra run https://github.com/my/project
```

The `pandra install` command that we used earlier cloned the repo, built the agent project, and registered the package in one go. Every time you run the installed agent, it uses the cached built package.

If your agent needs [MCP servers](https://modelcontextprotocol.io/), declare it in the agent definition file. For example, to add a [Time MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/time), add the following section to the agent definition:

```yaml
spec:
  mcps:
    - name: time-mcp
      stdio:
        command: ["uv", "tool", "run", "mcp-server-time"]
```

This ensures that the MCP server will be properly configured at runtime. Note however that agents do NOT install anything on the host environment. For example, this MCP server requires `python` and `uv` in order to run, which we did not install.

If you need to package the entire run-time environment, including programming language support, MCP servers and CLI tools, you can package it as a container image.

Start from one of the [official Pandra images](https://github.com/pandra-io/pandra/pkgs/container/pandra), install any required dependencies, and then install your agent package.

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

```bash
docker build -t hello-world-time .
docker run --rm -v profile.yaml:/run/profile.yaml hello-world-time --profile /run/profile.yaml
```

## There's more

Markdown assets can be assembled from multiple parts, each part can be sourced differently. This allows sharing and reusing prompt parts across projects and teams.  
Additionally, the `--prompt-append` flag, also available as `--input`, allows adding prompt parts for a single run. This allows customizing the agent prompt with user-defined values.  
Using these features we can create templated one-shot agents, which ship with mostly stable instructions, and let the user provide values at runtime:

```yaml
apiVersion: pandra.io/v1
kind: Agent
metadata:
  name: stock-analyzer
spec:
  systemPrompt:
    - fs:
        path: systemPrompt.md
    - git:
        url: https://github.com/mycompany/policy/pii-rules.md
  prompt:
    - text: |
        Analyze the requested stock for the selected year and produce a report.
```

Notice the system prompt is assembled from a functional part that belongs to the agent, and from a company-wide policy that is shared via a Git repository.

Also notice that the prompt is intentionally missing a subject, so the user can provide it at runtime: 

```bash
pandra run stock-analyzer --input "stock=MSFT" --input "year=2026" # provide values that complements the prompt
pandra run stock-analyzer --input "symbol=GOOG, this year" # syntax is forgiving since this becomes part of the prompt
pandra run stock-analyzer --prompt "what is EBITDA?" # overriding the entire prompt
```

So far, we've used a non-interactive, one-shot agent. It performs a well-defined task and exits, which is perfect for automations and scripts. But sometimes you do want to chat with the agent.

You can start an interactive agent in your terminal by adding the `--tui` flag:

```bash
pandra run hello-world-tnega --tui
```

A terminal user interface (TUI) opens and you chat freely with the specialized agent (in this case, a Tnega-speaking agent).

You can also bring agents into existing apps, agent control planes, or your favorite IDE using the [Agent Client Protocol](https://agentclientprotocol.com). To learn more, see [here](manual.md#run-modes).

Manage installed and running agents:

```bash
# list installed agents
pandra ls
# remove installed agents
pandra rm --name hello-world-tnega
# list running agents 
pandra ps
```

Now that you have a feel for Pandra, think about how you can use custom agents more in your day to day.

## Next steps

- [Examples](examples)
- [Cheat sheets](cheat-sheets)
- [Complete manual](manual.md)
