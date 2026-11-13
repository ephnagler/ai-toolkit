# memory

Keep your agent's skills and long-term memory in one git repo, and keep that repo in step across machines.

## The pattern

Agents keep their skills and memory in a home-folder directory (`~/.claude/` for Claude Code) that is not a git repo and does not sync. So:

1. **One git repo holds the real files.** For example `~/notes/brain/` with a `skills/` folder and a `memory/` folder.
2. **Skills are symlinked in.** `link-skills.sh` links each folder in `skills/` into `~/.claude/skills/`. The agent reads the link; git tracks the real file.
3. **Memory points into the repo.** In Claude Code, set `autoMemoryDirectory` in the project's `.claude/settings.json`:

   ```json
   { "autoMemoryDirectory": "~/notes/brain/memory" }
   ```

   Start Claude Code from that repo for planning and cross-project work, so it reads and writes the shared memory. Start it from a project repo for build work, so that work uses the project's own memory.

4. **A timer syncs the repo.** `vault-sync` pulls, commits and pushes it (and any other note repos) every 30 minutes on each machine.

The result: a skill you write or a fact the agent saves on one machine is on the other machine at the next sync, with full git history.

## link-skills.sh

```bash
link-skills.sh ~/notes/brain/skills          # or set SKILLS_SRC
SKILLS_DEST=~/.cursor/skills link-skills.sh ~/notes/brain/skills   # another agent's folder
```

Run it once per machine, and again after you add a skill. It is safe to run again. It never overwrites a real folder at the destination: it warns and skips, so you can move that copy first.

## vault-sync

```bash
vault-sync ~/notes/brain ~/notes/journal     # sync these repos
vault-sync                                   # sync the repos listed in ~/.config/vault-sync/repos
VAULT_SYNC_AFTER="qmd update && qmd embed" vault-sync   # refresh a search index afterwards
```

The list file has one repo path per line. `#` starts a comment, and `~` is expanded.

It exits non-zero if any pull or push fails, or if a repo has a conflict, so a scheduler can alert you.

### Why it is built this way

- **A dead network connection can hang `git push` forever.** After a laptop sleeps or changes wifi, git can wait on a socket that never answers. A `oneshot` systemd service that never finishes also stops its timer from firing again, so sync stops with no error. vault-sync aborts transfers that stall below 1 KB/s for 60 seconds, and kills any git network call after 5 minutes.
- **`git pull --autostash` exits 0 even when the stash conflicts.** Without a check, the next `git add -A` commits the conflict markers and pushes them to every machine. vault-sync checks for unmerged files after each pull, and stops for that repo if it finds any.
- **macOS has no `timeout` command.** vault-sync uses `gtimeout` from coreutils if it is installed, and otherwise keeps only the stall abort.

## Run it on a schedule

systemd (Linux), as user units:

```ini
# ~/.config/systemd/user/vault-sync.service
[Unit]
Description=Sync note and memory repos

[Service]
Type=oneshot
TimeoutStartSec=15min
ExecStart=%h/.local/bin/vault-sync
```

```ini
# ~/.config/systemd/user/vault-sync.timer
[Timer]
OnCalendar=*:00/30
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl --user enable --now vault-sync.timer
```

`TimeoutStartSec` is the outer guard: if everything inside fails to stop, systemd stops it.

On macOS, use a `launchd` agent with `StartInterval` set to `1800`.
