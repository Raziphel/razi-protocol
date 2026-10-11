# Razi Protocol settings

The startup settings use the same visual approach as **FluxWorks**: compact
category-based order prefixes, colorful localized headings using Factorio
rich text, and clear descriptions explaining the recommended configuration.

All five options are standard Factorio **startup settings**. Change them in
**Settings → Mod settings → Startup**, then restart/reload as prompted.
Changing startup settings may rebuild prototype definitions, so back up
existing saves before experimenting with a substantially different modpack.

## Worlds & Encounters

**Yellow heading.**

| Setting | Default | Effect |
| --- | --- | --- |
| Route modded enemy factions | On | Routes supported enemy mods to thematic planets and suppresses vanilla spawn noise on their configured surfaces. Off delegates placement to the source mods. |

Note that map-generation changes generally affect newly generated chunks,
not enemies that already exist in an established save.

## Production Integration

**Cyan heading.**

| Setting | Default | Effect |
| --- | --- | --- |
| K2SO interplanetary industry | On | Creates the optional K2SO-based exchange recipes connecting existing industries across systems. Off leaves original K2SO recipes alone. |
| Modded-planet industrial exchanges | On | Creates optional industrial exchanges among Rubia, Paracelsin, Moshine, Linox, Vesta, and Tenebris, only when source mods and production paths are valid. Off preserves the native factory recipes. |

These two settings are **independent**. Neither turns off mandatory system
science, galaxy layout, destination discoveries, or native production.
They only control the separate Razi-authored industrial *alternatives*.
Missing optional mods are already handled by each alternative's safety
checks. Defaults preserve existing gameplay behavior.

## Quality of Life

**Green heading.**

| Setting | Default | Effect |
| --- | --- | --- |
| Hide redundant tier-4 assemblers | On | Hides duplicate Planetaris Hyarion / Lithium Battery assembler tiers when present because K2SO's advanced assembler already covers that role. Off retains native tiers. |
| Expedition descriptions on the starmap | On | Preserves source authors' original planet descriptions, then appends Razi's system headings and briefings. Off uses the original descriptions without the Razi additions. |

## Visual consistency and localization

Razi's five setting names and descriptions are localized in
\`locale/en/settings.cfg\` and \`locale/ru/settings.cfg\`.

Each label follows FluxWorks' proven rich-text pattern:

\`\`\`ini
[color=cyan][font=heading-2]Production Integration[/font][/color] K2SO interplanetary industry
\`\`\`

Yellow identifies worlds, cyan indicates interplanetary industry, and green
marks interface and progression-cleanup options. The color groups sort
together through the \`aa[worlds]\`, \`ba[integration]\`, and
\`ca[quality-of-life]\` order prefixes, rather than injecting empty dummy
settings for headings. English and Russian descriptions cover what both
Yes and No actually do, with the default flagged as recommended.

This is a **settings presentation and optional-controls update**, not a
global redesign of other mod authors' settings. Razi only localizes and
changes settings that it owns. The existing hidden \`adjust-maraxsis\`
compatibility setting remains untouched.

### Automated safeguards

The new \`tests/lua/test_settings_presentation.lua\` checks all five
settings, their names and defaults, localized headings, order keys, and
matching translated descriptions. Existing integration fixtures also
assert that disabled optional catalogs are not created, and that original
planet information remains untouched when its briefing toggle is off.
