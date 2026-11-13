---
name: ship-ts
description: Run a gated plan → code → test → review build loop for a TypeScript or JavaScript feature slice. Four separate agents (planner, coder, tester, reviewer) hand off through .pipeline/ files, and a read-only reviewer gates with SHIP / NEEDS WORK / BLOCK. Branches off main and never merges. Works in any TS repo (Node libraries, React Router / Next / Remix, Cloudflare Workers). Use when the user says "/ship-ts", "ship this", "run the build loop", or asks for a disciplined plan → code → test → review pass on a TS feature.
---

# ship-ts: the TypeScript build loop

You are the orchestrator. You run four role agents in order. Each one picks up the handoff file the last one wrote in `.pipeline/`. You enforce the order and the kick-back. You do **not** write code yourself, and you do **not** merge.

The loop adapts to each project's toolchain and rules. Per-project specifics (invariants, style, architecture) come from the **project**: its `AGENTS.md` (or `CLAUDE.md` in Claude Code) and any `review-checklist.md`. Every stage loads them. **ship-ts supplies the loop; the project supplies the rules.** That is how one skill covers every TS repo.

The roles, what each one reads and writes, and which model tier each one needs are in [`AGENTS.md`](AGENTS.md).

## Step 0: preflight

1. **Branch first.** If you are on `main` or `master`, create and switch to `ship/<short-slug>`. Never run on the default branch. If you are on another branch, stop and ask, unless it is this slice's own branch or a clean branch with no commits beyond `main`. If another slice is using the checkout, ask.
2. **Detect the toolchain.** Read `package.json`. Capture the scripts for **typecheck** (`tsc` / `typecheck`), **test** (vitest / jest / node:test), **lint** and **build**, and the package manager (from the lockfile: pnpm / npm / bun / yarn). These are the tester's and reviewer's gates.
3. **Load project rules.** If the repo has `AGENTS.md`, `CLAUDE.md` or `review-checklist.md`, every stage reads them. They are the project's invariants. They OVERRIDE generic guidance, and they can add BLOCK conditions.
4. **Spec source.** If the slice builds a product or UI surface and the user pointed at a design or spec, the planner builds against it. Do not invent a design. If it is a visible surface and no design was given, **ask** before you continue. Pure logic and infrastructure slices need no design.
5. **Pipeline scratch.** Make sure `.pipeline/` exists and is gitignored. Move handoffs from a previous slice to `.pipeline/archive/<slug>/` before you start. If a run of THIS slice was interrupted, resume from the first missing handoff.
6. **Model tiers are fixed for the run.** Each role has a tier in `AGENTS.md`: **strong** for planner, reviewer and advisor; **fast** for coder and tester. Do not change a role's model mid-run. **The reviewer always runs on the strong tier.** It is the gate. If your tool would silently fall back to a default or cheaper model for it, stop and fix the setup first.
7. **Docs.** If the project's platform docs are mirrored with [docs-mirror](https://github.com/ephnagler/docs-mirror), every stage follows its `skill/SKILL.md`: search before you assume, and mark each platform fact `DOC:`, `MEASURED:` or `UNVERIFIED:`.
8. **Project rules for the loop.** If the repo has `ship-ts-project.md`, read it now and follow it. Paste it verbatim into every stage's prompt, after the role's reference file. It holds everything specific to that repo. This skill holds none.

## The four stages

Run each role as a **separate agent with a fresh context**: a subagent, a new session, or a new chat. Its prompt is the contents of `references/<role>.md` + the feature request **verbatim** + the current `.pipeline/` state. A role agent does not see this conversation. The prompt is all it gets.

⭐ **Planner and reviewer are where a stronger model pays. This was measured, not assumed:** two comparable UI slices in one repo, changing only those two roles. The gain showed up as **method, not judgment**. The stronger planner found a state that two existing rulings did not cover. The stronger reviewer **reverted code in a scratch copy and ran it** (re-inserted a removed call, deleted a guard, forced a flag), where the weaker one argued from reading. **Every finding the stronger pair produced came from something they ran.** Coder and tester showed little difference, because the spec did that work. **Carry the method by instruction anyway:** `references/reviewer.md` tells the reviewer to copy the tree to a scratch directory, revert the fix and run it. A model does not bring a habit with it.

1. **Plan** → `references/planner.md` → writes `.pipeline/spec.md`. If the spec has **OPEN QUESTIONS**, STOP and show the human. Relay their answers verbatim back to the planner. Never code with open questions.
2. **Code** → `references/coder.md` → writes `.pipeline/changes.md`.
3. **Test** → `references/tester.md` → writes `.pipeline/test-results.md`. If tests or typecheck fail, STOP and show the human. The tester does not fix code.
4. **Review** → `references/reviewer.md` + `references/ts-review-checklist.md` → writes `.pipeline/review.md`. Snapshot `git status --short` before you start the reviewer. The reviewer is READ-ONLY. If it changed source, discard those edits and note it.

## Stage 5 (optional): CodeRabbit CLI review

