# sync-claude-sessions

Claude Code only. Two scripts that work together:

- **`claude-sessions`** saves each Claude Code session as a markdown file, with frontmatter you can filter in Obsidian or search with any tool.
- **`enrich-sessions`** gives each saved session a clean title, a short summary and a "substantive" flag. It runs Haiku through your Claude Code subscription, so it needs no API key.

## Credit

`claude-sessions` is a fork of **sync-claude-sessions** from [personal-os-skills](https://github.com/ArtemXTech/personal-os-skills) by Artem Zhutov, used under the MIT license. His copyright and license are in [NOTICE](NOTICE). `enrich-sessions` is original to this repo.

What this fork changes:

| Change | Why |
|---|---|
| `CLAUDE_SESSIONS_DIR` sets the output folder | Write sessions anywhere, not only `<vault>/Claude-Sessions` |
| `project:` in the frontmatter, from the launch folder | Filter sessions by project without folders |
| Assistant text turns in the Conversation section | The log reads as a conversation, and enrichment has the replies to summarize |
| Titles skip slash-command envelopes and "Caveat:" lines | The first real message becomes the title, not harness noise |
| `summary`, `enriched`, `hidden`, `project` survive re-sync | A re-sync no longer wipes enrichment |

## Setup

1. Put both scripts on your PATH, or call them by full path.
2. Set where sessions go:

   ```bash
   export CLAUDE_SESSIONS_DIR=~/Notes/Claude-Sessions
   export CLAUDE_SESSIONS_PROJECT_ROOT=~/code      # optional; default ~/Work
   ```

   `CLAUDE_SESSIONS_PROJECT_ROOT` sets the project label: a session started in `~/code/my-app` gets `project: my-app`.

3. Add the hooks to `~/.claude/settings.json`, so every prompt and every stop syncs the session:

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         { "matcher": "", "hooks": [{ "type": "command", "timeout": 20,
           "command": "[ -n \"$CLAUDE_ENRICH\" ] && exit 0; claude-sessions sync" }] }
       ],
       "Stop": [
         { "matcher": "", "hooks": [{ "type": "command", "timeout": 20,
           "command": "[ -n \"$CLAUDE_ENRICH\" ] && exit 0; claude-sessions sync" }] }
       ]
     }
   }
   ```

   The `CLAUDE_ENRICH` check matters. enrich-sessions runs Claude Code itself, with `CLAUDE_ENRICH=1` set. Without the check, each of its calls would trigger a sync.

4. Copy this folder to `~/.claude/skills/sync-claude-sessions/` so Claude Code can run the commands for you.

To backfill today's sessions, run `claude-sessions export --today`.

## Enrichment

```bash
enrich-sessions --dry-run --verbose           # show what would change, write nothing
enrich-sessions --file <session.md> --verbose # one session
enrich-sessions --limit 75 --sleep 1          # a paced daily run
enrich-sessions --strategy headtail --sleep 1 # a paced backfill
enrich-sessions --report-usage --limit 50     # tokens and API-equivalent cost
enrich-sessions --force --file <session.md>   # enrich again
```

Run it once a day with cron or a systemd timer. Subscription limits work in rolling windows, so a daily batch is small. Only a first backfill of hundreds of sessions needs `--limit` and `--sleep`.

How it works:

- **The source is the saved markdown, not Claude Code's `.jsonl` logs.** Claude Code prunes old logs. The markdown is the copy that lasts.
- **Each session is enriched once.** `enriched: true` marks it done. Sessions active in the last 6 hours (`--fresh-hours`) are skipped, because they are probably still running.
- **Every session with content goes to the model.** There is no keyword filter. The model marks trivial sessions `substantive: false`, and the script sets `hidden: true` but keeps their title and summary. A short session can still hold one useful fact.
- **Transcript strategies:**
  - `full` (default): the whole conversation. Only very large pastes are trimmed.
  - `headtail`: the first 12 and last 8 messages. The end of a session, where decisions usually are, is always kept. Use it for large backfills.
  - `caps`: every message, each cut short.
- **The call:** `claude -p --no-session-persistence --model haiku`. `--no-session-persistence` keeps the enrichment calls out of your session logs. Do not add `--bare`: it drops subscription login.
- **The transcript is data, not a conversation.** The prompt tells the model to output one JSON object and never to continue the session.

## Search

The session files are plain markdown, so any search tool works. [qmd](https://github.com/tobi/qmd) gives fast local keyword and semantic search:

```bash
qmd collection add "$CLAUDE_SESSIONS_DIR" --name sessions
qmd search 'deploy rollback' -c sessions
```
