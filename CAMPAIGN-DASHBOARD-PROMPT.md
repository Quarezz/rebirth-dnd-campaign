# Campaign Dashboard Update Prompt

Use this prompt after an Obsidian sync when you want to refresh the Quartz homepage and campaign dashboard. It is designed to make the model gather evidence first, judge its own draft, iterate once if needed, and only then edit the site files.

```text
You are updating a Ukrainian D&D campaign Quartz vault after an Obsidian sync.

Primary goal:
Update the Quartz homepage and campaign dashboard so the published vault immediately gives the DM and players a factual, scan-friendly view of:
1. The latest meaningful session recap.
2. The current campaign state.
3. Active priorities, open quests, timers, pressure, unresolved questions, and plausible next routes.

Files you may edit:
- `content/index.md`
- `content/Панель_кампанії.md`

Files you must not edit:
- Anything under `content/Notes/`
- Source quest, character, location, chronology, or sync log files unless the user explicitly asks.

Hard rules:
- Treat `content/Notes/` as the source of truth for session events.
- Use existing quest, character, location, and chronology pages only as supporting context.
- Do not invent facts, motivations, dates, timers, locations, NPC statuses, or quest outcomes.
- If evidence conflicts, report the conflict and use the session notes as higher priority unless a later campaign page clearly supersedes them.
- Keep all user-facing vault content in Ukrainian.
- Preserve existing Quartz/Obsidian wikilink style, including aliases such as `[[Notes/Сесія 60|Сесія 60]]`.
- Preserve YAML frontmatter in edited files.
- Keep edits focused on the dashboard/homepage refresh. Do not reformat unrelated content.

Evidence workflow:
1. Read `.sync-log.txt`. If it is missing, use `git status --short` and the newest files under `content/Notes/` as fallback evidence, and mention the fallback in the final report.
2. Identify newly imported or changed session notes from `.sync-log.txt`.
3. Identify the latest session note with meaningful campaign events.
   - Sort session files numerically by session number, not lexicographically.
   - A note with only a date, LP, metadata, empty headings, or bookkeeping is not a meaningful session recap source.
   - If the newest session is not meaningful, explicitly state this in both edited vault content and the final report, then recap the latest previous meaningful session.
4. Read the current versions of:
   - `content/index.md`
   - `content/Панель_кампанії.md` if it exists
   - `content/Квести/Всі_квести.md`
   - `content/Хронологія_подій.md`
5. Read active quest pages and any newly changed character/location/quest pages referenced by `.sync-log.txt`. Prioritize these known active quest pages when present:
   - `content/Квести/Розслідування_Тиші_в_Есборзі.md`
   - `content/Квести/Порятунок_Опал_Дескард.md`
   - `content/Квести/Прокляття_Івена.md`
   - `content/Квести/Порятунок_Рексара.md`
6. Build a private evidence ledger before editing. For each important claim you plan to include, know which note/page supports it. Do not put the ledger in the vault unless the user asks.

Content contract for `content/index.md`:
- Keep it short enough to scan immediately.
- Include:
  - `Recap останньої повної сесії`
  - `Панель кампанії`
  - `Найважливіше зараз`
  - `Куди можна піти далі`
  - `Основні розділи`
- The recap should be 2-4 concise paragraphs.
- The priorities table should have 3-5 rows and concrete next steps.
- Link to the canonical dashboard as `[[Панель_кампанії]]`.
- Do not duplicate the full dashboard.

Content contract for `content/Панель_кампанії.md`:
- Create it if missing; otherwise update it in place.
- Keep the page title/frontmatter, then include exactly these H2 sections, in this order:
  - `Стан після останнього sync`
  - `Recap останньої повної сесії`
  - `Найважливіше зараз`
  - `Таймери і тиск`
  - `Куди можна піти далі`
  - `Відкриті питання`
  - `Швидкі посилання`
- The dashboard should answer:
  - What is urgent right now?
  - Which quests are active?
  - What are the next concrete actions?
  - What time-sensitive threats exist?
  - Which NPCs and locations matter next?
  - What can the party reasonably do next session?
  - What questions are unresolved?
- Prefer compact tables for priorities and action summaries.
- Use short route/action subsections only when they help decision-making.
- Do not copy full quest-page text; summarize and link.

Style:
- Ukrainian should be natural and practical, not ornate.
- Be concise and DM-useful.
- Prefer specific next actions over vague lore summaries.
- Use wikilinks for important sessions, quests, NPCs, and locations.
- Avoid long lore dumps and speculative explanations.
- Avoid unsupported exact countdowns. If the notes say "about a week", preserve that uncertainty.
- If a newer note is empty or non-meaningful, say so plainly instead of pretending it contains events.

Model-based scoring and result iteration:
1. Draft the intended homepage/dashboard changes mentally or in scratch notes.
2. Score the draft from 1-5 on each criterion:
   - Evidence fidelity: every important claim is supported by notes/pages.
   - Recency handling: latest meaningful session is correctly identified, including empty-note handling.
   - Decision usefulness: priorities, timers, and next actions are clear.
   - Ukrainian readability: concise, natural, and consistent.
   - Link integrity: wikilinks point to existing or intentionally canonical pages.
   - Scope control: only the homepage/dashboard are changed.
3. If any criterion is below 4, revise the draft once before editing.
4. Edit the actual files.
5. Conduct five result-scoring iterations on the edited `content/index.md` and `content/Панель_кампанії.md` before building:
   - Iteration 1, evidence audit: verify the recap, priorities, timers, and NPC/location statuses against session notes and supporting pages.
   - Iteration 2, recency audit: verify the newest meaningful session was selected correctly and empty/bookkeeping-only newer notes are called out.
   - Iteration 3, usefulness audit: verify the output helps choose next-session actions without duplicating quest pages.
   - Iteration 4, language/link/scope audit: verify Ukrainian readability, wikilink style, frontmatter preservation, and that only allowed files changed.
   - Iteration 5, final holistic audit: rescore all criteria after any fixes and decide whether the result is ready to build.
6. Each iteration must produce a score from 1-5 for the relevant criteria and a one-line fix decision.
7. If any iteration gives any criterion below 4, fix the edited files and rerun that iteration before moving on.

Editing workflow:
1. Read first, then edit.
2. Preserve frontmatter.
3. Keep existing useful structure when it already matches the contract.
4. Make the smallest complete change that brings both files up to date.
5. After all five result-scoring iterations pass, run `npx quartz build`.

Final report:
- List files changed.
- State which session was used for the recap.
- State whether the newest session note was meaningful or empty/bookkeeping-only.
- Include the five result-scoring iterations and the final model-based score table.
- State whether `npx quartz build` passed.
- Mention warnings or evidence gaps, especially unsupported timers, conflicts, missing `.sync-log.txt`, or broken/missing pages.
```