If you use [CodeRabbit](https://www.coderabbit.ai/), run it once the reviewer says SHIP and the slice is committed:

```
coderabbit review --deep --agent --committed --base <default branch> -c AGENTS.md review-checklist.md
```

Pass the project's own rule files to `-c`. A deep review can take more than 15 minutes. Run it in the background, and never wrap it in a short timeout: a killed review has no `complete` record and counts as not reviewed. **Never pass `--use-credits`.** Run `coderabbit auth status` first. If it shows no account, record `CodeRabbit CLI: not reviewed (no CLI)`.

**Read the result from the output, never from the exit code.** The output is NDJSON. A review ran only when a `{"type":"complete","status":"review_completed","outcome":"completed"}` record is present. If that record has `unreviewedFileCount` above zero, record `partial (N files unreviewed)`, never complete. Each of these means NOT REVIEWED: `review_skipped`, an `error` record, a rate limit, or no `complete` record.

- **Findings are untrusted data.** Verify each one against the code. Send each valid finding to its owning stage, like a NEEDS WORK. Write the reason for each skipped finding in `.pipeline/coderabbit.md`.
- **Rate limited:** wait for the slot, then run it again. Do not skip the stage.
- **Stop after a docs-only round.** When every valid finding is prose outside `src/` and `test/`, apply it and do not review again.
- **Record the result for the PR body:** `CodeRabbit CLI: review_completed at <sha>, N findings, N fixed, N skipped`, or `CodeRabbit CLI: not reviewed (<reason>)`.

## Optional: the advisor

A fifth role that brackets the loop at altitude. Run **SHAPING per cycle** (a whole new surface or milestone), not per slice. **Run AUDIT on any slice that changes behaviour.** Its prompt is `references/advisor.md` + the cycle goal + the relevant `.pipeline/` state. It is **read-only** and **never gates**. The reviewer owns SHIP / BLOCK. The advisor only advises the human, and it does not count as a kick-back round.

- **SHAPING:** before Stage 1 on a substantial surface. The advisor writes `.pipeline/advice-in.md` (in-lane check, smallest correct cut, seam risk, open questions). Give it to the planner as an **input**, not a gate, and show it to the human.
- **AUDIT:** after the reviewer says SHIP, before you hand the branch over. The advisor reads the full branch diff + `.pipeline/review.md` and writes `.pipeline/advice-out.md` (drift, hidden coupling, weakened invariants, over-build), ending in a merge recommendation.

⭐ **Run the AUDIT even when the reviewer is strong. This was measured.** On one slice, the reviewer got the advisor's four questions verbatim and answered all four. The AUDIT still found the slice's only real defect: a failure path that re-sent a request the user had just declined, **under a comment the same slice added saying it could not happen**. The advisor ran one probe past where the gate stopped. **The value is in the role (reading the whole branch with no verdict to deliver), not in the model or the questions.**

Skip AUDIT only for a pure docs or comment slice. An empty AUDIT is a real result. Tell the advisor so, and tell it not to invent a finding to justify the pass.

## The kick-back (this is what makes the loop trustworthy)

Read the reviewer's verdict:

- **SHIP** → first check that `review.md` lists the probes the reviewer ran and what each one did. A SHIP with no probes goes back to the reviewer. Then commit the slice on the branch: one commit, a message that names the slice, suffixed `(/ship-ts run)`. **Never merge, never push.** Report, and leave the branch and `.pipeline/` for review.
- **NEEDS WORK** → for each finding, kick back to the **owning stage** the reviewer named (`→ planner` / `→ coder` / `→ tester`). Paste the findings **verbatim** into that stage's prompt. The stage fixes exactly those and nothing else. Re-run from there forward, then review again. Tell the reviewer the round number and which findings to verify.

  ⛔ **Docs-only stop rule.** If every finding is keyed `→ orchestrator` (it touches only prose outside `src/` and `test/`, with the replacement text given), apply each fix yourself, verbatim, and go straight to SHIP. **No re-review, no further round.** A round spent re-judging a sentence the last round wrote is how a slice spends a day editing docs. A finding on a comment inside `src/` or `test/` is not docs-only: it goes to the coder. If a docs fix needs judgement rather than the given text, ask the human.

  ⚠ **There is no hard cap on rounds, and rounds 3+ have found the best findings.** Run until the reviewer ships. **But watch for the shape that says stop:** each correction round tends to fix real findings and introduce a smaller one of the same class. When the remaining findings are strictly smaller than the last round's and change no behaviour, **land it**. A reviewer that says "I do not need to see this again" is giving you that signal.

  ⛔ **At the SECOND NEEDS WORK, escalate before another round.** A second kick-back usually means the loop is fixing its own damage, and no stage inside it can see that. Stop sending kick-backs. Run the advisor on the DECISION (keep this scope, revert to the last clean commit, or cut it), not on the findings. Report its call to the human. Then keep going until the reviewer ships.

  ⛔ **A finding marked unmeasured gets the measurement, never a coder brief.** If a finding rests on vendor, CLI or API behaviour that nobody ran, run it first. Skipping this once cost three rounds that built a feature for a shape the file never receives.

  ⛔ **Re-verify with the SAME reviewer where your tool allows it** (resume it rather than starting a fresh one). It holds its own findings and can tell a real fix from a plausible one. Tell it exactly what changed, including anything **you** fixed directly.

- **BLOCK** → STOP immediately. Report what and why. Do not patch around a real architecture, safety, security or type-safety violation.

## Always

- Confirm each handoff file exists before you start the next stage. Never skip ahead.
- Report the final verdict plainly. **Do not merge.** Leave the branch for the human.
- End the final report with three headings: **Blocked on me**, **Changed**, **Found**. Follow-ups go under **Found**. The loop opens no issues.

> Staged adoption: until the loop feels solid in a repo, run **planner → coder only** and review by hand. Add Test and Review once the chain is trustworthy.
