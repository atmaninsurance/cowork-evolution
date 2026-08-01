# Launch prompt — conductor follow-up design pass (paste into a running Claude Code session)

*Authored 2026-07-31 by Cowork chat `remote_77a9151d`. Kept here so the launch instruction is on the record alongside the brief it points at.*

---

New task, unrelated to whatever you were doing — please set that aside.

You are running a **narrow follow-up design pass** for the Agent Workflow orchestration workstream (CLD-00109). A full design pass already ran today and was adjudicated; this pass revises two named parts of it and answers four questions that arrived afterward.

**Read this first, and treat it as your governing brief:**

`~/Documents/Projects/cowork-evolution/Prompts/conductor-design-followup-20260731.md`

It carries the mode, the full required-reading list, the questions, the deliverable path, and a verification bar you must self-check against before finishing. Everything below is orientation, not a substitute for reading it.

## Orientation

**What already exists.** The main pass produced `~/Documents/Projects/cowork-evolution/Design/conductor-orchestration-design-20260731.md` (~13k words). It is **decided, not a draft** — you are not rewriting it. You revise only its Part 7 (staged rollout) stages 1–2 and its Part 8 (the venture pipeline), and you answer what it could not: it completed at 14:44 PT, before four things landed.

**Your evidence is unusually fresh, and that is the main hazard.** Three decisions were captured today, after that document was written: **DEC-0101**, **DEC-0102**, **DEC-0103**, all in `~/Claude/memory/decisions/COWORK-DECISIONS-2026.md` (newest first, at the top). Read all three before anything else. **Where any older source disagrees with them — including the main design document, the two consultation transcripts, `librarian/topics.md`, and CLD-00089's earlier Progress entries — the newest DEC wins.** Several sources written earlier today describe The_Librarian's P3 as released with a build pending; that is stale, and DEC-0101 plus DEC-0102 say what replaced it.

**The four things that changed:**

1. The weekly digest the main design leaned on does not exist and its build was withdrawn (DEC-0101). It is now built as part of stage 1.
2. Promotion is the machinery's act, not David's — he reviews selections rather than approving them (DEC-0102 ruling 1), and the review surface is a session start rather than a push channel (ruling 2).
3. The compliance flag becomes a mechanical client-data disqualifier, and the venture lane gains an aggregate book-of-business profile compiled by Alfred (DEC-0103 items 1–2).
4. David asked for a scoring feedback loop between the Analyst and the Scout, and asked directly where the Scout's memory should live (brief, question 10).

**Also read** `~/Claude/memory/action-items/CLD-00109-260731-Open.md` in full, including its Progress log — the last three entries are today's and they carry context the DECs compress.

## Working rules

- **Read-only.** The only file you create is the deliverable. No script edits, no writes into any `inbox/`, no action items, no DECs, no intakes, no `topics.md` edit — it is David-owned and his edit to make (check its state and report what you found; he may not have made it yet).
- **No git.** Do not commit or push. The nightly Stage-5 sweep handles that.
- **Run autonomously to completion. Do not stop to ask.** Anything that belongs to David goes inline as `[DECISION REQUIRED]` with options and your recommendation, and you keep going. Halting on a question is the failure mode.
- **Cite or label.** Every claim about current behaviour cites `file:line`, a DEC id, or a CLD id. Anything you could not verify is labelled and collected in the deliverable's could-not-verify section.
- **Stay inside the brief's reading list.** The repository is large and the budget is real. In particular **do not read the Cowork chat transcripts** — the brief deliberately excludes them; the DECs and CLD-00109 are the authoritative record for everything this pass touches.
- **Do not reopen** stages 3–5 or any Part 1–6 conclusion of the main design. If something you find genuinely contradicts one, say so in a single prominently flagged section rather than redesigning around it.

## Audience

David is not a programmer. Lead with the plain-English shape before the mechanics, define any term of art on first use, prefer concrete examples over abstractions. Mermaid diagrams where a topology is easier seen than read. Do not pad, and do not compress away reasoning he would need in order to disagree with you.

## Deliverable

`~/Documents/Projects/cowork-evolution/Design/conductor-orchestration-design-followup-20260731.md`

An addendum, not a restatement. Self-check against the brief's verification bar before you finish, and fix what fails.
