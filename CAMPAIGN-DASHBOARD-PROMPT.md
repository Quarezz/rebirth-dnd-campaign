# Campaign homepage and dashboard

Use this contract after an Obsidian sync. The homepage resumes the story, the dashboard supports decisions, and the indexes help readers find entries. Keep those jobs separate.

## Scope and evidence

During the homepage/dashboard phase, edit only:

- `content/index.md`
- `content/Панель_кампанії.md`

Do not edit `content/Notes/`. Session notes are the source of truth. Use character, quest, location, and chronology pages for context. Preserve frontmatter, file paths, and existing link targets.

Before writing:

1. Read `.sync-log.txt` to identify imported or changed notes. If missing, use `git status --short` and the session files, and mention the fallback in the final report.
2. Find the latest session with campaign events, sorting session numbers numerically. A date, LP total, or empty heading alone does not make a session recap.
3. Read the current homepage, dashboard, and relevant quest, character, and location pages. Check earlier notes when a resource, promise, or status needs context.
4. Track the source of important claims privately. Never invent outcomes, motives, timers, affiliations, geography, or NPC statuses. Attribute conflicting accounts when the difference affects a decision.

An absent update is not a new event. Do not infer that a character recovered, an item was spent, or a quest ended. Carry forward the last known state with a session reference when its age matters.

## Homepage

Keep the homepage to roughly 100–160 Ukrainian words, excluding navigation. Use two sections:

- `Де зупинилися`: one or two short paragraphs describing the scene where play stopped and the immediate stakes. Include the latest meaningful session link and date, then a link to `[[Панель_кампанії|панель кампанії]]`.
- `Вікі кампанії`: links to characters, locations, quests, chronology, and the pre-session checklist.

Do not add a recap of the whole session, priorities table, route list, resource inventory, or open-question list. Those belong on the dashboard or linked entries.

## Dashboard

Open with the session link and date. Link back to the homepage and the pre-session checklist. Aim for roughly 300–450 Ukrainian words.

Group information by the decisions it supports:

- Current problems at the party's location. Use a descriptive heading such as `Справи в гаю`, not a sync status heading. Give each problem one short bullet with a link to details.
- `Ресурси й домовленості`. Use a compact table only for useful values and conditions, such as LP, a consumed item, a temporary protection, a price, or a promise. Preserve mechanical conditions exactly.
- Other active business, under a heading such as `Після гаю`. Link to quests and name the obstacle or available lead. Describe possible actions without deciding what the players will do.
- `Що з'ясувати`. Include only questions that affect an upcoming decision. Usually three to five are enough. Omit this section when there are none.

These are page responsibilities, not fields that must be filled. Rename location-dependent headings as the story moves. Omit empty sections. Put a real deadline beside the problem it affects, and never manufacture a timer section when no countdown exists.

Do not repeat a full recap, duplicate the homepage scene, or copy quest histories. Link to the session and chronology for past events.

## Indexes

Apply these rules during the broader derived-page update phase. They do not expand the dashboard phase's editing scope.

- `content/Персонажі/00_Index.md`: group by established affiliations, places, or relationships. Each person gets a link and one identifying sentence. Keep former identities accessible alongside the current name. Avoid good/evil classifications unless established in canon.
- `content/Локації/Всі_локації.md`: group geographically where supported. Use a separate group for other worlds, historical places, or places whose region is unclear. Each place gets one link and one distinguishing sentence. Never infer geography to make a group look complete.
- `content/Квести/Всі_квести.md`: group active and completed quests by supported status. Keep old unresolved or conflicting entries in `Давні справи` rather than promoting them to current priorities or assuming completion. Each quest gets a link and a short status or premise.
- List each entity once. Reuse the existing page instead of creating another entry under a new session range.
- Keep names, spelling variants, and links searchable. Details removed from an index must remain available in individual entries or source notes.
- Do not recreate miniature dossiers with repeated race, status, type, time, and features fields. Omit unknown fields and obvious classifications.

## Ukrainian prose

Write about the campaign in natural Ukrainian. Use plain sentences, descriptive headings, and wikilinks with readable aliases. Use bold sparingly and avoid decorative emoji.

Keep processing commentary in the final report, outside the wiki. Examples to exclude from published pages:

- "Останній sync імпортував…"
- "Це змістовна нотатка, не порожня дата…"
- "Тиск є зараз. Зворотного відліку в нотатках немає."
- Repeated "не записано", "не підтверджено", or "у цій сесії не згадується" for every entity.

Do not remove uncertainty by turning a guess into fact. When a gap matters, name it once in ordinary language, such as "Залишок зарядів невідомий". When an account is disputed, identify the competing accounts and link to the evidence. Omit gaps that do not help a reader understand the situation or choose an action.

Do not explain obvious headings, add generic significance paragraphs, prescribe a route through the story, or fill an empty section for completeness.

## Verification and report

Before finishing:

1. Verify important facts, resource values, and uncertainties against the notes. Check that the session selected has meaningful events. Mention a newer empty note in the report only.
2. Read both pages for repetition. Keep each fact where it helps most and link to details elsewhere.
3. Check Ukrainian wording, frontmatter, changed links, and allowed scope. During index updates, confirm every previously listed entity remains reachable.
4. Run `npx quartz build` and fix issues caused by the changes.

Report files changed, the session used, build result, and any evidence gaps requiring attention. No numerical self-scoring or repeated scoring rounds are required.
