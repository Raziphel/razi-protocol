# Expedition Journal: writing lore and translating

Razi Protocol's journal strings are ordinary **Factorio locale** entries.
The game automatically loads every `.cfg` file in `locale/<language>/`; there is no manual registration step.

## Where to edit

| File | Purpose |
| --- | --- |
| `razi_journal_interface.cfg` | UI labels, status captions, prompts |
| `razi_journal_chapters.cfg` | Chapter titles, mood, introduction and dispatch |
| `razi_journal_titles.cfg` | Quest headlines |
| `razi_journal_stories.cfg` | Quest narrative |
| `razi_journal_field_notes.cfg` | Quest hints, weather and workshop notes |
| `razi_journal_transmissions.cfg` | Unlockable archive title, origin and body |

The historical `razi_journal.cfg` is intentionally empty. **Do not put keys back in it** or you risk duplicate declarations.

## Write a quest

Every quest uses the same stable ID in three different Factorio locale sections:

```ini
[journal-title]
my-existing-quest-id=An interesting objective

[journal-story]
my-existing-quest-id=A few evocative sentences about the expedition.

[journal-tip]
my-existing-quest-id=Practical advice tied to the actual unlock.
```

Those examples belong in their corresponding files. The ID must match `id` in `scripts/razi_journal_data.lua` or its expansion modules.
Never edit an existing ID merely to reword the quest: IDs are referenced in Lua and may be retained in saves.

For chapter prose, edit matching keys in `[journal-chapter-story]` and `[journal-chapter-dispatch]`. For unlockable transmissions, update the matching `[journal-record-title]`, `[journal-record-origin]`, and `[journal-record-body]` keys. The unlocking research is defined separately in `scripts/razi_journal_records.lua`.

## Writing conventions

- **Story** is evocative in-universe prose. **Tip** is player guidance; avoid implying a construction or delivery has happened just because research is complete.
- Use the real discoverable world, source-mod machine, and technology names. Refer to optional worlds conditionally.
- Keep a consistent voice and terminology, but give each world a distinct atmosphere.
- Avoid inventing new technologies, rewards, quest prerequisites or canon in localization alone.
- Preserve all literal tokens such as `__1__`, `__2__`, `[color=#FFFFFF]`, `[/color]`, and any Factorio rich-text markup.
- Keep one `key=value` per line. Never rename locale section names. Use UTF-8 encoding.
- Do not translate technical key IDs or the names of installed mods unless an established localized form exists.

## Translate into another language

Create or edit `locale/<language>/razi_journal_*.cfg`, using the same section and key names as English.
Translate the **value to the right of** `=`. Language folders may initially contain only a subset of strings; Factorio handles fallback according to its locale rules and installed translations. Avoid duplicate keys across the locale files of the same language.

Example:

```ini
[journal-ui]
chapter-cover-open=Open chapter briefing
```

A translation changes only the text `Open chapter briefing`; `journal-ui` and `chapter-cover-open` stay exactly as they are.

## Quality checks

Run `python tools/journal_locale.py` to check the extracted English files for duplicate section/key pairs and validate translated placeholder counts.
Run the existing journal and progression unit tests before releasing. The checker does not replace in-game testing: it cannot confirm that every installed mod still defines a referenced technology or space location.

New English quest entries should supply title, story and tip together. When introducing a new archived transmission, update its origin and body as well.
