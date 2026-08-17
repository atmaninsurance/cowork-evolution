# DeepSeek Harness (`dsh`) — "everything is a plugin": how it works, and how it maps onto our estate

**Date:** 2026-08-16 · **Tier:** standard (one delegated researcher; 34 tagged claims; link check on this file) · **Session:** `efd1012f` (Code) · **Asked by:** David — *"research a recent deepseek harness where everything is a plugin. How does it work? What are the pros and cons? How would it work with our setup? How would it differ by system? (claude, codex, Alfred)"*
**Library deposit:** `~/Documents/The_Library/deepseek-harness/` (16 sources + sidecars, uncommitted — nightly sweep owns it).
**Provenance tags:** **[V]** verified against a fetched primary source · **[E]** estimated (our own reasoning) · **[I]** inferred-related.

---

## 0. Headline (plain English)

DeepSeek open-sourced an **agent harness** on 2026-08-13 — the software shell that sits between a model and the world (tools, files, sessions, permissions, UI). Its one idea: **there is no core.** The model adapter, the tool registry, the session log, the sandbox, the UI, and even the loop that runs the agent are all plugins, composed from a YAML config at boot, and any of them can be swapped without forking the codebase. It's a **developer preview** (v0.1.0-rc.6), MIT-licensed, TypeScript, ~130k GitHub stars in three days, and DeepSeek is **not accepting outside pull requests** — they call it "an idea, an official showcase, and a source of inspiration, but not a mandate." **[V]**

For us: it is **not a replacement** for Claude Code, Codex, or Alfred's OpenClaw — none of those are the problem it solves. What it *is* is (a) the best-articulated version of a design principle our machinery already leans toward, and (b) a plausible **fourth executor substrate** for the front door once it stabilises, because it runs headless, is model-agnostic, has a Python SDK, and logs every model-visible byte to an append-only event stream we could audit. **[E]** Recommendation in §6: watch, don't adopt; borrow two ideas now.

---

## 1. What it is **[V]**

- Repo `deepseek-ai/deepseek-harness`, created 2026-08-13, TypeScript, MIT, default branch `master`. Install: `npx @deepseek-ai/dsh web` → local Web UI on `127.0.0.1:3080`. Also a Python SDK (`pip install deepseek-harness-sdk`, ships its own runtime binary — no Node needed) and a TypeScript SDK.
- README, verbatim: *"It uses an architecture where **everything is a plugin**, and is powered by Cordis, whose design is described in A Programming Paradigm for Spatiotemporal Composability."* And: *"THERE WILL BE COMPATIBILITY-BREAKING CHANGES."*
- Contribution posture: *"We are sorry that we cannot accept external pull requests at the moment"* — extend by writing plugins (GitHub topic `dsh-plugin`), not by patching the harness.
- Session format version is **0**, *"with no compatibility promise"* (their AGENTS.md).

