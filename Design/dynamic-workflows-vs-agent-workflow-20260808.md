# Dynamic workflows (Anthropic, June 2026) vs. our Agent Workflow design — evaluation

**Date:** 2026-08-08 · **Author:** Claude Code (session per JSONL), David-requested
**Tier:** standard research pass (research skill)
**Primary source:** [A harness for every task: dynamic workflows in Claude Code](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code) — Anthropic blog, 2026-06-02, Thariq Shihipar & Sid Bidasaria. Library deposit: `The_Library/claude-apps/dynamic-workflows-blog-20260602.md`.
**Our-side records compared:** CLD-00109 (conductor workstream, incl. DEC-0102 "compile, don't interpret" and DEC-260119 verifier rework), the front-door end-state map (`front-door-endstate-20260808.md`), ACI-260011 (reconciliation + self-improvement), CLD-00116/DEC-0106 (diagnostic-ticket lane), the research skill (The_Estate).

**Provenance tags:** *verified-article* (from the captured article text) · *verified-harness* (from the live Workflow tool contract in the current Claude Code session — this capability is installed and available here today) · *verified-record* (from our estate/design files) · *estimated* (my assessment).

---

## 1. What the feature is (plain English)

A **harness** is the scaffolding around the model: how a task gets planned, split, checked, and declared done. Claude Code's default harness is one agent in one context window. **Dynamic workflows** let Claude write a small JavaScript control script *at runtime, custom for the task*, which then deterministically spawns and coordinates many subagents — each with its own clean context window, its own model choice, optionally its own isolated git worktree, with structured (typed) outputs passed between steps. *(verified-article; mechanics confirmed verified-harness: the script gets `agent()`, `parallel()`, `pipeline()`, phases, JSON-schema-typed agent outputs, per-agent model/effort selection, worktree isolation, token budgets, and resume-after-interrupt.)*

The article's motivating failure modes for one-context work: **agentic laziness** (declaring done at partial progress), **self-preferential bias** (a model going easy on its own output when judging it), and **goal drift** (losing constraints across compactions). *(verified-article)*

Its named patterns: classify-and-act, fan-out-and-synthesize, adversarial verification, generate-and-filter, tournament, loop-until-done; plus a **quarantine** pattern — agents that read untrusted content are barred from high-privilege actions. Workflows can be saved to `~/.claude/workflows` or distributed inside a skill. Opt-in is explicit (ask for a workflow, or the "ultracode" keyword). *(verified-article)*

## 2. The headline finding: we already chose a side of this fork — deliberately

The article distinguishes **dynamic** workflows (the model authors the harness at runtime) from **static** workflows (pre-written coordination, e.g. Agent SDK / `claude -p`). *(verified-article)*

Our Agent Workflow sits firmly, and by ratified decision, on the **static/declared** side. The conductor design pass (2026-07-31) proposed and David accepted **"compile, don't interpret"**: a workflow definition is a version-controlled file that a deterministic expander compiles into ordinary task files, so every existing gate, screen, and audit path applies unchanged and **no second execution authority exists** (DEC-0102). CLD-00109's required properties — declared deterministic routing, inspectable version-controlled topology, per-step model selection, typed outputs between steps, fan-out and pipeline as first-class, explicit human gates — are point-for-point the same primitives the dynamic-workflows feature ships. *(verified-record)*

**Assessment (estimated):** this is not a conflict; it is two layers with different trust models.

- **The unattended machinery** (orchestrator, worker, designer, verifier — launchd, no human present) is right to stay declared-and-compiled. A runtime-authored harness inside that lane would be exactly the "second execution authority" DEC-0102 refused, and would bypass the screen/attester/red-line stack that took months to build.
- **The supervised surfaces** (this Code session, consulting chats) are where dynamic workflows fit: David present, session permissions in force, high-value one-off work — research passes, design critiques, verification sweeps, backlog mining. Here the harness-per-task idea buys real capability with governance supplied by supervision.

## 3. Overlap map — what the article recommends that we already have

