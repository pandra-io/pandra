# Example agents

Each directory here is an agent project: a `pandra.toml` with the files it names. Run one straight from GitHub, from any directory, without cloning this repository. The first run of an agent shows what it contains and asks you to approve it.

| Agent | What it does |
| --- | --- |
| [hello-world](hello-world/) | Greets you with a card that shows Pandra delivered its instructions, its skill, and its initial prompt. |
| [reviewer](reviewer/) | Reviews the changes in your repository, built from widely recommended parts: Karpathy's coding guidelines, the ponytail-review skill, and the Context7 MCP server. |

## hello-world

The smallest agent that uses every part a definition usually has: instructions (`instructions.md`), one skill (`skills/greet`), and an initial prompt (`prompts/initial.md`). It reads and changes nothing in the workspace.

Run it headless. The initial prompt is the message, so no `--prompt` is needed, and the answer goes to stdout:

```sh
pandra run github.com/pandra-io/pandra/examples/hello-world --harness claude-code
```

The answer looks like this, with your directory's name and the harness filled in:

```text
+----------------------------------+
|  Beep from Pandra!               |
+----------------------------------+
Workspace: my-project
Harness:   Claude Code

Hope my-project is treating you well today, Boop!

-- hello-world agent
```

Each part of the answer shows that one part of the agent arrived:

- "Beep" and "Boop" are words of a made-up language that only the skill defines, and the initial prompt, `Say hello.`, does not name the skill, so they show that the harness loaded the skill and chose it by its description.
- The last line comes from the instructions.
- The answer itself shows that the initial prompt was sent.

To check that `--prompt-append` reaches the agent, ask for the sentence in another language:

```sh
pandra run github.com/pandra-io/pandra/examples/hello-world --harness claude-code \
    --prompt-append "Write the sentence in Japanese."
```

## reviewer

A code reviewer for the repository you run it in. It reads the uncommitted changes, or the last commit when there are none, and reports what is wrong with them, most severe first, each finding with its `path:line` and a suggested fix. It never changes your files.

It is made of parts that many coding-agent setups recommend, each pinned in `pandra.lock`:

| Part | Source | What it adds |
| --- | --- | --- |
| Instructions | [`CLAUDE.md`](https://github.com/forrestchang/andrej-karpathy-skills/blob/2c606141936f1eeef17fa3043a72095b4765b9c2/CLAUDE.md) of forrestchang/andrej-karpathy-skills, at a commit | Karpathy's guidelines against common LLM coding mistakes: hidden assumptions, overcomplication, and changes nobody asked for |
| Instructions | `instructions.md` | What to review, the form of the review, and that a headless run states its assumptions instead of asking |
| Skill | [`ponytail-review`](https://github.com/DietrichGebert/ponytail/tree/v5.3.3/skills/ponytail-review) of DietrichGebert/ponytail, at `v5.3.3` | A review in order of importance: correct, safe, holds under load, tested, fast, lean |
| MCP server | [`io.github.upstash/context7`](https://github.com/upstash/context7) 4.7.0, remote | Current documentation of the libraries a change uses, so the reviewer checks an API instead of guessing |
| Initial prompt | `prompts/initial.md` | "Review the uncommitted changes in the workspace. If there are none, review the last commit." |

Run it headless from inside the repository to review:

```sh
cd ~/src/my-project
pandra run github.com/pandra-io/pandra/examples/reviewer --harness codex > review.md
```

To review something else, replace the initial prompt:

```sh
pandra run github.com/pandra-io/pandra/examples/reviewer --harness codex \
    --prompt "Review the changes since main."
```

Context7 works without an API key, within its rate limits for anonymous use. To use a key, supply it as the server's `Authorization` input ([supplying values to servers](../docs/mcp-servers/README.md#supplying-values)).

## Running from a branch or a clone

To run an agent as it is on another branch or at a tag, add `@` and the ref:

```sh
pandra run github.com/pandra-io/pandra/examples/hello-world@main --harness claude-code
```

From a clone of this repository, run the local copy instead:

```sh
pandra run ./examples/hello-world --harness claude-code
```
