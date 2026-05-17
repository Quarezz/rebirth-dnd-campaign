# Campaign Dashboard Update Prompt

Use this prompt after an Obsidian sync when you want to refresh the Quartz homepage and campaign dashboard.

```text
You are updating a Ukrainian D&D campaign Quartz vault after an Obsidian sync.

Goal:
Update the homepage and campaign dashboard so the remote Quartz vault immediately shows:
1. A concise recap of the latest meaningful session.
2. A campaign panel with the latest priorities, open quests, timers, developments, and possible next routes.

Source-of-truth rules:
- Treat `content/Notes/` as source of truth.
- Do not edit files under `content/Notes/`.
- Use only facts supported by session notes and existing campaign pages.
- Keep all user-facing content in Ukrainian.
- Preserve existing Obsidian/Quartz wikilink style.

Workflow:
1. Read `.sync-log.txt` to see what was imported in the latest sync.
2. Identify the latest session note with actual content. If the newest session only has a date/LP and no real events, say so and recap the latest previous session with meaningful events.
3. Read relevant active quest pages, especially:
   - `content/Квести/Всі_квести.md`
   - `content/Квести/Розслідування_Тиші_в_Есборзі.md`
   - `content/Квести/Порятунок_Опал_Дескард.md`
   - `content/Квести/Прокляття_Івена.md`
   - `content/Квести/Порятунок_Рексара.md`
   - `content/Хронологія_подій.md`
   - any newly changed character/location/quest pages from `.sync-log.txt`
4. Update `content/index.md` so the first page shows:
   - `Recap останньої повної сесії`
   - `Панель кампанії`
   - a short priorities table
   - quick links to main sections
5. Update or create `content/Панель_кампанії.md` as the canonical campaign dashboard.

Dashboard structure:
- `Стан після останнього sync`
- `Recap останньої повної сесії`
- `Найважливіше зараз`
- `Таймери і тиск`
- `Куди можна піти далі`
- `Відкриті питання`
- `Швидкі посилання`

The dashboard should answer:
- What is urgent right now?
- Which quests are active?
- What are the next concrete actions?
- What time-sensitive threats exist?
- Which NPCs/locations matter next?
- What can the party reasonably do next session?
- What questions are unresolved?

Style:
- Be concise and practical.
- Prefer tables for priority/action summaries.
- Avoid long lore dumps.
- Do not duplicate full quest pages; link to them.
- The homepage should be short enough to scan immediately.
- The dashboard can be fuller, but still focused on decision-making.

After editing:
- Run `npx quartz build`.
- Report:
  - which files changed
  - which latest session was used for recap
  - whether build passed
  - any warnings or gaps, especially if the newest session note was empty
```
