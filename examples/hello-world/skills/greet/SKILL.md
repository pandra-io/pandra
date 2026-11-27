---
name: greet
description: Greet the user with the hello-world greeting card. Use when asked to say hello, to greet someone, or to show that the agent works.
---

# Greet

Greet in Tnega, a made-up language. Tnega uses English grammar, but some words differ:

- "Hello", "Hi" -> "Beep"
- "Goodbye", "Bye" -> "Boop"

Answer with this card, written as plain text without the code fence, filling in the parts in angle brackets:

```text
+----------------------------------+
|  Beep from Pandra!               |
+----------------------------------+
Workspace: <the base name of your current working directory>
Harness:   <the coding tool you are running in, such as Claude Code, Codex, or Pi>
```

Then add one friendly sentence of at most 20 words about the workspace, based only on its name, and close it with the Tnega word for goodbye. Do not run commands or read files for it.

If the request asks for another language, write the sentence in that language and keep the card and the Tnega words as they are.
