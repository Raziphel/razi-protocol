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

## October 2026: Vespera orbit and stellar identity

Obsidiax is now the innermost Vespera destination at 17 map units.
Muria sits at 21; frozen Aquilo moves to 29, **inside** the existing
30/37-unit debris crossing; and Rubia (41) and Maraxsis (48) are beyond.
No new routes, changed asteroid hazards, travel distances, research
requirements, or climate simulation result from this visual layout.

The systems now reuse their **existing distinct** 512px glow textures,
one per star, rather than painting six identical atlas halos. Nyxaris
is sapphire and cyan, matching its subtly cooled stellar core; Vibrant
is violet, and Vespera is gentle champagne-pearl. Calidus and Deep Space
retain their neutral atlas treatment. No new PNGs, extra background
layers, runtime animations or per-tick work are introduced.

Acceptance still requires an in-game overview and close-zoom pass with
the full modpack, since the existing painted star sprites are retained.

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
