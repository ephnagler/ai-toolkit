# ai-toolkit

Tools I use every day for working with coding agents. Each folder stands alone. Take the parts you want.

| Folder | What it is | Works with |
|---|---|---|
| [`ship-ts/`](ship-ts) | A gated plan → code → test → review build loop for TypeScript. Separate agents per stage, and a read-only reviewer that has to *run* its checks, not just read the diff. | Any agent that reads skill files |
| [`claude/claude-time/`](claude/claude-time) | Active hours with Claude per project, from Claude Code's own logs. | Claude Code |
| [`claude/sync-claude-sessions/`](claude/sync-claude-sessions) | Save every Claude Code session as markdown, then give each a clean title and summary with Haiku. The sync script is a fork of Artem Zhutov's [personal-os-skills](https://github.com/ArtemXTech/personal-os-skills) (MIT). | Claude Code |
| [`memory/`](memory) | Keep skills and agent memory in one git repo, synced across machines. | Any agent; examples use Claude Code |

## Install a skill

`ship-ts/` is a skill: a `SKILL.md` with instructions, plus reference files.

- **Claude Code:** copy or link the folder to `~/.claude/skills/ship-ts/`. `memory/link-skills.sh` does the linking for a whole folder of skills.
- **Cursor, Codex, Aider and others:** reference `ship-ts/SKILL.md` from your `AGENTS.md` or rules file.

`ship-ts/AGENTS.md` lists the roles and the model tier each one needs, with Claude model examples and setup notes for other tools.

## Related

- [docs-mirror](https://github.com/ephnagler/docs-mirror): mirror a vendor's docs to local markdown, so agents can search and cite them. ship-ts uses its citation rules when a project has a mirror.

## License

MIT
