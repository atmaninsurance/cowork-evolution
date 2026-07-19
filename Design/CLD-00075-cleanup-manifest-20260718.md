# CLD-00075 — Transcript-store cleanup manifest

**Generated:** 2026-07-18 (David-supervised Code session)  
**Store:** `~/Claude/transcripts/code/` — 460 transcripts total  
**Method:** content-first classification, cross-referenced against source project dir (`~/.claude/projects/<encoded-cwd>/<uuid>.jsonl`, depth-3 = the exporter's glob scope) where the JSONL survives the 30-day window, and by transcript content where it has aged out.

## Summary — disposition × class

| Disposition | Class | Count | Tracked | Evidence basis |
|---|---|---:|---:|---|
| **DELETE** | stub-fixture | 176 | 176 | body is literal `stub`; all sourced from tmp/scratch roots |
| **DELETE** | probe (sampler PONG) | 152 | 152 | single-turn ≤1.1KB, `PONG (SAMPLER-…)`; sampler stood down |
| **DELETE** | probe (liveness) | 6 | 6 | single-turn ≤1.3KB canned health probes (see list) |
| **KEEP** | queue-machinery (DEC-0078) | 55 | — | Agent_Workflow worker/reviewer sessions — sanctioned |
| **KEEP** | real-chat | 36 | — | sourced from real workspace roots |
| **KEEP** | uncertain-keep | 35 | — | JSONL aged out; substantial multi-turn content — kept on the safe side |
| | **TOTAL** | **460** | | |

**Deletion list: 334 files, all git-tracked → all removed via `git rm` (no untracked in the delete set). Keep: 126 files.**

## ⚠️ Finding A — regeneration risk (4 files need source-JSONL removal to make deletion stick)

The exporter recreates any transcript whose source JSONL is still discoverable (`process_session`: no file → create). Cross-checking the delete set against live JSONLs:

- **177 files** — live JSONL in a **deny-listed** tmp/scratch root → once the Task-2 deny-list lands, the exporter skips them, deletion sticks.
- **153 files** — JSONL **aged out** (152 SAMPLER PONG + 1 `ALIVE`) → nothing to regenerate from, deletion sticks.
- **4 files** — live JSONL in a **non-deny-listed real root** → **tonight's Stage-1 export would recreate them** after `git rm` unless their source JSONLs are also removed:

| Transcript | Probe | Source JSONL (still live) |
|---|---|---|
| `1786df53….md` | `PREFLIGHT_OK_7d3` | `~/.claude/projects/-Users-alfredassistant-Documents-The-Wiki/1786df53….jsonl` |
| `5698d158….md` | `TRUSTOK` | `~/.claude/projects/-Users-alfredassistant-Claude-Scheduled-nightly/5698d158….jsonl` |
| `a1a4c636….md` | `TRUSTOK` | `~/.claude/projects/-Users-alfredassistant-Claude-Scheduled-nightly/a1a4c636….jsonl` |
| `ebd4088d….md` | `PROBEOK` | `~/.claude/projects/-/ebd4088d….jsonl` |

These 4 roots are **not** deny-list candidates (real/mixed, or `/` — not ephemeral-by-nature; fails the pattern-addition criterion). Making their deletion stick requires removing the 4 source JSONLs from `~/.claude/projects/` — a new action class not in the prompt's task list (which contemplated only transcript `git rm`/`rm`).

**David's decision (2026-07-18):** remove the 4 JSONLs. Rationale — leaving them means ~3 weeks of nightly regeneration + Stage-5 re-commit of the re-created transcripts + a standing (dedupe-suppressed) leak item about producers already dispositioned: sustained noise in exactly the channels being cleaned. Removal is consistent with the morning principle — content-unambiguous, individually dispositioned, at a human gate. **Framed as a one-time disposition, not a new standing practice**: no rule change follows; these files carry no retention promise (they evaporate ~2026-08-09 regardless). Audit record (captured before deletion):

| Source JSONL | Bytes | Probe content |
|---|---:|---|
| `~/.claude/projects/-Users-alfredassistant-Documents-The-Wiki/1786df53-b782-45b5-9038-7c584eb22ac8.jsonl` | 12841 | `Reply with exactly the token PREFLIGHT_OK_7d3 and nothing else…` |
| `~/.claude/projects/-Users-alfredassistant-Claude-Scheduled-nightly/5698d158-d370-4ec0-84ab-6e7af3567c0e.jsonl` | 14442 | `Reply with exactly TRUSTOK and nothing else.` |
| `~/.claude/projects/-Users-alfredassistant-Claude-Scheduled-nightly/a1a4c636-90de-46c1-a728-2825f7ec4402.jsonl` | 15121 | `Reply with exactly TRUSTOK and nothing else.` |
| `~/.claude/projects/-/ebd4088d-6602-453f-b67d-3fa453ffa3e0.jsonl` | 18904 | `Reply with exactly PROBEOK` |

## ⚠️ Finding B — no standing nightly-chain probe emitter exists to redirect (Task 3 rescoped)

The amendment's premise (probe emitters live in the nightly chain / DEC-0079 preflight-trust / hook test) was investigated exhaustively. Result: **the leaked liveness probes were one-off diagnostics, not standing emitters.**

- `TRUSTOK`×2, `PROBEOK` — added in `822b874` (**2026-07-10** nightly automation stand-up), one-time.
- `PREFLIGHT_OK_7d3`, `HOOK_TEST_OK`, `ALIVE` — **2026-07-14** DEC-0079/CLD-00068 TCC-debugging probes, one-time (per `.claude/plans/dry-run-adaptive-heron.md`: "earlier preflight + dry-run sessions from tonight's own build").
- **No standing script** under `~/Claude/Scheduled/nightly`, the loaded launchd agents, or the Wiki (`_meta/` has only `lint.py`, no `claude`-spawning tooling) emits these tokens on a schedule. The sampler plist is gone (only logs remain); the SAMPLER PONGs will not recur.

**The only standing single-turn `claude -p` probe** is the worker's CLI-version-change TCC preflight (`worker.sh`, prints `PREFLIGHT_OK`) — and it runs with `cwd=~/Documents/Agent_Workflow`, a **DEC-0078 queue root that is deliberately recorded (KEEP)**. It is therefore not a leak; it is sanctioned machinery. Redirecting it would change what the DEC-0078 surface records — out of this item's scope.

**Consequence for Tasks 3–5:**
- **Task 3** reduces to the original fixture-harness redirect (`test_worker_timeout.sh` + any `_meta/`/`_lib/` spawn site). There is no nightly-chain emitter to redirect because none is standing.
- **Tasks 4–5** must **scope the `trivial-single-turn` lint finding to exclude transcripts sourced from DEC-0078 queue roots** (and deny-listed roots), so the sanctioned worker preflight never trips the lint → the leak-to-inbox hook only fires on genuine real-root leaks. Without this, the standing worker preflight would make the hook file an inbox item every CLI-update night — the exact "filing an item about a producer we already know" failure the amendment warns against, just via `PREFLIGHT_OK` instead of `TRUSTOK`.

Removal is from HEAD only (`git rm`); no history rewrite, no force-push. The noise was committed in `498f21a` (2026-07-16 sweep) and `74bff88` (2026-07-17 sweep) — both remain the recovery path.

## Deny-root purity (justification for the Task-2 deny-list patterns)

Every source root matching the proposed deny-list patterns holds **only** delete-class files (0 real/keep sessions) — so deny-listing them cannot drop a real chat. Per David's pattern-addition criterion, this census is the required evidence.

| DELETE | KEEP | Source root |
|---:|---:|---|
| 1 | 0 | `-private-tmp` |
| 44 | 0 | `-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code` |
| 26 | 0 | `-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code` |
| 26 | 0 | `-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code` |
| 26 | 0 | `-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code` |
| 1 | 0 | `-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-HmpepTOXkc-root-code` |
| 1 | 0 | `-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-KBXknSpobk-root-code` |
| 26 | 0 | `-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code` |
| 26 | 0 | `-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code` |

## Noise sourced from REAL / varied roots — file-level disposition (NOT deny-list grounds)

These probes came from roots that also hold (or are) real sessions, or whose JSONL has aged out. Per the pattern-addition criterion they are dispositioned individually; the **producer** (the health/preflight/trust probe emitters) is the thing to redirect, not the root. The 152 SAMPLER PONGs whose JSONL aged out are listed in the bulk table below.

| File | Probe | Source root |
|---|---|---|
| `0b41aa79-2b7b-474e-98c3-40f68de38c4e.md` | Respond with exactly: HOOK_TEST_OK — not | `-private-tmp` |
| `1786df53-b782-45b5-9038-7c584eb22ac8.md` | Reply with exactly the token PREFLIGHT_O | `-Users-alfredassistant-Documents-The-Wiki` |
| `462192a0-eae3-4320-a44e-2283b4565e70.md` | Reply with exactly one word: ALIVE | `(aged-out)` |
| `5698d158-d370-4ec0-84ab-6e7af3567c0e.md` | Reply with exactly TRUSTOK and nothing e | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `a1a4c636-90de-46c1-a728-2825f7ec4402.md` | Reply with exactly TRUSTOK and nothing e | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `ebd4088d-6602-453f-b67d-3fa453ffa3e0.md` | Reply with exactly PROBEOK | `-` |

## KEEP — real chats & sanctioned machinery (spot-check reference)

Load-bearing records confirmed present and retained: `ded3b532` (2.1 MB), `b3947f3e`, `f195ecdf`, `c2297ad9`, `39e396f4`, `99580b8f`, `9c8b915b`, and the full Scheduled-nightly / Agent-Workflow sets.

| File | Class | Turns | Size | Root |
|---|---|---:|---:|---|
| `7e75b05a-6531-43e2-a506-2d39bfe3d78a.md` | queue-machinery | 3 | 136561 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `8664bd58-140e-43bb-b2ec-792a8bd71aee.md` | queue-machinery | 1 | 132193 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `a1da48cd-c4c3-4b79-b03e-f9270d6cf6a7.md` | queue-machinery | 1 | 128984 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `40560074-757e-4c42-b34d-8a3e0c835ec9.md` | queue-machinery | 3 | 112326 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `591ccb1e-663c-4785-ae74-1ddd37d3fa4d.md` | queue-machinery | 1 | 107176 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `04fdae9b-2fb9-4ef0-b90f-03e446a37b67.md` | queue-machinery | 3 | 103418 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `b35f70f8-c142-414f-8a6a-608815e6e75b.md` | queue-machinery | 1 | 101536 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `29ef3826-8a6f-4a76-b6cc-f1ec89569ef9.md` | queue-machinery | 3 | 99508 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `efffba47-4a21-4c4d-8aed-0878b1189934.md` | queue-machinery | 1 | 97284 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `802b3f13-197f-4b58-9710-ff4719180710.md` | queue-machinery | 1 | 95168 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `87a048ad-2597-40ab-9694-7a1d3830104d.md` | queue-machinery | 1 | 94588 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `6b2f7135-6d7d-4fd1-b353-5a02a519bed8.md` | queue-machinery | 1 | 94091 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `17b131b9-c8bd-4439-961a-49a5d5baf2a7.md` | queue-machinery | 1 | 93237 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `020d7c6a-f9c4-4f2d-bb66-3e8d75644daa.md` | queue-machinery | 1 | 92401 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `ca0113db-0207-4307-b381-e3a714cbebff.md` | queue-machinery | 1 | 92220 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `c220ba38-9a53-4a4e-9f72-6752f1f61966.md` | queue-machinery | 2 | 88740 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `d0914c2f-2c74-4cc6-b479-def08a8e1525.md` | queue-machinery | 1 | 86630 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `4d39f841-a957-4fe4-9c4a-09ad2accb1f8.md` | queue-machinery | 3 | 85081 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `92dfe330-71b7-4771-8dcc-b7576c7710b6.md` | queue-machinery | 1 | 82442 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `0dbfde8d-bf65-4f48-81fd-46d0282303ec.md` | queue-machinery | 1 | 80972 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `deaf04b4-b3c1-4ae4-bd60-03bd3486ed41.md` | queue-machinery | 1 | 78980 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `8e1be7ee-ef1a-4f4f-8c65-2bd164435efb.md` | queue-machinery | 1 | 78861 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `b0929655-a8ce-4371-ae8b-b33b7cc7c93c.md` | queue-machinery | 1 | 75448 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `31ad2b73-d50e-4a79-bd40-7f2c41d4e71f.md` | queue-machinery | 1 | 75274 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `25ac6463-0865-493e-b1b4-ae6fb23a2188.md` | queue-machinery | 1 | 73928 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `cb516eb6-16ce-4fb6-990b-da9e02cded21.md` | queue-machinery | 3 | 73731 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `c917d7c8-4be9-430f-af46-570940e1ecaa.md` | queue-machinery | 1 | 70307 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `762f0717-b94e-402d-b7c3-1044d839671b.md` | queue-machinery | 1 | 69821 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `58ccbf00-8215-4693-91a7-969e7f80efcb.md` | queue-machinery | 1 | 69778 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `8b846a83-7ab8-4ebb-8f86-5d03a47754a7.md` | queue-machinery | 1 | 69250 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `00043368-a6df-4f1f-89d7-258fd95fd821.md` | queue-machinery | 1 | 44134 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `630d533e-807e-4667-92e1-2f304ff2dd71.md` | queue-machinery | 1 | 35957 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `1538e742-1784-425c-813e-ddb07a159101.md` | queue-machinery | 1 | 31473 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `9a49e448-91c4-43e6-88b5-99c2880ac614.md` | queue-machinery | 1 | 30627 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `18168869-322c-4a7f-92bb-70102aa51099.md` | queue-machinery | 1 | 30134 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `b9ab107c-06a2-4652-a15d-a3928dbd4f52.md` | queue-machinery | 1 | 29635 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `652e7fe3-8f89-45ac-8cd9-2c4e273723c5.md` | queue-machinery | 1 | 26591 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `b8fa1e40-5e6f-42c5-bb9f-6f7777b4f222.md` | queue-machinery | 1 | 26013 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `8c7846fd-7d69-4535-a062-9598446997d4.md` | queue-machinery | 2 | 25516 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `e70379a3-669e-45d2-8f0f-573525592773.md` | queue-machinery | 1 | 22937 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `cfce3a50-4f26-40d7-9708-acb6d70a1a88.md` | queue-machinery | 1 | 19946 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `3b60aeb8-72d6-4ef8-974f-8eb65eeeb6dc.md` | queue-machinery | 1 | 15787 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `e459c29e-93a8-46ef-83cf-b938d8681bdd.md` | queue-machinery | 1 | 15781 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `65c5acfa-b425-4b3f-989e-9bfdb8f1d2b6.md` | queue-machinery | 1 | 15780 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `42ebe239-b549-4a53-99e8-591bcd5558d2.md` | queue-machinery | 1 | 15771 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `12314fcc-705e-4c19-9f74-6f5c4f35d03d.md` | queue-machinery | 1 | 15768 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `2fb9da1a-369c-40ec-87cb-0bb08ba5ac5c.md` | queue-machinery | 1 | 15762 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `5af0f01f-70d6-4bb3-adaa-b1ca04440bd0.md` | queue-machinery | 1 | 15720 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `d7675443-e609-4485-a7d7-96837e04213e.md` | queue-machinery | 1 | 15720 | `-Users-alfredassistant-Documents-Agent-Workflow` |
| `839c168a-ba5f-43db-a583-b08d4c2fae47.md` | queue-machinery | 1 | 5020 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `c7afa5ee-68e1-43e3-9189-212238585514.md` | queue-machinery | 1 | 4311 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `bbad75e7-4784-4137-839c-9cedc4835c4b.md` | queue-machinery | 1 | 3152 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `ec8da45c-645b-4d43-bb52-858dc557bf0b.md` | queue-machinery | 1 | 2342 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `a50422de-2883-46bf-9fab-2b3edbc2ac44.md` | queue-machinery | 1 | 2032 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `7daeadd0-3731-4347-b898-846a788559b4.md` | queue-machinery | 1 | 1967 | `-Users-alfredassistant-Documents-Agent-Workflow-code` |
| `ded3b532-bedb-4ff8-9762-091eb774b357.md` | real-chat | 36 | 2140282 | `-Users-alfredassistant` |
| `10591a50-1c93-4eb2-ad07-ca63138fdf35.md` | real-chat | 7 | 359999 | `-Users-alfredassistant` |
| `7d360bec-b6d0-4198-b021-a39488a89ec1.md` | real-chat | 12 | 305474 | `-Users-alfredassistant` |
| `b3947f3e-0483-4237-9783-259fe7dce242.md` | real-chat | 32 | 279656 | `-Users-alfredassistant` |
| `99580b8f-01ca-40d2-b680-17c09287722a.md` | real-chat | 7 | 274484 | `-Users-alfredassistant` |
| `f195ecdf-6089-4ad7-b072-a25467a231f3.md` | real-chat | 6 | 268940 | `-Users-alfredassistant` |
| `c2297ad9-396a-4617-aa09-f144e49a3883.md` | real-chat | 17 | 252865 | `-Users-alfredassistant` |
| `39e396f4-49e6-482d-bebf-7c6e2f59a704.md` | real-chat | 10 | 214021 | `-Users-alfredassistant` |
| `822b81a2-6666-43f6-bbcc-428e447702f9.md` | real-chat | 7 | 140144 | `-Users-alfredassistant` |
| `1d0d4a5b-8ae8-4ad8-8306-ac4ae823ae4f.md` | real-chat | 5 | 131227 | `-Users-alfredassistant` |
| `f038b96b-2a25-4d9d-8f38-49fc1ab0f731.md` | real-chat | 1 | 124104 | `-Users-alfredassistant-Documents` |
| `d8621ee6-7124-43d0-bbc5-9824bd452acd.md` | real-chat | 7 | 118223 | `-Users-alfredassistant` |
| `11da2b73-8df4-49c6-b869-bbbfe7559350.md` | real-chat | 8 | 110850 | `-Users-alfredassistant` |
| `f762e8bc-8643-45ea-9da4-7e12e9812694.md` | real-chat | 1 | 100465 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `77435d00-1998-4075-96c0-771b2f381eec.md` | real-chat | 7 | 90415 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `9c8b915b-84e3-4174-83f6-1cdb22a55ae2.md` | real-chat | 8 | 85005 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `4a499e0a-262c-4f85-b79d-7a319cb17dca.md` | real-chat | 6 | 78041 | `-Users-alfredassistant` |
| `2a1aa2e1-4e92-4c7d-afaf-d3af69a93d64.md` | real-chat | 3 | 73734 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `c1193f35-d33e-4714-80b0-d2af3a986f48.md` | real-chat | 9 | 69596 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `be0c828b-4c14-4b77-9c56-ec13600bb03d.md` | real-chat | 3 | 68960 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `8927212b-efd3-4434-9ca4-a45556d47e46.md` | real-chat | 3 | 68434 | `-Users-alfredassistant-Documents-The-Wiki` |
| `9b62b153-817a-4139-a76d-9fffac8ee2a7.md` | real-chat | 4 | 56831 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `895ac9bd-9c12-4267-b6e4-5e32564d46bf.md` | real-chat | 1 | 53252 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `8ed1bfc9-3837-434a-8696-d81733c7cfbc.md` | real-chat | 1 | 51402 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `b8d13ee4-3347-41a9-93ce-ad7e3ba8a17f.md` | real-chat | 7 | 50280 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `69a2c7de-f50c-4539-8989-753f897db985.md` | real-chat | 1 | 47569 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `0363677f-e5c0-456f-bb56-40308ade57e2.md` | real-chat | 1 | 45525 | `-Users-alfredassistant-Documents-The-Wiki` |
| `4eb12c5d-c74e-495a-b97a-233e52b5126e.md` | real-chat | 1 | 43113 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `33b2aaa7-7671-4633-bc0f-9240667f620c.md` | real-chat | 3 | 40155 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `1e79da33-53d8-4468-810d-63a2616b89c5.md` | real-chat | 2 | 37123 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `7be3a8a7-ba91-4f6c-85ba-a962e9e80d64.md` | real-chat | 1 | 35702 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `a9e4d9a5-9734-4ce6-ad93-16e6994c3c55.md` | real-chat | 2 | 33445 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `77a38663-8b61-49bf-bf41-403f47009fbc.md` | real-chat | 2 | 31153 | `-Users-alfredassistant-Claude` |
| `e516042a-1831-4017-ac4e-6efd9bcb4cf0.md` | real-chat | 1 | 15858 | `-Users-alfredassistant-Claude` |
| `0011c34b-201b-450c-aa03-6b5aad4e653c.md` | real-chat | 1 | 9816 | `-Users-alfredassistant` |
| `d8f49cd5-3a4a-49a8-8d14-220f3ac6f936.md` | real-chat | 1 | 4917 | `-Users-alfredassistant-Claude-Scheduled-nightly` |
| `212175b0-6070-4ca3-9927-e92476a83b3b.md` | uncertain-keep | 15 | 234113 | `(aged-out)` |
| `c2e3be23-99aa-483b-85c0-87402d4fdccc.md` | uncertain-keep | 32 | 103836 | `(aged-out)` |
| `7829e055-90b4-4bf9-b217-45bc25d03596.md` | uncertain-keep | 64 | 81781 | `(aged-out)` |
| `29002fa0-4405-4a8e-bc82-acc859f4cfb4.md` | uncertain-keep | 59 | 62000 | `(aged-out)` |
| `92c93d3d-d02f-4e0a-b962-20dee5d259c3.md` | uncertain-keep | 53 | 61572 | `(aged-out)` |
| `80725409-1826-47cf-ae3a-e1522812b1dd.md` | uncertain-keep | 42 | 57736 | `(aged-out)` |
| `cb967ff7-6292-48ed-9931-2146c1d2cfb5.md` | uncertain-keep | 1 | 56783 | `(aged-out)` |
| `9d099424-e8a5-4d09-bc95-47c8a4a9a7f4.md` | uncertain-keep | 35 | 53798 | `(aged-out)` |
| `87bea6ed-9994-4be6-a57a-b1ed8e58bfb2.md` | uncertain-keep | 1 | 53284 | `(aged-out)` |
| `d94d6990-089a-4c78-a54e-d5bdacfd2a49.md` | uncertain-keep | 24 | 38867 | `(aged-out)` |
| `46e9072a-863e-4778-885d-9220f3420123.md` | uncertain-keep | 1 | 29304 | `(aged-out)` |
| `55a91b08-aa0b-44f6-bb2a-1ce48e4256c6.md` | uncertain-keep | 9 | 28222 | `(aged-out)` |
| `2d559c7a-13d2-4936-9d53-07e080fbd417.md` | uncertain-keep | 23 | 22056 | `(aged-out)` |
| `ef31d7e1-6a03-4e97-9f93-400847ea7f64.md` | uncertain-keep | 1 | 20902 | `(aged-out)` |
| `fa5b3b80-3013-4915-9729-b67b91681080.md` | uncertain-keep | 6 | 18421 | `(aged-out)` |
| `b6bd1761-9915-47cf-9c3c-1d09ce20ba92.md` | uncertain-keep | 9 | 17325 | `(aged-out)` |
| `a008ee12-0b3a-4ced-a841-fcc32e519dcb.md` | uncertain-keep | 1 | 16383 | `(aged-out)` |
| `8152b1d6-8c0f-4be6-b189-43906862e9e4.md` | uncertain-keep | 2 | 15146 | `(aged-out)` |
| `b7acac7a-44de-4998-88be-e5e66bebbe3e.md` | uncertain-keep | 6 | 15065 | `(aged-out)` |
| `f7eb7ef1-eba3-4e14-8879-36185e72e369.md` | uncertain-keep | 1 | 14074 | `(aged-out)` |
| `bca519fc-f8cb-42a1-872d-bd862b87b7e5.md` | uncertain-keep | 12 | 13872 | `(aged-out)` |
| `70f8e4a5-2f25-4875-9831-3249a91ee70f.md` | uncertain-keep | 2 | 12251 | `(aged-out)` |
| `47f527d1-10ed-454d-b4f0-369a658f0d8c.md` | uncertain-keep | 8 | 10247 | `(aged-out)` |
| `f380a1c4-5179-4eb0-af67-5be8ec989b9b.md` | uncertain-keep | 4 | 9386 | `(aged-out)` |
| `4586b77e-c830-46ee-9f29-3a377b54ab64.md` | uncertain-keep | 1 | 9072 | `(aged-out)` |
| `7b1976cd-ef67-4db0-a1aa-804d0d76cbe4.md` | uncertain-keep | 1 | 7958 | `(aged-out)` |
| `f8403729-ecef-4a14-b7de-53689b4ef05d.md` | uncertain-keep | 1 | 6820 | `(aged-out)` |
| `86938178-2a20-47b0-b85e-812080c32571.md` | uncertain-keep | 1 | 5393 | `(aged-out)` |
| `0c962488-9a01-4c4c-9ffc-8ad97dd3bbd6.md` | uncertain-keep | 1 | 4940 | `(aged-out)` |
| `648235f4-5ba4-46f4-92be-c7f2f6b1d3d6.md` | uncertain-keep | 1 | 4648 | `(aged-out)` |
| `f997a547-7e7a-4810-bd16-86259d910d43.md` | uncertain-keep | 1 | 4613 | `(aged-out)` |
| `2c70ca81-b95f-444e-ada5-146d7b96c8ac.md` | uncertain-keep | 3 | 4546 | `(aged-out)` |
| `499b7f9a-a33c-4576-b3c1-87c13e5f46db.md` | uncertain-keep | 2 | 4423 | `(aged-out)` |
| `b50ff824-2207-4eb4-a01f-8cc2b2fb3899.md` | uncertain-keep | 2 | 3501 | `(aged-out)` |
| `4ff39970-68f1-468d-a687-e12c7c66398b.md` | uncertain-keep | 2 | 3476 | `(aged-out)` |

## Full deletion list (334)

<details><summary>176 stub-fixtures</summary>

- `stub-1784235847-29596.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235912-18577.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235913-22037.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235913-26696.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235913-9259.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235914-17378.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235914-26832.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235979-24841.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235980-2860.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235980-31568.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784235981-8679.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236046-18133.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236046-28495.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236111-4272.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236112-31956.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236177-14460.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236177-5007.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236242-2532.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236322-32710.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236387-27085.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236388-17767.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236388-2436.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236388-30545.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236389-2572.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236389-25886.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236454-32498.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236455-10518.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236455-6458.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236456-16337.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236521-175.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236521-22581.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236586-25500.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236587-20416.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236652-18850.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236652-9397.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784236717-7831.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237506-26894.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237506-6904.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237507-1337.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237507-16242.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237507-21326.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237507-3463.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237508-15217.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237508-2439.md`  (-private-tmp-claude-502--Users-alfredassistant-99580b8f-01ca-40d2-b680-17c09287722a-scratchpad-awtest-code)
- `stub-1784237591-14019.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237656-12028.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237656-20747.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237657-19548.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237657-28267.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237657-8278.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237658-17132.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237658-27494.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237658-29910.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237658-7505.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237659-21385.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237659-26470.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237659-6480.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237659-8607.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237660-3948.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237725-11584.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237726-1473.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237726-27282.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237726-5533.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237791-19839.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237792-14272.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237857-24634.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237857-2711.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237922-14407.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237923-24769.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784237988-9149.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-yUDU3NXJoH-root-code)
- `stub-1784242488-10314.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-KBXknSpobk-root-code)
- `stub-1784242623-6893.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242688-23190.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242689-31310.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242690-14781.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242690-27560.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242690-6062.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242691-14008.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242691-16424.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242691-26787.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242691-3646.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242692-12984.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242692-25762.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242692-27889.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242692-7899.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242693-23230.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242758-11669.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242758-15729.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242758-5850.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242759-21548.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242824-6295.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242825-728.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242890-16793.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242890-5948.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242955-32182.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784242956-9776.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784243021-26073.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-BbUaTNnowO-root-code)
- `stub-1784243027-10027.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243092-1734.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243093-22033.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243093-9254.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243093-9853.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243094-10898.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243094-17374.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243094-30887.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243095-20235.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243095-25320.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243095-5330.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243095-7457.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243096-17703.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243096-19211.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243096-6432.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243162-10202.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243162-323.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243162-6142.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243163-16021.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243228-2102.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243228-24508.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243293-653.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243294-28336.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243359-20043.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243360-30405.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784243425-29864.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-TGiYPeP3yQ-root-code)
- `stub-1784300441-31945.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-HmpepTOXkc-root-code)
- `stub-1784302393-11862.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302458-21257.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302458-29976.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302459-13757.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302459-22475.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302459-2486.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302460-29087.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302460-9098.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302461-18435.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302461-23520.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302461-3530.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302461-5657.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302462-17411.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302462-4632.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302462-882.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302527-341.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302528-12037.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302528-18765.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302528-7977.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302594-1385.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302594-29494.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302659-28953.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302660-23869.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302725-20486.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302725-9215.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784302790-14435.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-0Vr81QMqKx-root-code)
- `stub-1784329231-20084.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329296-18635.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329296-9916.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329297-11134.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329297-23912.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329297-2415.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329298-17746.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329298-30524.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329299-12178.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329299-24957.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329299-27083.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329299-7094.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329300-22308.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329300-26059.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329300-6069.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329365-8563.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329366-16200.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329366-20259.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329367-11057.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329432-12333.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329432-8583.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329498-10768.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329498-21613.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329563-20163.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329564-15504.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)
- `stub-1784329629-1759.md`  (-var-folders-kx-z2gq6vbx305525t5sysv2drw0000gp-T-tmp-FMEE3QhrQ8-root-code)

</details>

<details><summary>158 probes (152 SAMPLER PONG + 6 liveness)</summary>

- `014838ab-9aac-4693-a86f-3017d386f341.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `03aa1bd3-6f24-42b7-8471-ff6ae7ac9755.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `0404ef1e-6041-4418-8257-31c12798d8c3.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `04ad86dc-fa5c-4e57-b630-bdeae0149c93.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `04fa60e6-36df-4301-88ef-191647ab8470.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `06814ad4-312a-4145-93db-3bf11bbaf987.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `0824df53-ed1f-4160-af98-cb6ffcd4e122.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `0917223d-28b2-495c-9b99-e6288120f25c.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `0b41aa79-2b7b-474e-98c3-40f68de38c4e.md`  (liveness: «Respond with exactly: HOOK_TEST_OK — not»)
- `0b5fef3b-03e2-4fe8-88df-535307358779.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `0bb5386f-03a3-4455-a55a-3a59f9338fa0.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `0cb8160a-fceb-4ab3-b74b-d06a88543aee.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `0cb93d09-8962-4eee-8fcd-862e6c502151.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `0fe9381b-b30a-44ea-b087-64ac42800526.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `11f37ca4-506d-4c5e-b457-6c37081165d5.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `14c507fc-e70d-42ea-8e19-424eb88bb2e1.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `16c9b05a-8f9e-4907-a12b-48234ef20cff.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `1786df53-b782-45b5-9038-7c584eb22ac8.md`  (liveness: «Reply with exactly the token PREFLIGHT_O»)
- `1954242a-f402-4562-88ac-79bcb13e7c0a.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `198b67f2-ab62-4149-baa6-0b4150bb4de7.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `1bb62435-018e-4bba-a8f6-53723774cedc.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `1f59e698-655a-4216-bde9-5677bec2765c.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `22956c69-0da8-4e21-8be2-00dda31efe34.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `23628fef-31b7-4258-b4e9-25212b0d62c8.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `245c41ed-b4fb-4937-9e7f-d973e8a34a12.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `24858b66-2b20-423f-bd6d-1432fe365085.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `29bef825-4557-4c6f-8862-4cce5a97ad23.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `2a37de92-539f-4bdd-8d98-7a3fc24cd560.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `2c907e72-090c-40ba-83b1-ce88af940178.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `2e89f475-58ba-4060-a50b-2ed5c1d2a675.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `2f9e4189-3fb3-4d85-ae2f-76ba2c1434a3.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `320dd2a6-4e27-4d73-b20b-e3a302625cec.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `33d807d3-08aa-4989-9bc6-94493b839c99.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `3656fc4f-bbad-45ae-b11e-1f9f05bd35a8.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `370f0b43-3104-49b7-a63e-3d805bd11381.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `373485ca-a56d-400d-a328-3e88e020b03b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `380ab198-9f28-431e-afd4-5a0d6a04ace0.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `3b3feea7-0df0-4441-af8b-8d79ca55aae8.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `3d99c578-a7d7-4736-8bad-7574b2ea01da.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `3db6a296-cdfe-4fb0-b4e4-359b64d0b510.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `3ecfc373-6f5e-4c17-a80c-a76b7df9544f.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `40dc7d15-6f8e-41b0-abf5-29533abdfa1d.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `4107be69-a484-4d39-8180-4965365a2b1f.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `42157560-752e-44d3-a96f-0ca5369d13de.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `44e551a7-8050-488f-a802-7fbcbb8c2858.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `459db080-69fd-42e6-9365-06880eaa797a.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `45b9fd05-bfd2-4df2-920b-924a27fe1983.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `462192a0-eae3-4320-a44e-2283b4565e70.md`  (liveness: «Reply with exactly one word: ALIVE»)
- `4688b640-39e3-4ac1-beaf-7ef6ca2ddd78.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `4b9da76a-dbfd-4314-949c-35e1b2efb618.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `4bc0cbec-4484-4d8f-929a-e1eb71de365a.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `4d281a97-3ff5-4896-9e34-7ca0f906da3b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `4da571e1-5a19-4a0c-8420-c2879b7784a8.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `50d5c72c-2d5b-4f8f-b41f-fd31f569fd91.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `52c51a81-5c70-47e2-a0c1-9e83ad7c81c7.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `551117e1-796a-428f-95f9-e947e1c36738.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `5698d158-d370-4ec0-84ab-6e7af3567c0e.md`  (liveness: «Reply with exactly TRUSTOK and nothing e»)
- `583a14b6-df38-4c20-b2b1-9d7ad333cd8c.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `5ac1a5a6-a4c3-4cf5-bdab-8c2c7ba581dd.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `5ca65b0f-44de-4730-95d3-2d8693e04347.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `5dba3fbb-501c-4b09-a214-0df0f6c726cc.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `5dbea4f4-4642-43c7-bf52-66f42e5c11cd.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `5eba3750-41cf-49ef-a0d5-3b940b2951aa.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `5ed8e956-2d65-411b-a15d-2ff7bfa502eb.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `5f6e9d5e-0e94-4069-b2ca-d473996c7366.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `62dd5a54-3487-486a-b1a5-2a86931070d1.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `63bc1a9b-a09e-46ba-96b7-bb833ba29614.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `64435340-89ab-4401-b73f-8184e7ad573c.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `66a072ee-5b65-46ce-af08-705535198503.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `68190c4e-4af5-4cbc-9d25-82e5e423dfb6.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `6a421d13-fe1f-42f5-a1a9-36f2974b43e2.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `6a6d1479-b1a2-4e50-97c8-5efb74666057.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `6ace2071-6c79-4bf5-b626-b85017c97a35.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `70b7e275-42c0-41b4-9840-9b77fdd73196.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `71e5f050-58be-4c93-9b87-61bb520ead2c.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `747d27f2-a7a3-4dfc-b767-a5635d6fae00.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `7759ad9f-7760-494e-b813-1d601e2a0294.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `78035d37-d789-4730-988d-58078fa1565b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `7ad6b32a-0cd1-44de-9a67-bb6be63ff01e.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `7b31d1a6-4c02-4de5-bafd-d35a0f648410.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `7b72cf6c-db94-45e4-ad9e-93e6a3a92d7b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `7e76aea2-5ac9-4f0c-9ece-38bed8ab6846.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `8393a041-dab0-4129-be48-53abce756609.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `897c75da-ad4e-4c04-bcd1-23705748b3da.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `89e3d5cc-f822-4d84-b515-c292d1c75702.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `8b901705-5aa3-49d8-85d2-6ba2fc425545.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `8c2075f0-f14e-4cd3-af09-cacf51031e84.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `8d7d31f6-80db-4d28-b930-90b33c26b9f7.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `8dd5a906-e0ac-4f20-84ff-57ac1808285b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `91bfe80d-cbec-4230-a578-65b70146031c.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `92cb18a4-19f9-4d0a-b18f-dc3dc7709834.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `93f181a1-a835-4c08-8da3-3a42f9505ec8.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `94fa39fb-0fb0-4949-af45-1f732dbb1b2f.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `967c13da-2d50-4bb1-a90a-1728010d5645.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `9a75395d-a960-4a0a-899d-9f5e0d471720.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `9abe57bd-71c8-4245-be08-89581d3350fa.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `9c4516d2-b616-4500-9b52-04e5850322d0.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `9d00ef13-777c-4a90-aca0-c9c8a4d6842b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `9fb5c68d-9aec-4233-b519-35561ec1aa00.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a0a1a48c-0054-4488-b10f-fd90c0034a31.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a0e0a994-67e5-4289-92db-b90e8bd76e55.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a1654924-0e34-436b-9e8c-de08a0f01271.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a1a4c636-90de-46c1-a728-2825f7ec4402.md`  (liveness: «Reply with exactly TRUSTOK and nothing e»)
- `a1f6c8cf-5fd4-4476-8517-70be22a2d73d.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a2d4e095-7a8c-41c8-9822-e06358cffc09.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a63ea6d5-a37d-4412-aefd-b8e032fce732.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a67d9e30-5cc9-4bd7-94ff-b0093b8cd944.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a6867597-4b89-4e6f-a923-d88ca6ab5339.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `a9b16299-dd56-4ef4-919c-62659c9394fd.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `ac9c8df1-5cb8-4339-a8d8-e19b01d3e095.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `af1c79c7-b809-4c3a-96ec-6bb30d4783ae.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `af8a4369-12b3-4017-a7dc-64c0b2b3d5aa.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `b033a8fa-217a-4737-b5dc-dd11b5e80d45.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `b3a6854c-ed99-4c0d-bf87-f9721b36fdbc.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `b424b18a-3a57-4a94-afd2-c1c37cf783e1.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `b6d888fa-5099-4ba8-b19a-6a9187c92cbd.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `b7787f25-7512-4cbd-9e40-9ff803c2e32c.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `b89b916c-7397-4aa6-93eb-dbd3db331566.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `b8f3c4bc-f591-40a6-8ca8-6d662781d50b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `ba6c3fb6-75c9-49b6-8e6d-0304b92ccdc0.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `bdd57b01-4310-44a7-a20d-e3bb0708e3c2.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `bf4c81cd-8616-497b-918d-36c36495b9f4.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `c152d277-dedb-4496-9f0b-0897106794b0.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `c1d43391-5c7d-4128-b4c9-d3d2a4cdedca.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `c603a138-a948-441c-93aa-18e509656afa.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `c70791cc-f4ec-4351-bfc7-66f7fe756075.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `c80a7644-b012-46f5-b778-d7b57804c81d.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `cdec4e80-ad6b-4640-bfd9-8d79bf72be74.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `cf38e7cc-dffb-4aff-b2a6-19728562b2c0.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `d0c7a57f-b4e4-454b-a24e-89f7d2313c65.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `d32f1cf6-3260-4d80-a23d-ae71845382a3.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `d4767232-38ee-4dcf-ac02-73fb9314aa09.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `d586b599-a351-4118-a9c6-2e4e25016b5b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `d7c50f4c-a37d-446a-b8c2-a91e7e9f5705.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `d933b39c-21bb-441c-a308-2e08bb0f6979.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `d9ea1c7f-8de1-4ac3-9934-23a8a35d788d.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `dce409c0-6267-4f91-ba04-b31ca738a2d3.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `e1fa1edb-8788-4168-bdf2-b0c7d3368482.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `e2c5a386-3a34-4b35-80d0-1ccd5502987d.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `e43f4ae4-de25-4cfd-a18e-4f5d65c69789.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `e636c5f1-16bf-4ba2-8c3b-271e2d3f53f8.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `e6a7dd32-538f-4fc2-a7fa-181a40116710.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `e6be8be8-01f8-4a7c-87d5-e09a48aa097d.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `eb24e100-19df-42ef-9d18-92ca5ea93679.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `ebd4088d-6602-453f-b67d-3fa453ffa3e0.md`  (liveness: «Reply with exactly PROBEOK»)
- `f07b7de9-2744-44ac-b48a-2986e97f7e53.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `f10ee914-83dc-4589-989e-152bcba0c23f.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `f31a739a-ac66-4d03-86cb-f68a64a3dcf2.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `f399fd24-6be5-47e4-886b-6ccecdbeba6a.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `f60081ba-bbb9-4a7f-ae97-436dee39f84c.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `f6a3216f-3a5d-4623-a2e6-0dd0285dd4fe.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `f775ce3a-dbe1-4062-924f-6e3d61223955.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `f98acfda-3303-4819-837e-9ad191aba13b.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `fb2fb25c-2aa4-4eb8-acd7-9865f5155433.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `fb9bb51c-579b-48ff-a3a2-424a090ca179.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `fca36c8d-1107-4c71-8278-8f5a595b0c4a.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `ff5abe3f-43db-480a-b6db-48ab61e56dd2.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)
- `ffd0c945-8c19-418d-a006-99734ff9fd78.md`  (sampler: «Reply with exactly one word: PONG (SAMPL»)

</details>


## Execution confirmation (2026-07-18)

- **Staged:** `git rm` of all 334 files above (exact match to the deletion list; `git diff --cached --diff-filter=D` = 334, nothing else staged). Left staged for tonight's Stage-5 reviewed sweep (a `[SWEEP-NOTE]` in `run-ledger.md` tells the anomaly gate this mass deletion is intentional). Not committed in-session.
- **Removed (one-time JSONL disposition):** the 4 source JSONLs in the Finding-A table — so the deletions stick and do not regenerate tonight.
- **Post-cleanup state:** `transcripts/code/` 460 → 126 files; exporter dry-run `skipped_denylisted=177`, only `create` = the live supervised session (a real chat); lint `trivial_single_turn_count` = 0; worker test suite 31/31 green with **zero** new JSONLs in `~/.claude/projects/`. Load-bearing chats confirmed present.
- **Recovery:** every removed transcript remains at prior commits `498f21a` (2026-07-16) / `74bff88` (2026-07-17). No history rewrite.
