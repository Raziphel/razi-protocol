## Current Vespera design: no asteroid belt (October 2026)

Vespera's two In/Out space locations, the artificial grey belt and
its 6,500 km crossing were removed. It now uses direct planetary
connections: Slip Stream → Muria → Rubia, with Rubia branching toward
oceanic Maraxsis and icy Aquilo. This decision supersedes all older
Vespera belt experiments documented below. Vibrant's and Umbra's
physical asteroid fields are unaffected.

## Expedition Journal: field dossier, not a command dashboard

Use three quiet folios for Quests, Projects, and recovered Journal entries.
The active chapter is the only prominently surfaced index card. Body copy
is neutral and readable, with small chapter-colored cues for orientation.
Actual technologies and source game artwork remain the visual anchors.
Avoid full-color header text, equal-weight boxed tiles, large ornamental
progress meters, and unrelated control-room metaphors.

Major projects are named dossiers. Their progress tracks source research and
physical expedition delivery, not invented completion statistics. Project
icons are fixed to 32 Factorio GUI units to prevent intrinsic sprite scaling.
Only the selected dossier gets a stronger accent and the large detail reader
has one scroll pane. The Dyson art stays backed by its existing stage sprites.
This redesign adds no texture files or periodic render workload.

## October 2026: Umbra's shaped orbital routes

Umbra's Slip Stream is relocated past its ring instead of inside it,
and both incoming lanes now stay free of rocks. The southeastern
rim markers give the only authored hazardous belt crossing;
inner Tenebris and native Crucible form a compact western crescent.
Carna and Arcanyx are reachable through internal spurs, and outer
Vesta has its own northeastern opening, not a diagonal through
the star or the asteroid ring. Two centered Factorio-native arcs
bring controlled orbital flow instead of arbitrary long sweeping
lines: Tenebris→Crucible and Outer Rim→Vesta. All other Umbra
routes remain deliberately straight, especially the crossing.
The survey is now researched before the inner worlds to avoid
a progression deadlock. Live Factorio zoom checks are still needed.

## October 2026: Umbra rocks and farther Deep Space

The fuzzy copper wreath wasn't convincing as a shattered asteroid
field. A purpose-made 512px static transparent rock texture
replaces it without introducing another sprite layer or periodic
render cost. Sparse irregular rocks, not atmospheric fog, match
the real 31–39-unit crossing. Vesta has more exterior space at
radius 56, and the Deep Space parent anchor at 215 pulls its
Nexus, Shattered, black-hole and Aegis/Pulsar branches outward.
Asteroid spawn profiles and tech progression are preserved.
The resulting artwork needs a Factorio zoom-level review.

## October 2026: Umbra orbital and belt clarity

The earlier Umbra 'In/Out' markers were almost on the same circular
orbit; the outer marker was actually slightly *closer* to the star.
They now sit at 31 and 39 map units and the far-side Vesta at 48.
Tenebris (24), Crucible's native approach (20), and optional Carna
(29)/Arcanyx (27) have spread bearings within the belt.

The Slip Stream no longer links to Crucible redundantly: reach the
source-owned Crucible landing route through Tenebris. Existing
Carna/Arcanyx gateways stay accessible without the additional four-way
network of duplicate routes. Native Umbra connections use the same
safe straight-line presentation as other Razi systems. Crucible and
its approach get opposing labels; parent-child prototypes are retained.

The static Subtle sky now uses the existing sparse Umbra debris texture
at the real ring's scale instead of the undersized, continuous blurry
brown ring. Cinematic retains a barely visible optional smoke accent.
No new graphics, per-tick effects or changes to asteroid hazard science
were introduced. Manual inspection at normal Factorio zoom is required.

## October 2026: Source-grounded Vespera orbits

Vespera's hot inner Muria is 21 map units out, with lava-heated but
cold Obsidiax at 25. The original debris ring stays at radii 30–37,
separating the inner worlds from Rubia (42), distant greenhouse-ocean
Maraxsis (48) and the truly icy outermost Aquilo (57). Optional Balack
(63) shares Aquilo's outer orbital region.

A single researched physical belt passage feeds two **independent**
branches: outer rim -> Rubia -> Maraxsis, and outer rim -> Aquilo.
To prevent research and travel deadlock, the belt survey follows Muria
instead of requiring Aquilo first. Both outer world technologies
now independently require the survey. Rubia still leads to Maraxsis.
Existing source planetary environments and native asteroid hazards
remain unchanged. The previous star-specific glow artwork remains.

Confirm map labels, star clearance, optional side paths and real
Factorio 2.1 loading at near and full galaxy zoom.

## 2.1.72: Restrained visual hierarchy

The sun PNGs remain the original 1024px Razi textures. Calidus is warm
yellow, Solaris orange, Nyxaris botanical teal, Vibrant electric indigo,
Vespera neutral pearl, Beetlejuice rose, and Umbra dark copper. Each star
gets exactly one tuned atlas halo with its own radius and opacity; no
extra flares, lens effects or animated backgrounds are registered.

