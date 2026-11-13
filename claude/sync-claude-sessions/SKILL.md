---
name: sync-claude-sessions
description: Sync Claude Code sessions to Obsidian markdown, one file per session. Export, resume, annotate and close sessions; enrich-sessions adds clean titles and summaries. Use when the user says "sync sessions", "export sessions", "resume session", "add session note", "close session" or "log session".
---

# sync-claude-sessions

Claude Code only. Saves each Claude Code conversation as a markdown file in `$CLAUDE_SESSIONS_DIR`, so past sessions stay readable and searchable after Claude Code prunes its own logs.

Setup is in [README.md](README.md). If the hooks are already in place, sync is automatic. Do not set them up again.

## Commands

Run `claude-sessions <command>` (many people alias it to `cs`).

| Command | Does |
|---|---|
| `sync` | Sync the current session (the hooks call this; `--session-id`, `--transcript`) |
| `export` | Batch export (`--today`, `--all`, or one `.jsonl` file) |
| `resume` | Resume a session (`--pick`, `--active`, `--fork`, `--all`) |
| `note "text"` | Add a timestamped comment to the current session |
| `close ["text"]` | Mark the session done, with an optional comment |
| `log` | Annotate: `--status active\|done\|blocked\|handoff`, `--tags`, `--rating 1-10` |
| `list` | List sessions (`--active` default, `--all`, `--json`) |

## Frontmatter

```yaml
type: claude-session
date: YYYY-MM-DD
session_id: uuid
project: my-app           # from the launch directory
title: "..."              # first real user message; enrich-sessions replaces it
summary: "..."            # from the transcript, or from enrich-sessions
skills: [ship-ts]         # skills used in the session
messages: 42
last_activity: ISO timestamp
status: active            # active | done | blocked | handoff
tags: []
rating: null              # 1-10
comments: ""              # from note / close
enriched: true            # set by enrich-sessions
hidden: true              # set by enrich-sessions for trivial sessions
```

A re-sync never overwrites `comments`, `projects`, `status`, `tags`, `rating`, `title`, `summary`, `enriched`, `hidden`, `project` or the `## My Notes` section. One exception: a title that is harness noise (a slash-command envelope) is regenerated, unless the session is already enriched.

## Body

Summary, Skills Used, Artifacts (files created or changed), My Notes, then Conversation: the user and assistant text turns, with tool input and output removed. enrich-sessions summarizes this Conversation section.
