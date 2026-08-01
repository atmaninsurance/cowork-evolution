# Ponytail vs. the Cowork-me memory architecture

**Prepared:** 2026-07-31 · **Method:** full clone of `DietrichGebert/ponytail` at `main` (156 files, read directly, not summarized from the README) + structural read of `~/Claude/memory`, `~/Claude/Scheduled`, and `~/Documents/Projects/cowork-evolution`.

---

## 0. The headline: it doesn't have one

Ponytail does not include a memory architecture. That isn't a technicality — it's the design.

Its **entire persistent state** is:

- `~/.claude/.ponytail-active` — a file containing one word (`full`)
- `~/.config/ponytail/config.json` — optional, one field (`defaultMode`)
- `~/.claude/.ponytail-statusline-nudged` — an empty file meaning "already offered to set up the badge"

That's it. No logs, no history, no knowledge store, nothing that survives to tell session two what happened in session one. A grep for "memory" across the repo returns two hits, both incidental (an in-memory rate-limiter example).

**Why it looks like a memory system from outside:** Ponytail solves the *other* half of the same problem you're solving. Your system remembers **what happened** — episodic knowledge, decisions, open work. Ponytail installs **how to behave** — a disposition that has to survive every turn, every subagent, and twenty different host platforms. In cognitive-science terms yours is declarative/episodic memory and Ponytail is purely procedural memory. Both live in the same place in an agent's context window, which is why they look alike from a distance.

The useful comparison isn't system-to-system. It's **Ponytail vs. your `rules/` directory** — and on that axis it is genuinely apples-to-apples, because Ponytail has spent months and a public benchmark suite engineering something you built once and never measured.

---

## 1. What Ponytail actually is

A single behavioral ruleset (~1,100 words), distributed to 20+ agent platforms, injected at three lifecycle moments, with an intensity dial and a measurement suite that tries to prove it doesn't work.

### The payload

`skills/ponytail/SKILL.md` — a decision ladder the agent runs before writing code:

```
1. Does this need to exist at all?   → no: skip it (YAGNI)
2. Already in this codebase?         → reuse it, don't rewrite
3. Stdlib does it?                   → use it
4. Native platform feature?          → use it
5. Already-installed dependency?     → use it
6. Can it be one line?               → one line
7. Only then: the minimum that works
```

Plus a hard carve-out list ("never simplify away: input validation at trust boundaries, error handling that prevents data loss, security, accessibility") and an output contract ("Code first. Then at most three short lines").

### The delivery system

| Moment | Hook | What it does |
|---|---|---|
| Session start | `ponytail-activate.js` | Writes the mode flag file, injects the ruleset as hidden context |
| Every user turn | `ponytail-mode-tracker.js` | Parses `/ponytail lite\|full\|ultra\|off`, updates the flag, re-injects on hosts that need it |
| Subagent spawn | `ponytail-subagent.js` | Injects the same ruleset into every child agent |

Three ~100-line Node scripts. That is the whole runtime.

### The intensity dial

One canonical `SKILL.md`; `filterSkillBodyForMode()` strips the rows and examples that don't belong to the active level before injection. **There is no second copy of the document.** Three behaviors, one source of truth, filtered at load time.

### The measurement suite

`benchmarks/` — a real headless Claude Code session editing a real public repo (`fastapi/full-stack-fastapi-template` at a pinned commit), scored on the `git diff` it leaves behind. Twelve feature tickets, four arms, n=4. Plus a seven-task adversarial safety tier where the produced function is *executed* against `../../etc/passwd`, `' OR '1'='1`, and a newline-injected email address.

Results: −54% lines of code, −22% tokens, −27% time, 100% safety retained. The naive "YAGNI + one-liners" prompt gets −33% LOC but drops to 95% safe — it cut the path-traversal guard on the one task where it wrote the fewest lines.

---

## 2. The comparison

