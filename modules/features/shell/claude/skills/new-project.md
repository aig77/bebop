---
name: new-project
description: Bootstrap a new project with CLAUDE.md and AGENTS.md
disable-model-invocation: true
allowed-tools: Write Bash
---

Set up this repo with the standard project conventions:

1. Create `AGENTS.md` at the repo root. Use the current working directory and any existing code to infer the project type, stack, and purpose. Include:
   - A brief description of what the project is
   - Build, run, and test commands
   - Repo structure overview
   - Any style or convention notes relevant to the stack

2. Create `CLAUDE.md` at the repo root containing only:
   ```
   @AGENTS.md
   ```

3. Commit both files with message `chore: add project docs`

Do not add unnecessary sections. Keep AGENTS.md concise and specific to this project.
