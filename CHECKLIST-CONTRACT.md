# Checklist Contract — `content/Чекліст_Рувена_перед_сесією.md`

This file is embedded into the sync prompt (`.cursor-sync-prompt.txt`). It governs the format of the pre-session checklist: a player-facing, at-the-table quick-scan page. Compact entity-based sections; never long-form prose.

## Rules

1. Read changed session notes in full (including appended text), the current checklist, and relevant linked pages. Notes outrank stale derived pages. Invent nothing.
2. Keep the H1 `# Рувен — чекліст перед сесією` and the status line `> Актуально після [Сесії N](Notes/Сесія%20N.md) (date). **Пул LP: X.** Огляд — [Панель кампанії](Панель_кампанії.md).` Use the latest recorded LP pool; unknown → `(?)`; never reset to zero by default.
3. Keep these H2 sections, in this order: `Додати вручну`; `Ефекти на Рувена`; `Супутники`; `Предмети`; `НПС і борги`; `Квести`; `Франшиза`; `Архів`.
4. Section routing: effects and conditions on Ruven himself, including his promises and obligations → `Ефекти на Рувена`; companions (Рексар, Комарі) and effects they grant → `Супутники`; objects and consumables → `Предмети`; NPCs, debts, and obligations to others → `НПС і борги`; active quests and next steps → `Квести`; Acquisitions Inc. → `Франшиза`.
5. One unnested physical line per reminder: `- [ ] **Тема:** дія / механіка; число, тривалість або (?) за потреби. [СN](Notes/Сесія%20N.md)`. No tables, recap paragraphs, or nested bullets.
6. Markdown links only, relative to the content root, with `.md` and spaces encoded as `%20`; validate every target. Session tags are clickable `[СN]`.
7. A tag records the session of the last substantive change to that item, not the latest sync. Preserve unchanged tags; add older source tags only for distinct retained mechanics or explicit conflicts.
8. Keep the visible insertion instruction under `Додати вручну`. Accept new lines tagged `[ручне]` or untagged. `[ручне]` also preserves inherited player notes without a traceable session; do not invent attribution.
9. Each sync: route manual items into the matching section, merge exact duplicates without losing details, and replace `[ручне]` only when a source supports it; otherwise preserve the player's wording and intent.
10. Add only actionable reminders, lasting effects, held or uncertain items, obligations, active quest steps, and franchise rules. Urgent items first within a section; update an existing line before adding another.
11. Preserve all still-valid numbers, triggers, durations, ownership, costs, and promises. Never delete a valid item merely because it is old, absent from new notes, inconvenient, or over the length target.
12. Resolved one-off tasks, spent effects, and superseded states move to `Архів` (see rule 18) instead of being deleted.
13. In active sections, a checkbox means "processed this time": reset recurring checks only for a new played session; remove checked one-off actions unless newer evidence reopens them. An untagged/manual item is not disposable.
14. Never infer in-world elapsed time from real session dates. Unknown expiry, charge, ownership, or changed-form mechanics → compact `(?)`; preserve the useful reminder until resolved.
15. Conflicting testimony: keep both attributed versions side by side with `конфлікт версій`; do not pick a winner or turn a reported recommendation into established truth.
16. Keep historical narrative, evidence caveats, and campaign analysis on linked pages. The checklist keeps only the player's action or mechanic with short uncertainty markers.
17. Length guard for active sections (everything above `Архів`): aim 40–60 physical lines, ≤ 45 checkbox items, normally ≤ 25 visible words per item excluding tags. Shorten prose and merge same-section duplicates first.
18. Archive rules: archived items are grouped under H3 session-range headings (`### С61–С70`; ranges of 10 sessions; newest group on top). An item goes into the range containing the session where it ended (its newest tag); create a new group when needed. Archived items use `- [x]`. Do not prune the archive unless the user explicitly asks.
19. Before saving, check facts, LP, omissions, manual preservation, removals, tags, link targets, and counts; if valid facts still exceed the length guard, preserve them and report the overage instead of silently dropping them.