| Axis | Ponytail | Cowork-me memory |
|---|---|---|
| **What persists** | one word (`full`) | ~4 MB across 400+ files, monotonically growing |
| **Purpose** | procedural — how to behave | episodic + declarative — what happened, what was decided |
| **Startup payload** | ~2–4k tokens, fixed forever | ~52–65k tokens, growing every day |
| **How it loads** | platform hooks fire it; agent has no choice | the agent is *instructed* to load it and must comply |
| **Intensity control** | `lite` / `full` / `ultra` / `off`, one flag file | none — all or nothing |
| **Subagent inheritance** | explicit `SubagentStart` hook + opt-in regex scoping | none (CLD-00052 open; Dispatch loads its rules by hand) |
| **Drift protection** | `check-rule-copies.js` fails the test suite if any of 7 host copies diverge from canonical | none — MEMORY.md, the Global Instruction, and `eod-prompt.md` are hand-maintained duplicates |
| **Verification** | adversarial benchmark built to falsify the skill | none — 16 rules, zero evidence any changes behavior |
| **Failure stance** | fail open, fail silent, never block | fail loud, FLAG ledger, ATTENTION file on hard FAIL |
| **Retention** | n/a (nothing to retain) | none — nothing is ever pruned |
| **Portability** | 20+ hosts from one canonical rule file | single-surface, and even that has bootstrap misses (CLD-00049) |

---

## 3. Genuine similarities (convergent design)

These are cases where two independent teams solving adjacent problems arrived at the same shape. That convergence is itself evidence the shape is right.

**3.1 Always-load vs. load-on-trigger.** Ponytail's frontmatter `description` field is a long, trigger-phrase-dense paragraph whose only job is to make the host load the skill at the right moment; the ruleset itself is always-on. You have the identical split: `always_load: true` on twelve rules, three load-on-trigger, one surface-gated. Same insight — a rule that must always hold and a rule that fires on a condition are different artifacts with different costs.

**3.2 Rule vs. procedure.** Ponytail separates the always-on `AGENTS.md` ruleset from the on-demand `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt` commands. You separate `rules/` ("a constraint you *check*") from `processes/` ("a procedure you *execute*"). Independently derived, same line drawn in the same place.

**3.3 The deferral ledger.** Ponytail marks deliberate shortcuts inline with a `ponytail:` comment naming the ceiling *and the upgrade trigger*, then harvests them repo-wide with `/ponytail-debt`. Any marker with no upgrade path gets tagged `no-trigger` — "those are the ones that silently rot." This is structurally identical to your `[WIKI-CANDIDATE?]` / `[PROMOTE?]` / `[COMPACTION-ISSUE]` inline flags harvested by nightly EOD. Two systems, same mechanism: cheap inline marker at the moment of the decision, batch harvest later.

**3.4 Explicit non-application boundaries.** Every Ponytail skill ends with a `## Boundaries` section naming what it does *not* govern. Your rules carry an optional `**Boundary:**` field. Both learned that a rule without a stated edge gets over-applied.

**3.5 "Mention is not use."** Ponytail's `isDeactivationCommand()` requires the *entire trimmed message* to equal "stop ponytail" — with this comment:

> *Matching the phrase anywhere in the message turned it off mid-task for ordinary requests like "add a normal mode toggle" — so require the whole message to be the command.*

That is your named defect class, hit independently, and fixed the same way you fixed the unanchored `DAY-COMPLETE` grep. External corroboration that the pattern is real and worth a commons page.

---

## 4. Key learnings, ranked

### 4.1 Move activation from instruction to hook — and leave a visible artifact

**The single biggest structural difference.** Your startup protocol is a *request*: MEMORY.md asks the agent to load rules, read the daily log, check the ledger. CLD-00049 exists because sometimes it doesn't happen, and the 2026-07-31 contingency-ledger line records a fresh instance — *"a missed bootstrap silently costing BOTH the per-turn capture and the safety net, with only the capture failure visible."*

Ponytail engineered this failure mode out by never asking. `SessionStart` fires `ponytail-activate.js`; the platform guarantees it. And critically, activation writes an artifact — the `.ponytail-active` flag plus a `[PONYTAIL:FULL]` statusline badge — so "did it fire?" is answerable at a glance.

**What to take, in order of effort:**

