# ship-ts roles

The loop runs five roles. Each role is a separate agent with a fresh context. It gets its instructions from `references/<role>.md`, the feature request, and the `.pipeline/` files. It never sees the orchestrator's conversation.

| Role | Instructions | Reads | Writes | Edits source? | Tier |
|---|---|---|---|---|---|
| Orchestrator | `SKILL.md` | everything | commits on the branch | no | strong |
| Planner | `references/planner.md` | request, project rules, code | `.pipeline/spec.md` | no | **strong** |
| Coder | `references/coder.md` | `spec.md`, project rules | source, `.pipeline/changes.md` | yes | fast |
| Tester | `references/tester.md` | `changes.md`, `spec.md` | tests, `.pipeline/test-results.md` | tests only | fast |
| Reviewer | `references/reviewer.md` + `ts-review-checklist.md` | all handoffs, the diff | `.pipeline/review.md` | **never** | **strong** |
| Advisor (optional) | `references/advisor.md` | branch diff, `review.md` | `.pipeline/advice-in.md` / `advice-out.md` | **never** | strong |

## Model tiers

- **Strong:** the most capable model you have, at high reasoning effort. Planner, reviewer and advisor. The planner sets the quality ceiling, and the reviewer is the gate.
- **Fast:** a cheaper, quicker model at medium effort. Coder and tester. A good spec does most of their work.

**The reviewer must run on the strong tier.** Check that your tool does not silently swap in a default model when you start the reviewer. A demoted reviewer still says SHIP; it just checks less.

### Example: Claude

| Tier | Model | Effort |
|---|---|---|
| Strong (reviewer) | Claude Fable 5.2 (`claude-fable-5-2`) | high |
| Strong (planner, advisor, orchestrator) | Claude Opus 5.5 (`claude-opus-5-5`) | high |
| Fast (coder, tester) | Claude Sonnet 5.5 (`claude-sonnet-5-5`) | medium |

If Fable is not available to you, run the reviewer on Opus. Keep the other roles as they are.

For other vendors, map the same way: their top model for strong, their mid-size model for fast.

## Running the roles in your tool

### Claude Code

Define one subagent per role in `~/.claude/agents/` (or the project's `.claude/agents/`, which wins). The orchestrator passes the role instructions in the prompt, so each file stays short and only pins the model:

```markdown
---
name: ship-reviewer
description: ship-ts reviewer stage. Started by the ship-ts orchestrator, not for direct use.
model: fable
effort: high
---

You are the ship-ts reviewer. Your role instructions, the feature request and the current `.pipeline/` state are in the prompt. Follow them exactly.
```

Make `ship-planner`, `ship-coder`, `ship-tester` and `ship-advisor` the same way with the models above. The orchestrator starts each one with `subagent_type: ship-<role>` and does not pass `model`.

Do not fall back to the general-purpose agent. Without a pinned model it runs on the session default, which can silently demote the reviewer. If a `ship-*` agent is missing, stop and fix the setup.

### Other agents (Cursor, Codex, Aider and others)

If your tool has subagents, define one per role the same way, with the model pinned in the definition.

If it does not, run each role as a new session or chat:

1. Start a fresh session on the role's model.
2. Paste `references/<role>.md`, the feature request and the `.pipeline/` files it reads.
3. Let it write its handoff file.
4. Return to the orchestrator session, which reads the handoff and starts the next role.

This is slower but keeps the one rule that matters: each role sees only its prompt and the files, never another role's reasoning.

## Project files the loop reads

| File | Purpose |
|---|---|
| `AGENTS.md` / `CLAUDE.md` | the project's invariants and conventions; binding on every stage |
| `review-checklist.md` | extra review rules; can add BLOCK conditions |
| `ship-ts-project.md` | loop rules for this one repo; pasted into every stage's prompt |
