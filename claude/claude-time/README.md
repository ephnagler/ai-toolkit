# claude-time

Claude Code only. Shows how many active hours you spent with Claude, per project, from the session logs Claude Code already keeps in `~/.claude/projects`.

```
Time with Claude  gap: 10m | this month

Project       Sess  Active  Msgs  Range
api             14   14.8h  4975  11/01 - 11/04
web             10    5.6h  1358  11/01 - 11/04
docs             8    2.3h   950  11/01 - 11/04

TOTAL  32 sessions  22.7h  7283 msgs
```

One Ruby file. It uses the standard library only, with no gems.

## Use

```bash
claude-time                      # all time
claude-time --today              # also --week, --month, --quarter, --year, --lastyear
claude-time --since 2026-10-01 --until 2026-10-31
claude-time --month --gap 15     # a longer pause still counts as active
claude-time --month --json       # for scripts and invoices
claude-time config               # show the config in use
```

## How "active" is counted

Each session is a list of message timestamps. The time between two messages counts as active only when the gap is 10 minutes or less (`--gap`). A longer pause means you were away, and it counts as zero. So a session left open overnight adds only the time you were actually working.

## Project names

Claude Code stores each session under a folder named after the directory you started it in, with `/` changed to `-`. That loses information: `my-app` and `my/app` look the same. claude-time resolves the name against real folders under your project roots, longest name first, so `~/Work/my-app` comes out as `my-app`.

## Config

Optional. `~/.config/claude-time/config.json`, or set `CLAUDE_TIME_CONFIG`.

```json
{
  "gap_minutes": 10,
  "project_roots": ["~/Work/clients", "~/Work"],
  "project_aliases": { "api-v2": "api" },
  "ignored_projects": ["~", "work"],
  "extra_session_dirs": ["~/backups/other-laptop/projects"],
  "claude_ai_exports": ["~/exports/claude-ai/**/conversations.json"],
  "conversation_projects": { "<conversation uuid>": "api" }
}
```

| Key | Does |
|---|---|
| `gap_minutes` | default for `--gap` |
| `project_roots` | folders whose children are projects; the most specific root wins. Default `["~/Work"]` |
| `project_aliases` | rename or merge projects |
| `ignored_projects` | leave these out |
| `extra_session_dirs` | more Claude Code `.jsonl` logs, for example copied from another machine |
| `claude_ai_exports` | `conversations.json` files from a claude.ai data export |
| `conversation_projects` | assign a claude.ai conversation to a project by its uuid |

A claude.ai conversation can also name its project itself: start the first message with `project: <name>`.