1. **The cheapest, today:** make the greeting print a one-line receipt — `protocol: 12 rules · daily 07-30 (1d gap) · index 109 open · DEC-0103 · ledger OK`. Right now a startup miss is invisible until someone notices missing carry-forward. A receipt turns a silent miss into an obvious one, and it costs nothing.
2. **The flag-file equivalent:** have the receipt also written to `~/Claude/Scheduled/startup-ledger.md`. The nightly then has ground truth on which chats bootstrapped, instead of inferring it from transcript damage.
3. **The real fix, where the platform allows it:** Claude Code has `SessionStart` hooks and you already use `SessionEnd` (`code-session-end-hook.sh`, DEC-0076). Anything that can be hook-fired should be. Remote Cowork can't do this today — but that's a platform gap to name, not a design choice to defend.

### 4.2 Intensity levels for memory load

Ponytail's `lite/full/ultra/off` maps directly onto your sharpest cost problem: **~52–65k tokens before the first user turn, on every chat**, whether that chat is "fix a typo in a seminar email" or "resume the orchestrator authorization design."

`rules/startup-delay-acceptable.md` quotes you defending the delay — *"if there is an initial delay it is worth it, otherwise i'm spending the first few rounds of chat trying to get you up to speed."* That's correct for continuation chats. It is not correct for the marketing chat that will never touch a DEC.

Ponytail's implementation is the part to copy, not just the idea: **one canonical document, filtered at injection time.** `filterSkillBodyForMode()` keeps a single `SKILL.md` and strips the mode-irrelevant lines on the way out. Don't write three startup protocols that drift. Write one, tag its steps, and load the tagged subset.

A plausible shape:

| Level | Loads | ≈ tokens |
|---|---|---|
| `lite` | MEMORY.md + always-load rules + latest `[SESSION-STATE]` only | ~10k |
| `full` | current protocol (default) | ~55k |
| `deep` | full + scope-matched lookback + referenced DECs in full | ~80k |

### 4.3 Cut the payload mechanically — two changes worth ~30k tokens per chat

Ponytail applies its own thesis to itself: the always-injected payload is ~2–4k tokens and is *filtered down* before injection. Yours only grows. Two mechanical fixes with no loss of carry-forward:

- **`action-items/_index.md` is 68 KB (~17k tokens), of which roughly 40 KB is the `*Last updated: …*` footer** — an inlined reverse-chronological changelog of every open/close batch back to 2026-06-03, read at every startup, useful at approximately none of them. Move it to `_index-history.md`. **Saves ~10k tokens per chat, every chat.**
- **The top-15 DEC read is ~22.5k tokens** because modern DECs run 34–60 lines of dense prose. Add a `**Headline:**` one-liner to each DEC. Startup reads 15 headlines (~1k); full text loads on demand when a DEC becomes relevant. **Saves ~21k.** This is a strict improvement — you currently get 15 full DECs and use maybe two.

Together that's most of the way to `lite` without needing modes at all.

### 4.4 Steal `check-rule-copies.js` — the sharpest single idea in the repo

Ponytail keeps `AGENTS.md` canonical and derives seven host-specific copies. `scripts/check-rule-copies.js` byte-compares each copy and **fails the test suite on drift**. But the clever part is what it does about `SKILL.md`, which is *longer* than `AGENTS.md` and therefore can't be byte-compared:

```js
// SKILL.md is the runtime source of truth and is longer than the compact body,
// so it cannot be byte-compared. ponytail: canary, not full equality. Assert the
// load-bearing rules survive verbatim in both.
const INVARIANTS = [
  'in this codebase',
  'ONE runnable check',
  'input validation at trust boundaries',
  'prevents data loss',
  'security',
  'accessibility',
  ...
];
```

**Ten pinned substrings.** Reword a load-bearing rule anywhere and the test trips — which is the reminder to propagate it everywhere.

You have the identical hazard and no check: MEMORY.md's startup protocol, the Cowork Global Instruction, `eod-prompt.md`'s guardrails, and `~/Documents/Agent_Workflow/_meta/authoring-contract.md` all restate load-bearing constraints. `rules/compile-amendments.md` — an **always-load** rule — has pointed at a destination file that no longer exists since 2026-06-28 and carries a REVIEW FLAG nobody has cleared.

A nightly stage that greps ~10 pinned phrases across those four surfaces and FLAGs on absence is about thirty lines of Python and closes that entire class of rot.

### 4.5 Add the persistence clause to rule text

Ponytail's ruleset opens with:

> **ACTIVE EVERY RESPONSE. No drift back to over-building. Still active if unsure. Off only: "stop ponytail" / "normal mode".**

Three separate ideas in twenty words: assert continuous application, name drift as the failure mode, and default to *on* under uncertainty. Your rules are read once at startup and then compete with an increasingly long conversation — with nothing in the text asserting they still hold at turn 80. `auditor-scope` in particular is exactly the kind of rule that fades: the pressure to just fix the thing you found grows with session length.

Cheap to add, and it costs one line per rule.

### 4.6 Subagent inheritance is a hole you already have

Ponytail ships `ponytail-subagent.js` *specifically because* session-start context never reaches subagents (their issue #252) — every `Task`-spawned agent was running ponytail-unaware. Their design, which is directly reusable:

- inject the same ruleset into every child by default
- **fail open** — unknown agent type, unparseable payload, bad regex, or timeout all inject rather than skip
- opt-in `PONYTAIL_SUBAGENT_MATCHER` regex to scope it (e.g. keep it off read-only search agents)

Your equivalent: CLD-00052 (Dispatch has no startup protocol, loads its rules manually), and `dispatch-notification-policy` carries `always_load: false` explicitly because the shared list is loaded by all surfaces. Ponytail's answer is a per-surface rule *matcher* rather than a per-surface rule *list* — one canonical set, filtered by which surface is asking. That generalizes better than what you have and removes the manual step.

*(Note the same fail-open reasoning appears three times in their hooks, always with the issue number that caused it. Their comments name the incident. So do your rules' `**Why:**` fields. Keep doing that.)*

### 4.7 Measurement — the uncomfortable one

You have 16 rules encoding expensive lessons and **zero evidence that any of them changes behavior.** Ponytail's benchmark exists explicitly to disprove itself:

> *"If the arms converge (everyone safe, similar size), the benchmark says so. It is built to be able to disprove the skill's value, not only to confirm it."*

Four techniques worth taking:

**(a) The behavior gate.** `benchmarks/behavior.yaml` asks a question you have never asked: *does the ruleset actually produce the behavior, or does it merely carry the text?* Three probes, with a **no-skill control that should mostly FAIL** — that delta is the whole point. Your version would be cheap: does a chat with the protocol loaded actually refuse to run git in Cowork bash; actually read the clock instead of estimating a date; actually stop at findings in auditor mode. Run it with a no-protocol control. You will find out which of your 16 rules are load-bearing and which are decoration, and that answer directly informs what `lite` mode can drop.

**(b) Self-test before you spend.** Every Ponytail instrument ships a `good` and a `bad` reference and must rank them correctly *before any API call*. The over-engineering judge is itself validated: it must score a deliberately over-built reference strictly above the minimal one, or it isn't trusted.

Apply that to your nightly. **CLD-00097** — Stage 2 died on an API 529 and the ledger recorded `OK`; the day's log was never finalized and a chat got no section at all, found a day later. **CLD-00104** — an 8.5-hour run reported clean. Both are precisely what a good/bad fixture catches: give each stage a known-bad input that it must FAIL on, run it first, and a stage that can't detect its own failure never gets to report success.

**(c) Contamination isolation.** They **superseded their own published benchmark** on discovering that the plugin's `SessionStart` hook was firing on every arm — the control was secretly running the treatment. Any A/B you run on memory-load variants has the identical hazard: the Global Instruction fires regardless of what you're testing. Isolation has to be enforced, not assumed.

**(d) The completeness judge.** LOC alone can be won by shipping a stub, so they added a second judge scoring whether the feature was actually built — *"a low-LOC arm whose completeness also drops is doing less, not less-bloated."*

This is the guardrail for §4.2 and §4.3. **Any startup-trim needs a paired carry-forward check**, or you will optimize the token count by forgetting things and the metric will call it a win.

### 4.8 A standing rot-audit command

`/ponytail-audit` (whole repo) and `/ponytail-debt` (harvest deferrals, tag the ones with no upgrade trigger) are *standing commands* — anyone can run the rot scan at any time.

You have an auditor *scope rule* but no audit *command*. Current visible rot: `design/` empty and marked TBD; DEC-0041 reserved and permanently unused; `compile-amendments` pointing at a deleted file for a month; two graph `.bak` files at 72 MB; `context/project_memory_architecture.md` self-flagging that its figures are stale as of 2026-05-19; the graph itself — 79.7 MB, nightly-refreshed, **never queried at retrieval time**, leaving principle 5's second rung with no runtime caller.

None of that is urgent. All of it is the kind of thing a standing `/memory-audit` surfaces in thirty seconds instead of accumulating for a quarter.

Extend the `no-trigger` idea too: your `[PROMOTE?]` and `[WIKI-CANDIDATE?]` flags carry no close criterion, so a flag can sit unresolved indefinitely. You already added `## Close criteria` to CLDs under DEC-0097 — same idea, one level down.

---

## 5. What NOT to take

**Fail-silent.** Every Ponytail hook swallows its errors and never blocks: *"Silent fail — flag is best-effort, don't block the hook."* That is correct for a code-style nudge, where a miss costs you some verbosity. It is wrong for your system, which is the authorization substrate for headless machinery — a silent miss there is CLD-00097. Your fail-loud posture is the right call and the divergence is principled.

The nuance worth keeping: Ponytail fails open **but leaves a visible artifact** (the statusline badge). Fail-open plus visible beats fail-open plus silent. That's §4.1.

**Statelessness.** Obviously. Ponytail doesn't need to remember anything; you do.

**Minimalism as a governing value for memory.** The ladder is right for code and wrong for a knowledge store — the cost curves are opposite. Code you didn't write has no bugs; context you didn't record can't be recovered. Where the ladder *does* apply is the **injection layer**: what gets loaded into every context window, every session, forever. That's the part where "the best token is the token you never spent" is exactly right, and where §4.2 and §4.3 come from.

---

## 6. Priority

| # | Action | Effort | Payoff |
|---|---|---|---|
| 1 | Move `_index.md`'s changelog footer to `_index-history.md` | 10 min | ~10k tokens per chat |
| 2 | Startup receipt line in the greeting + `startup-ledger.md` | 30 min | turns silent bootstrap misses visible |
| 3 | `**Headline:**` field on DECs; startup reads headlines only | ~1 hr + backfill | ~21k tokens per chat |
| 4 | Invariant-phrase drift check as a nightly stage | ~1 hr | closes the `compile-amendments` rot class |
| 5 | Persistence clause on always-load rules | 30 min | anti-drift in long sessions |
| 6 | Good/bad self-test fixture per nightly stage | ~half day | closes CLD-00097 / CLD-00104 |
| 7 | Behavior gate: do the 16 rules actually change behavior? | ~1 day | tells you what `lite` can safely drop |
| 8 | `lite`/`full`/`deep` startup modes, one filtered protocol | ~1 day | right-sizes cost to the chat |
| 9 | Subagent/Dispatch rule inheritance by matcher | ~1 day | closes CLD-00052 |
| 10 | Standing `/memory-audit` command | ~half day | rot surfaced continuously |

Items 1 and 3 alone recover roughly 30k tokens on every chat you start, and neither costs you any carry-forward.

---

## Sources

All Ponytail claims are from a direct clone of the repository at `main`, read file-by-file — not from the README or third-party summaries. Repository: https://github.com/DietrichGebert/ponytail

Files quoted verbatim: `AGENTS.md`, `skills/ponytail/SKILL.md`, `skills/ponytail-debt/SKILL.md`, `skills/ponytail-review/SKILL.md`, `hooks/ponytail-config.js`, `hooks/ponytail-runtime.js`, `hooks/ponytail-activate.js`, `hooks/ponytail-subagent.js`, `hooks/ponytail-mode-tracker.js`, `hooks/ponytail-instructions.js`, `hooks/claude-codex-hooks.json`, `scripts/check-rule-copies.js`, `benchmarks/README.md`, `benchmarks/agentic/README.md`, `benchmarks/behavior.yaml`, `docs/agent-portability.md`.

Cowork-me figures (file counts, byte sizes, token estimates, graph row counts, open-item counts) were measured live on 2026-07-31 from `~/Claude/memory`, `~/Claude/Scheduled/nightly`, and `~/Documents/Projects/cowork-evolution`. Token figures are estimates at ~4 bytes/token, not measured against a tokenizer.
