# Infinite research after the first five levels

Razi Protocol 3.x keeps the original infinite research for the first five
completed infinite levels, then offers a separate system-tech-card continuation.
A vanilla technology with a -7 starting level therefore switches when the
next native level would be 12, not after researching five early finite upgrades.

## Scope

The final data-stage pass inspects every technology with
`max_level = "infinite"`, including technologies added by companion mods.
It selects ordinary repeatable bonus effects (productivity, mining, military,
robotics, artillery and similar modifiers). The `upgrade` property is a
technology-menu presentation choice and does not restrict eligibility.

Research using mapped science from Calidus and the other systems converts those
ingredients to their system cards. Nonmapped ingredients, including special
research data, remain unchanged. A continuation is created only when an
existing laboratory can consume the full result. No universal lab is added.

One-time unlocks, unknown effect types, disabled/hidden technologies,
research-triggered technologies and incompatible lab combinations are
intentionally left untouched. Every omitted infinite technology is reported
by name and reason in factorio-current.log under
`[Razi Protocol/infinite-research]`.

## Save compatibility

The original technology IDs are never renamed or removed. At the threshold,
force research switches to a stable `razi-system-infinite-...-cards` ID.
Completed native levels beyond the threshold are credited to the new research;
partially completed research and queued work are kept. Saves which already
transitioned after eight native levels carry their previous levels across
once on configuration change. Missing card recipes leave the original path
open until the new path can be researched.

The cost formula is offset to use the original level, including technologies
whose names already end in a numeric starting level.

## Verification

`tests/lua/test_system_infinite_research.lua` provides mock regression cases
for eligible and excluded technologies, five-level boundaries, high-level saves,
eight-level migration, research queues, lab compatibility and cost formulas.
The full Factorio 2.1 headless load test is still required before release.