Sources: [README](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/README.md) · [repo API](https://api.github.com/repos/deepseek-ai/deepseek-harness) · [CONTRIBUTING](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/CONTRIBUTING.md) · [AGENTS.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/AGENTS.md) · [landing page](https://deepseek.com/harness/en/)

## 2. How it works — the systems view

Think of it as **a tree of parts, assembled at startup from a parts list, where every part can be unplugged cleanly.**

### 2.1 The plugin model (Cordis) **[V]**
- **A plugin** is a small unit of code with a name and an `apply(ctx)` function. It runs against a **context** — a shared registry where services live under keys (`ctx.llm` = the model, `ctx.tools` = the tool registry, `ctx.sessions` = session storage, `ctx.sandbox`, `ctx.subagents`, `ctx.jobs`, `ctx.shell`…).
- **Dependencies are declared, not hard-wired.** A plugin says `inject: ['tools']` and simply waits until something provides `tools`. Swap the provider and every consumer follows.
- **Registrations are reversible.** Anything a plugin adds (a tool, an event listener, a model adapter) is an "effect" that is unwound when the plugin is unloaded — so the config file can be edited while the harness runs and the tree **hot-reloads** to match (they call this HMR). Architecture doc: *"There is no privileged core to patch."*
- **Cordis** is the underlying framework — a meta-framework from Peking University / DeepSeek researchers (paper "A Programming Paradigm for Spatiotemporal Composability", 88-page draft dated 2026-08-13). *Temporal* composability = a component's side effects can be fully reverted on removal; *spatial* composability = components declare and reactively manage dependencies on each other. Cordis v3 has run the Koishi chatbot framework for ~4 years; the paper presents v4.

Sources: [architecture.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/architecture.md) · [cordis-primer.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/cordis-primer.md) · [Cordis paper repo](https://github.com/cordiverse/paper)

### 2.2 Configuration = layered YAML **[V]**
- A running `dsh` is *"a plugin tree composed at boot from ordered layers"*: **bundles** (npm packages that declare a `cordis.patch.yml`) stacked by a **profile** (`~/.dsh/profiles/<name>/`), then the profile's own patch, then a home-level patch, then `--patch` overlays on the command line. Each row is `{id, name, config, disabled}`; a patch replaces a row's whole config (no deep-merge) or inserts rows. `dsh --profile web --dump-config` prints the assembled tree.
- Three shipped bundles: `dsh-base` (adapters, tools, persistence, sandbox/approval, credentials, telemetry), `dsh-web-app` (browser UI), `dsh-headless` (one-shot CLI).
- **Third-party plugins**: `dsh plugin --profile <name> add <pkg>` (npm, git, or local path); anything with a `dsh.bundle` declaration auto-joins the stack. A scratch `.ts` file can be mounted by absolute path for local development.

Sources: [CLI reference](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/apps/cli/reference/README.md) · [app-boot](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/boot/app-boot/README.md) · [publish guide](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/user/develop/basic/publish.md)

### 2.3 The session log — the part most relevant to us **[V]**
- *"A `Session` is an **append-only log** of typed `SessionEvent`s — the single source of truth… The LLM message history is derived from the log, never stored separately; replay is re-derivation from the same events."*
- Invariant: *"**Model-visible means logged.** Anything that reaches a model request must be reconstructable from the log, and a runtime invariant asserts it."* System prompts, reasoning, tool calls/results, subagent scheduling, every context injection.
- Persistence: JSONL (`session.jsonl.zstd` per session, first line an immutable header with id/cwd/parent/depth) or SQLite; `session-query` gives full-text search + lineage. **Fork** a session at any turn boundary; **resume** and **replay** operate on the same stream. The Web UI has a "Trajectory view" to inspect what the model saw, by source.
- Caveat: schema is documented in TypeScript types but is **format version 0, no compatibility promise**.

Sources: [session.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/subsystems/session.md) · [JSONL backend](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/session/session-persistence-jsonl/README.md) · [session-query](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/subsystems/session-query.md)

### 2.4 Loop, subagents, sandbox, permissions **[V]**
- **Loop:** a *step* = one model request + the tools it calls; a *turn* = zero or more steps. Interception points (`agent/pre-step`, `agent/request`, `llm/stream`, `tools/pre-execute|execute|post-execute`, `agent/turn-stopping`) are where plugins hook in.
- **Subagents:** a registry where multiple providers coexist — in-process spawn/fork, ACP, **Codex**, **Claude Code** (invokes the official Claude Agent SDK, using the user's own `claude` install/login), and dsh-SDK. Codex and Claude Code providers *"load dormant"* in the base bundle. Tools: delegate, `send_message`, `interrupt_agent`, `list_agents`; capabilities include `outputSchema`, `depthLimit`, `toolFilter`, `persona`.
- **Sandbox:** modes `read-only | workspace-write | danger-full-access` (file effects only — network/process visibility explicitly out of scope). Backends: Linux bwrap/Landlock, **macOS Seatbelt**, Windows ACL. Enforcement honestly reported as `full` or `partial`.
- **Approval:** `allowed-once | rejected | cancelled | unavailable`, fail-closed; policy `ask` or `never`. Permission presets bundle sandbox+approval (`workspace-write`+ask is the default; `danger-full-access`+never).
- **Runtime modes:** Standard, Code (tools exposed via a "Code Mode SDK" so the model writes one TypeScript program instead of many tool calls), Minimal (persistent bash + editor), Creator (runtime inspection; the agent can write and mount plugins into its own live runtime via `cordis_define/run/undefine`).

Sources: [architecture.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/architecture.md) · [subagent.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/subsystems/subagent.md) · [claude-code subagent](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/subagent/subagent-claude-code/README.md) · [sandbox.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/subsystems/sandbox.md) · [approval.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/subsystems/approval.md) · [tool-cordis](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/extensions/tool-cordis/README.md)

### 2.5 Compatibility with the Claude Code / Codex world **[V]**
- **Instructions files:** loads `AGENTS.md`-compatible files (home, then project root → cwd); a `CLAUDE.md` that duplicates its sibling `AGENTS.md` is rendered once; 64 KB render budget.
- **Skills:** `SKILL.md` bundles with `name`/`description`/`whenToUse` frontmatter — same shape as ours — discovered from `<project>/.dsh/skills`, `<project>/.agents/skills`, `~/.dsh/skills` (**not** `.claude/skills`).
- **Hooks:** native = a Cordis plugin; bridges `dsh-hooks-claude-code` / `dsh-hooks-codex` run *the command-hook subset* of an existing Claude Code `hooks` config (`SessionStart`, `UserPromptSubmit`, …); http/mcp/prompt hooks skipped; described as *"only a compatibility path"*.
- **MCP client:** yes (stdio + streamable-http), tools named `mcp__<server>__<tool>` — the same shape Claude Code and Codex use. **No MCP server** package.
- **Models:** provider-agnostic. Direct DeepSeek adapter plus a generic multi-provider adapter built on Pi's `pi-ai` library (Anthropic, OpenAI, Bedrock, Vertex, Azure, custom OpenAI-compatible gateways). **[I]** Ollama/local: `ollama` appears nowhere in dsh's tree, but pi-ai supports any OpenAI-compatible endpoint (an OpenAI-compatible base URL on `localhost:11434`) and dsh's "custom provider" is exactly that — should be config, not code; **not tested, not documented by name.**

Sources: [agent-instructions](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/context/agent-instructions/README.md) · [skills.md](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/subsystems/skills.md) · [hooks-claude-code](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/hooks/hooks-claude-code/README.md) · [mcp-client](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/mcp/mcp-client/README.md) · [providers guide](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/user/guide/providers.md) · [pi-ai on npm](https://registry.npmjs.org/@earendil-works%2Fpi-ai)

### 2.6 Headless / embedding / channels **[V]**
- `dsh --profile headless "job"`: one fresh persisted session, prints the final answer, exits 0/1. Limitation: *"One submitted task only — the runner has no interactive follow-up surface."*
- **Python SDK:** `DeepSeekHarness(provider=, model=, cwd=, session_root=)` → `harness.run(prompt, session_id=)`; reusing a `session_id` continues the same durable conversation and persistent Bash. macOS 14+ arm64 supported. Default composition is `danger-full-access` — *"Run it only inside a disposable checkout or container."*
- **ACP server** (Agent Client Protocol over JSON-RPC stdio) for automation.
- **No chat channels at all** — no Telegram/Slack/Discord/WhatsApp/web-chat plugin anywhere in the ~8,600-file tree (grep of the full tree). The only human surfaces are the local Web UI (single-user, loopback) and the CLI.

Sources: [headless bundle](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/bundle/headless/README.md) · [Python SDK guide](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/docs/user/guide/python-sdk.md) · [ACP](https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/master/packages/acp/acp/README.md) · [tree API](https://api.github.com/repos/deepseek-ai/deepseek-harness/git/trees/master?recursive=1)

---

## 3. Pros and cons

| | Pro | Con |
|---|---|---|
| **Architecture** | Every capability swappable from config; no privileged core; hot-reload; clean unload. Armin Ronacher (Pi): *"the first time I have been looking at something new in the space and felt quite inspired to revisit some of our choices."* **[V]** | HN Pi-side commenter: cross-plugin dependency injection *"comes with a lot of footguns… most plugins do not have dependencies on each other."* Reviewers: *"over-engineered for everyday development."* **[V]** |
| **Traceability** | "Model-visible means logged"; append-only event stream; fork/resume/replay/search on one stream; CoT reasoning retained. **[V]** | Log format version 0, no compatibility promise; SQLite/JSONL schema is code-documented only. **[V]** |
| **Model choice** | Provider-agnostic; DeepSeek, Anthropic, OpenAI, gateways; The New Stack: *"nothing in the harness ties it to DeepSeek's models."* **[V]** | Local models (Ollama) inferred-only, not documented by name. **[I]** |
| **Interop** | Reads AGENTS.md/CLAUDE.md, SKILL.md skills, MCP client, Claude Code hook bridge, spawns Claude Code / Codex as subagents. **[V]** | Bridges are explicitly "compatibility paths"; skills root is not `.claude/skills`; no MCP server. **[V]** |
| **Safety** | Real OS sandboxes (Seatbelt on macOS), fail-closed approvals, honest `full/partial` enforcement reporting. **[V]** | Sandbox is file-effects only (no network/process isolation); Python SDK defaults to `danger-full-access`. **[V]** |
| **Maturity** | 130k stars in 3 days; MIT; clear docs; Cordis v3 has 4 years of production behind it. **[V]** | Developer preview; breaking changes promised; **no external PRs accepted**; one reviewer reports ~3–10× token usage vs peers (preliminary, unverified). **[V as reported]** |
| **Surfaces** | Web UI, headless CLI, Python/TS SDK, ACP. **[V]** | No chat channels; headless is one-task-per-process; TypeScript-heavy to extend natively. **[V]** |

Commentary sources: [The Register 2026-08-14](https://www.theregister.com/ai-and-ml/2026/08/14/deepseeks-innovative-harness-treats-everything-as-a-plug-in/5288095) · [The New Stack 2026-08-13](https://thenewstack.io/deepseek-harness-open-source-plugins/) · [Justin3go review 2026-08-15](https://justin3go.com/en/posts/2026/08/15-deepseek-harness-review) · [HN thread](https://news.ycombinator.com/item?id=49285244) · [CodePick](https://codepick.dev/en/guides/deepseek-harness-intro/)

---

## 4. How it would work with our setup **[E — our reasoning, grounded in the estate designs]**

Frame: our estate already has a harness-of-harnesses. The **Agent_Workflow front door** (intake → screen → attester → Designer → Verifier → route) hands work to **executor lanes**, and each lane is *"one fresh `claude -p` session with its own context and its own transcript"* run through `_lib/run_claude.sh` (headless, stdin from `/dev/null`, watchdogs, JSONL forensics on kill). Continuity between attempts is *filesystem-only*. The Reviewer judges the outbox; the Housekeeper watches for absences; the nightly chain rebuilds transcripts from the Code JSONL and commits everything. (Design docs: `The_Estate/designs/machinery/executor-lanes.md`, `estate-map.md`.)

Against that, dsh slots in three ways:

**A. As a fourth executor substrate (worker-dsh) — plausible later, not now.**
- Fits our lane contract well: `dsh --profile headless "job"` or the Python SDK gives exactly the "one fresh session, print result, exit 0/1" shape `run_claude.sh` already wraps; a `run_dsh.sh` sibling would be small. Its per-session JSONL is *more* complete than Code's (system prompt + every injection logged) — the handoff-writer rung of the CLD-00072 ladder would have strictly better forensics.
- Model-agnostic means one lane could run DeepSeek V4, Anthropic, OpenAI, or (inferred) a local Ollama model — the "different model substrate, same lane structure" idea from the planned worker-codex lane, generalised.
- Blockers today: rc status with promised breaking changes; format-0 session log (any parser we write breaks); no external PRs (bugs we hit are ours to plugin around); our screen's model allowlist (`sonnet`, `opus`, `fable`) and every DEC that names Claude semantics (DEC-0091 grants, DEC-0104 screen) would need a substrate-neutral restatement first. **[E]**

**B. As the orchestrator itself — no.**
- Our topology principle is *"compile, don't interpret"* — workflow definitions are files expanded into task files so every gate applies; *no second execution authority* (DEC-0102). dsh's Creator mode (agent writes and mounts plugins into its own live runtime) and its hot-reloading plugin tree are the opposite posture: a live, self-modifying interpreter. Powerful, but exactly the "second authority" DEC-0102 rules out. **[E]**

**C. As a source of two ideas we can take now, harness-independent.**
1. **"Model-visible means logged"** as an *asserted invariant*, not a convention. Our transcript story is deterministic reconstruction from Code's JSONL (DEC-0076), which is good but records what Claude Code chooses to record; injected preambles/system prompts from `run_claude.sh` are not in that stream. A cheap step: have `run_claude.sh` write the composed prompt file's hash + path into the ledger line so the reconstruction can be joined to what the session actually saw. **[E]**
2. **Reversible registrations.** Our machinery grows by adding launchd jobs, hooks, and cron entries whose removal is manual and error-prone (the tripwire retirement of 2026-08-14 left prose contradicting DEC-260130 precisely because there was no unwind). A "how does this get cleanly removed?" line in the Designer checklist (ACI-260011's self-growing checklist) is the Cordis lesson at zero cost. **[E]**

**Boundary note:** dsh has no bearing on the HIPAA wall — it's a local tool with a file sandbox, no PHI safeguards; the POSIX-user wall (ACI-260009) still does that work. Its Web UI is loopback-only, single-user, and would need the same Tailscale-serve treatment as OpenClaw's if ever exposed. **[E]**

---

## 5. How it differs by system

| Dimension | **Claude Code** (Cowork-me's Code surface + our worker lanes) | **Codex** (planned lane, CLD-00065) | **Alfred / OpenClaw** | **dsh** |
|---|---|---|---|---|
| Extension model | Hooks (event → shell command), skills (`SKILL.md`), MCP servers, plugin marketplaces; **loop, model adapter, session store are not swappable** | Plugin marketplace (declarative "folder = plugin", per one reviewer), MCP; **loop/model fixed** | **Already plugin-shaped**: channel plugins (Telegram), provider plugins (Ollama, Google), memory plugin (`memory-core`), TS event hooks, skills registry, subagents, sandbox — closest cousin to dsh **[V — local config keys, values-blind]** | Everything, incl. loop, adapter, log, UI |
| Model | Anthropic only | OpenAI only | Multi-provider (local Ollama primary per DEC-0086; Vertex Gemini lane) | Any (Anthropic/OpenAI/DeepSeek/gateway; local inferred) |
| Headless | `claude -p` (what our lanes use) | `codex exec` (not yet wired here) | Gateway daemon + cron; not a one-shot CLI | `--profile headless`, Python/TS SDK, ACP |
| Session record | JSONL under `~/.claude/projects/` (we rebuild transcripts from it) | Own store | Session JSONL + hooks-written daily logs | Append-only typed event log, fork/replay/search, "model-visible means logged" invariant |
| Chat channels | None (terminal/app) | None | Telegram now, web-chat-over-Tailscale planned (ACI-260009) | **None** |
| Sandbox | Permission modes + tool allow/deny (our screen adds deny-classes) | OS sandbox | OpenClaw sandbox config | Seatbelt/Landlock/ACL file sandbox + fail-closed approvals |
| Reads our files | `CLAUDE.md`, `.claude/skills` | `AGENTS.md` | `AGENTS.md`/workspace bootstrap | `AGENTS.md`/`CLAUDE.md`, `SKILL.md`, Claude-Code hooks bridge, MCP — **would read our estate skills nearly unchanged [E]** |
| Can drive the others | Agent tool (Claude subagents) | — | Coding-agent skill | Spawns **Claude Code** and **Codex** as subagent providers |

Reading across the row: **Claude Code and Codex are products with extension points; OpenClaw and dsh are frameworks made of extension points.** Alfred is already living the "everything is a plugin" model at the channel/provider/memory layer — what dsh adds over OpenClaw is the swappable *loop* and the logged-invariant session stream, and what OpenClaw has that dsh lacks entirely is the messaging-channel layer Alfred exists to run on. So dsh is **least relevant to Alfred** (no channels, no HIPAA posture, and Alfred's runtime question is the POSIX-user daemon, not the harness), **moderately relevant to the Codex lane** (as a "worker-X" pattern generaliser: if we build a substrate-neutral lane for Codex, dsh becomes a third substrate almost for free), and **most relevant to Claude Code lanes** as an observability benchmark. **[E]**

---

## 6. Recommendation **[E]**

1. **Do not adopt now.** Developer preview, breaking changes promised, format-0 logs, no upstream PR path. Re-look at the first non-rc tag or ~90 days, whichever first.
2. **Take the two harness-independent ideas** (§4C): log-what-the-model-saw hash in the ledger; "clean unwind" question on the Designer checklist. Both are small; both would have caught real incidents on the record.
3. **When the Codex lane is designed (CLD-00065), design it substrate-neutral** — `run_<substrate>.sh` + a screen allowlist keyed on substrate+model — so worker-dsh is a config row later, not a build.
4. **Optional bounded trial** on a Cowork-side scratch tree only (no Alfred files, no estate writes): `pip install deepseek-harness-sdk`, one headless job against an Anthropic key, inspect the session JSONL — to answer the one thing the docs can't: how the log looks in practice and whether Ollama works. Half a day; deposit findings.

---

## 7. What this rests on / still unverified

- **Rests on:** DeepSeek's own repo docs at the 2026-08-13 push (README, architecture, subsystem docs, package READMEs), the GitHub API, npm/PyPI registries, the Cordis paper repo, and five independent write-ups (The Register, The New Stack, Justin3go, HN, CodePick; a sixth, XenoSpectrum, was read by the researcher but blocks automated re-check and is not cited). Local-fit claims rest on `The_Estate/designs/machinery/executor-lanes.md`, `estate-map.md`, `_lib/run_claude.sh`, and a values-blind read of `~/.claude/settings.json`, `~/.codex/config.toml`, and `~/.openclaw/openclaw.json` key structure.
- **Unverified:** VentureBeat piece (blocked, not read); Ollama end-to-end (inferred from pi-ai's provider list); token-usage multiples and "22 contributors / 500K lines" (single reviewer, preliminary); the claimed CLAUDE.md+AGENTS.md double-injection bug (current README says byte-identical siblings collapse to one — may be fixed or was wrong); Cordis repo itself not fetched (paper + vendored primer used); the `deepseek-harness.github.io` developer docs not fetched (repo docs used).
- **Not a source:** star counts and ecosystem size are volatile and the `dsh-plugin` topic is polluted by unrelated repos.

## 8. Deposits and flags

**Library** (`~/Documents/The_Library/deepseek-harness/`, 16 items, each with `.meta.yaml`, hashes verified, secrets/email screen clean): dsh README, architecture doc, Cordis primer, CLI readme, providers guide, Python SDK guide, MCP-client readme, hooks-claude-code readme, headless-bundle readme, CONTRIBUTING, landing page, Cordis paper PDF, The Register, The New Stack, Justin3go review, HN thread (usernames stripped).

**Wiki — flag only (DEC-0034):**
- `[WIKI-CANDIDATE?]` tools/deepseek-harness — what it is, install, maturity, provider support.
- `[WIKI-CANDIDATE?]` concepts/cordis-spatiotemporal-composability — revertible effects, reactive coeffects, HMR.
- `[WIKI-CANDIDATE?]` extend concepts/agent-harness-landscape (or persistent-ai-teammates) with the §5 comparison row.
- `[WIKI-CANDIDATE?]` concepts/append-only-session-logs — "model-visible means logged" as an observability pattern.
