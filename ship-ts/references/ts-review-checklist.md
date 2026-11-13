# ship-ts · TypeScript review checklist (flag immediately)

The reviewer's primary instrument. Flag anything here on sight; escalate the structural ones to BLOCK. The project's own rules files (`AGENTS.md` or `CLAUDE.md`, and any `review-checklist.md`) can ADD invariants — those are binding too.

## BLOCK-worthy (can't be patched in place / violates a contract)
- **Type dishonesty** — `any` used to dodge a real type; `@ts-ignore` / `@ts-expect-error` hiding a genuine error; a cast that launders unsafe/untrusted data; a public API whose types lie about its runtime shape.
- **Runtime-boundary leak** — server-only code (secrets, private keys, DB, secret env) reachable from the client bundle; Node-only APIs in an edge/Workers runtime (or browser APIs on the server); the wrong SSR primitive for the runtime.
- **Secret exposure** — a key, token, or credential in source, in a client-visible variable, or logged.
- **Scope creep / lane drift** — the slice does things the spec didn't ask for, or rewrites a stable seam that should have been extended additively.

## NEEDS-WORK (fixable in place — key to the owning stage)
- Doesn't pass the project's `typecheck` or `lint`.
- Tests are green but shallow (assert "it ran", not the promised outcome) → `→ tester`.
- Missing an edge case the spec named → `→ coder` or `→ tester`.
- Doesn't match the surrounding idiom (naming, module layout, error handling, comment density).
- Duplicated logic that should reuse an existing util; dead code; a `TODO` left as a real gap.
- Unhandled error / loading / empty states in UI; unhandled promise rejection; a missing `await`; an unbounded loop or missing cancellation on a long task.
- A fabricated abstraction — a wrapper / service / layer the spec didn't need.
- **A comment doing the wrong job.** Flag: a comment that **restates a ruling** instead of pointing at
  the doc that owns it; a comment that **re-asserts a measurement** instead of citing its dated
  source; and — worst, because it fails silently — a comment **citing a path that is gitignored,
  scratch, or otherwise absent from a fresh clone.** That last one reads as authoritative and resolves
  to nothing. Comments that state *what this code must not do, at the line where the mistake happens*
  are correct and must not be stripped.

- **A test that cannot fail** → `→ tester`. The recurring shapes: a self-comparison (`expect(x).toBe(THE_CONSTANT)` where `x` is that constant); an optional call (`handler?.()` is a no-op when absent, so "nothing further happened" passes with the handler removed); an empty-sink assertion where the sink was never wired; a test that reimplements the logic it checks; a `not.toContain` that passes forever once the thing is deleted. ⚠ **Naming is not evidence** — probe it.
- **A rule, type or abstraction with ZERO live instances** — usually because the case that motivated it changed mid-slice. It should be **withdrawn, not softened**: an unexercised rule reads as precedent and gets cited.
- ⭐ **A human's ruling recorded WIDER than they gave it.** Check the subject did not grow — *"a declined dialog"* is not *"a decline"*, *"no modal"* is not *"no toast"*. This is how a preference becomes a constraint, then a comment, then a pinned test, with nobody having agreed to it. When unsure, say the record should quote them verbatim.
- **A line number in a comment or doc.** They go stale inside a single slice. Prefer identifiers.

## Verdict contract
- **SHIP** — passes all of the above + the project's own invariants.
- **NEEDS WORK** — list each with `file` + the **identifier** + the fix + `→ owning stage`. ⚠ Address findings by identifier, not line number: the diff moves under you between rounds.
- **BLOCK** — name the violation and why it can't be patched in place.

> ship-ts supplies this generic TS bar. The **project** supplies its specifics via its rules files (`AGENTS.md` or `CLAUDE.md`, and any `review-checklist.md`) — for example "every query is scoped to the current tenant", "no third-party script loads before consent", "public API types change additively only". Load and enforce those; they can be BLOCK conditions.