Subtle mode draws a single hand-authored `belt-vespera.png` or
`belt-umbra.png` per outer system, rather than generic ring plus debris
duplicates. Cinematic mode optionally adds one faint matching fragment
each. Vibrant retains its dedicated safe legacy art layers and never gains
a second generic ring.

Route warning presentation is reserved for big or huge threats.
Harmless shuttles have short tooltips; optional custom species still
raise uncertainty warnings. Each actual belt crossing has its own
restrained existing navigation palette, and native connection geometry
remains authoritative.

The research experience likewise keeps the native science icons and
technologies. Razi-owned milestones sort into five groups, First Frontier,
Middle Frontier, Outer Frontier, Deep Space, Convergence, while the
Campaign panel uses one 20px native card icon and a five-pixel
progress indicator for each system. Nothing changes science recipes,
lab capacities, travel risk, unlocks or research progress.

**Art budget:** no new PNGs, no extra star atlas tiles, two fewer belt
layers in Subtle mode, no new render tick loops. Any further image
refinement should replace an existing asset rather than add another
full-map decoration.

# Razi Protocol Art Direction

Razi Protocol's visual identity is anchored by the existing Solaris, Nyxaris,
Vibrant, and BeetleJuice stars and by the eight industrial technology cards.
New assets should extend that collection rather than reinterpret it.

## Stars

- Use a centered, nearly frame-filling stellar disc on transparency at
  1024 x 1024 pixels.
- Preserve the originals' turbulent, layered surface detail, restrained corona,
  sharp alpha edge, and strong readability when reduced for the starmap.
- Give each system a controlled palette and characteristic surface pattern;
  avoid flat circles, generic lens flares, text, frames, or scenery.
- Vespera is pearlescent white and platinum, with moonstone-gray currents and
  restrained champagne highlights. It must remain neutral enough not to read
  as a second Nyxaris-blue star.
- Umbra is a near-black, eclipsed star with selective molten-copper fissures,
  a brass limb, and a smoky bronze corona. Its dark body is the dominant read;
  avoid violet so it cannot be confused with Vibrant, and avoid expanding the
  hot accents until it resembles Solaris.

## Technology cards

- Cards are 256 x 256 transparent PNGs using the same tilted, chunky industrial
  cartridge silhouette, dark worn metal, copper contacts, inset stellar window,
  bevel lighting, and compact framing as the original card set.
- The inset star carries the system palette while the casing remains materially
  consistent across the collection. Dedicated art is preferred to runtime tint.
- System-colored casing accents may echo the inset, but neutral worn metal and
  the gold electrical contacts should remain shared collection anchors.
- Details must survive Factorio's small inventory and technology icon sizes.

## Route icons

The four 64 x 64 icons in `graphics/icons/routes/` form one compact family:

- `planetary-route`: ordinary local planetary travel.
- `interstellar-route`: travel between stellar systems.
- `asteroid-route`: hazardous asteroid-belt crossings.
- `deep-space-route`: extreme-distance and late-game routes.

Their editable SVG sources are kept beside the PNGs. All use a worn octagonal
navigation-instrument housing, recessed fasteners, a dark gridded display,
high-contrast route marks, restrained emissive color, and clean alpha. The
silhouette and main route symbol must remain legible at 32--64 pixels; avoid
glossy circular badges, flat neon nodes, or UI treatments that read as generic
mobile-app icons. Add a category only when it communicates a genuinely
different route.

## Ownership and validation

Keep external-mod graphics as dependency references; do not copy them into this
repository. The legacy `graphics/orbits/` images were not restored from the
original edition: Dev has no references to those bitmap rings and its current
PlanetsLib orbit/starmap layout uses prototype orbit data instead.

Run `python3 scripts/audit_assets.py` after changing graphics. The audit resolves
every Razi-owned graphics path, validates PNG headers, alpha and known dimensions,
and protects the dedicated star/card and late route-icon contracts. Lua route
fixtures additionally verify that every final space connection receives an icon
without overwriting icon metadata owned by another mod.

## Protocol Codex chapter theming (2.1.18)

The first-party expedition Codex now uses its own shared theme catalog at
`scripts/razi_journal_themes.lua`. The 18 chapters use distinct colors and
source-prototype artwork instead of repeated generic buttons:

- Calidus: brass and copper; Solaris: molten orange; Nyxaris: botanical green
- Vibrant: electric azure; Vespera: arctic lilac; Beetlejuice: mineral gold
- Umbra: crimson; Stellar Works: solar gold; Network: trade turquoise
- Industrial Constellations: signal amber; Finale: starlight lavender
- Foundations: bronze; Fleet: flight blue; Outposts: explorer green
- Sciences: laboratory violet; Defense: ember red; Deepworks: radiation blue
- Echoes: archive parchment, with recovered-signal iconography

A localized short mood caption gives each chapter a distinct setting.
Icons fall back to the Codex crest if the corresponding source mod sprite
is absent, without introducing new external artwork dependencies. Native
Factorio frames, progressbars, and modest color rules provide the look,
with no scripted animations, gameplay changes, or ticker work.