| Article pattern | Our equivalent | Provenance |
| --- | --- | --- |
| Adversarial verification | The whole verifier line: V/D → Verifier rework (DEC-260119), attester dual-control, adversarial diff review (DEC-0104 position 3), reviewer=judge (CLD-00109 thread) | verified-record |
| Self-preferential bias countered by fresh judges | Resident-vs-reviewer ruling: reviewers deliberately have *no* shared memory — "an adversarial reviewer that shares accumulated context shares the author's assumptions" (CLD-00109 settled §3) | verified-record |
| Fan-out-and-synthesize, synthesizer separate | Deliberative fan-out geometry; cold + anchored lenses; "the synthesizer must not be one of the lenses" (CLD-00109 settled §6–8) | verified-record |
| Classify-and-act | The front door: arrival classification → attester → intent judge → Designer lane routing (front-door end-state map) | verified-record |
| Quarantine (untrusted readers can't act) | Trusted-origin ≠ trusted-authority (CLD-00043); judges structurally unable to write the evidence base (DEC-0104 position 2); staged copies I-6 | verified-record |
| Model/intelligence routing | CLD-00106 per-task model field; "different models depending on what is required" (David, 07-31); per-lane tiers | verified-record |
| Token budgets | Shared weekly pool, Fable 50% cap, per-lane slot caps | verified-record |
| Loop-until-done with stop conditions | Bounded retries, continuation caps (CLD-00072), round budgets, DEC-0106's bounded ticket recursion | verified-record |
| Save/share workflows via skills | Estate-canonical skills with thin per-agent loaders (research skill pattern) | verified-record |

The degree of convergence is striking: our design, argued from first principles in consultations, independently arrived at nearly every pattern Anthropic now names as best practice. That is meaningful external validation of the architecture. *(estimated)*

## 4. Where the article's ideas could improve our system

Ordered by expected value; all are proposals, nothing here is authorized. *(all estimated unless noted)*

1. **Workflow-backed deep research.** Anthropic's own `/deep-research` skill is a dynamic workflow: fan out searches, fetch sources, adversarially verify claims, synthesize a cited report *(verified-article)*. Our research skill's deep tier already specifies exactly this shape (delegated researcher + independent refute-first critic + bounded loop-back) but executes it as hand-orchestrated Agent calls. Rewriting the deep tier to use a saved workflow would make the critic/verify steps structural rather than remembered, and typed outputs would replace prose hand-offs. Cheapest win; touches only estate skill files.

2. **"Graduate" workflows into estate property — the reconciliation of dynamic and compiled.** The save-and-share mechanism (workflow file → checked into git → distributed via a skill) *(verified-article/harness)* is precisely how a runtime-authored harness becomes what CLD-00109 demands: inspectable, version-controlled, reviewed before it runs again. Proposed convention: dynamic authoring is allowed on supervised surfaces; any workflow worth repeating is saved, reviewed, and checked into an estate skill — at which point it is a *declared* topology. One-off improvisation stays cheap; anything recurring becomes auditable.

3. **Scout → Analyst venture pipeline (CLD-00109 worked example).** Generate-and-filter and tournament are the article's patterns for exactly this shape: generate many ideas cheaply, filter by rubric, pairwise-judge rather than absolute-score ("comparative judgment is more reliable than absolute scoring" *(verified-article)*). The promotion gate David asked for (score threshold + rank cut) maps cleanly onto a tournament stage. Worth citing in the stage-1/2 build DEC.

4. **Root-cause investigation for the diagnostic-ticket lane (DEC-0106).** The article's competing-hypotheses pattern — separate agents generate hypotheses from *disjoint evidence* (logs vs files vs data), each hypothesis faces refuters, loop until one theory survives *(verified-article)* — is a ready-made shape for how a diagnostic ticket gets worked on a supervised surface before its fix routes through the front door.

5. **Session mining for the ACI-260011 generalization step.** The article's memory-and-rule-adherence use case — mine recent sessions for recurring corrections, cluster with parallel agents, adversarially verify each candidate ("would this rule have prevented a real mistake?"), distill survivors into rules *(verified-article)* — is nearly verbatim the self-growing Designer checklist David ruled on 2026-08-08 (findings → deduped candidates → ratified). A periodic supervised workflow run could be the engine that produces checklist candidates.

6. **Deep verification of design documents before ratification.** One agent enumerates every factual claim in a design doc; one subagent checks each against the live tree *(verified-article pattern)*. We have paid repeatedly for stale claims in design records (DEC-0104's build "corrected the design record" when §3 restated a stale summary instead of reading the code *(verified-record)*). A claim-check workflow run before a ratification consultation would catch that class.

7. **Worktree isolation as the answer to the concurrent-writer class.** Per-agent git worktrees *(verified-harness)* are the platform-native version of what the ACI-260008 saga taught us the hard way: parallel writers on one live tree destroy each other. For supervised multi-agent work on estate repos, worktree isolation should be the default posture. (The machinery's own answer — staged copies, I-6 — is already ratified and stays.)

## 5. Cautions

- **Token cost is real.** The article itself: workflows "often use more tokens and are best suited for complex, high value tasks," and "most traditional coding tasks do not need a panel of 5 reviewers" *(verified-article)*. Our shared weekly pool makes this a budget question, not just advice. Workflows are opt-in by design (explicit request or "ultracode") *(verified-article/harness)*.
- **Governance boundary restated:** nothing above proposes putting runtime-authored harnesses inside the unattended machinery. DEC-0102's compile-don't-interpret stands; the proposals in §4 all live on supervised surfaces or pass through the existing front door as ordinary intakes.
- **Version dependence.** The Workflow tool's exact contract (function set, caps, budget semantics) is CLI-version-dependent; the nightly repin stage is the change-exposure moment, same class as the `--tools` fragility noted on CLD-00109 *(verified-record)*.

## 6. What this rests on / what's still unverified

**Rests on:** the captured article text (Library deposit above); the live Workflow tool contract present in this session's harness; CLD-00109 and its cited DECs; the front-door end-state map; the research skill file. **Unverified:** the article references a Bun Zig→Rust rewrite thread and an Anthropic million-line-migration article — cited by the article, not independently fetched; one in-body table (the workflow function reference) did not survive HTML extraction, its content confirmed instead from the live harness contract; whether the `/deep-research` skill referenced in the article is available in *this* environment's skill roster (it is not in the current session's skill list — the estate research skill is what we have here).
