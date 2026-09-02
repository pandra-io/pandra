# Pandra - Pack and Run Agents

> [!IMPORTANT]
> Pandra is in early beta stage. We are working to release a stable version soon along with the source code.
> During this time, you can learn about Pandra's vision and try out the rolling beta release (and don't forget to star the repo!).
> Please keep in mind that the user experience, the artifact specifications and even the project scope are subject to change.

## What is Pandra?

- Create agents as code [→](docs/manifesto.md#create-agents-as-code)
- Share and deploy agents [→](docs/manifesto.md#share-and-deploy-agents)
- Write once, run anywhere [→](docs/manifesto.md#write-once-run-anywhere)
- Bring your own AI [→](docs/manifesto.md#bring-your-own-ai)
- Manage skills at scale [→](docs/manifesto.md#manage-skills-at-scale)
- Automate with agents [→](docs/manifesto.md#automate-with-agents)
- Isolate harness configurations [→](docs/manifesto.md#isolate-harness-configurations)
- Enjoy agents everyday [→](docs/manifesto.md#enjoy-agents-everyday)
- Build with Pandra [→](docs/manifesto.md#build-with-pandra)

Read more in our [Manifesto](docs/manifesto.md).

## Getting started

### To get started, take the [Tour of Pandra](docs/tour.md).

If you can't help yourself, here's a sneak peek:

```bash
# The hello-world-tnega agent speaks a made up language called Tnega using it's skills

# Run an agent from GitHub
pandra run https://github.com/pandra-io/pandra/docs/examples/hello-world-tnega
# Install an agent for quick and efficient access
pandra install https://github.com/pandra-io/pandra/docs/examples/hello-world-tnega
# Run installed agent
pandra run hello-world-tnega
# Override some agent features for a single run
pandra run hello-world-tnega --prompt "Say bye in Tnega!"
# Use a specific workspace
pandra run hello-world-tnega --ws . --prompt "Say hello into file"
# Select harnesses and LLM
pandra run hello-world-tnega --harness "claudecode" --provider "anthropic" --model "claude-haiku-4.5"
```

## Documentation

- [Installation](./docs/install.md)
- [Tour](./docs/tour.md)
- [Examples](./docs/examples)
- [CLI usage](./docs/cheat-sheets/cli.sh)
- [Agent definition usage](./docs/cheat-sheets/agent.yaml)
- [Complete manual](./docs/manual.md)
