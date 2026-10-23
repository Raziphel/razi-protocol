## October 23, 2026: twin-frontier Aegis relocation and restored Deep Space

The live seven-system design keeps the source-author Aegis/Bellicos pulsar,
waypoints, asteroid art and special mechanics. The visible pulsar sits at
**(0, 210)** on the galaxy chart, directly **south of Solaris and Nyxaris**,
with its entry stargate at **(30, 170)**. These two positions are derived from
the existing Calidus Slip Stream coordinate, not duplicate prototype stars.
Two **112,000 / 118,000 km** researched approaches connect the Solaris and
Nyxaris Slip Streams independently to the native Aegis entry gate. This
requires *both* early-system discoveries, not Vespera or Deep Space. The
advanced Bellicos survey remains tied to Beetlejuice's third-tier research.

Both entries use the Aegis high-density hostile asteroid profile with
guaranteed big (and rare huge) asteroid encounters where their prototypes
exist. All native Aegis custom asteroid species, original science technologies
and special inner routes remain owned by the upstream mod. Missing internal
connection pairs are repaired only when a source connection is actually absent.
The ten-level danger ladder now grades the entry at 8, inner region 8–9 and
deep Bellicos gate at 10, rather than treating the whole expedition as either
Calidus-safe or post-finale.

**Important baked-art fix:** The cinematic background previously drew a
secondary "Bellicos" halo at the old hardcoded north-of-Deep-Space coordinate.
That stale halo caused the disconnected blue graphic shown in screenshots.
The background now uses `bellicos.pulsar_position()` from the **same**
authoritative position plan as native locations, original PlanetsLib sprite
shifts and the final Warden synchronization pass. No source sprites were
recreated or replaced.

**Vibrant:** The sole physical asteroid crossing is moved around the
southwestern rim (Inner Rim 31 / turn .725, Outer Rim 46 / turn .74). It now
points directly at the actual exterior Paracelsin/Khemia/Shchierbin planets.
The outer planets occupy distinct 51/67/70-unit lanes, while Fulgora,
Ribbonia and their native Cerys moon remain interior. Only the original
edge-to-edge crossing traverses the dangerous rock belt.

**Deep Space:** The solar-system edge is closer to the six-star galaxy
(radius 250), while the Nexus, Oort, Sol and Black Hole branches fill out
the newly available northern sky. Shattered Planet's distinct approach,
real final planet and Lost Beyond expedition remain separate. All original
tech unlocks, route lengths, world surfaces and old destination IDs remain.

The Aegis network now uses a single connected spine: Frontier Gate → Outer Edge → Inner Edge → Point Warden → Bellicos Gate, with Near Bellicos Orbit reachable as a short Inner Edge spur. Redundant author shortcuts are pruned, retaining each approved native route name and copying source-exclusive asteroid drops onto surviving paths. The colossal pulsar beam is dimmed without replacing source art. The first-frontier gateway and internal expedition now all remain east of the beam to avoid cutting through the native sprite. Nyxaris moon and twin-world captions are separated, while Vibrant's two long rim labels no longer collide.

Static route-geometry audits found no new line intersections. Verify the
actual Factorio 2.1 rendered coordinates, saved platform schedules and
the native Aegis tech effects before releasing.

## October 2026: Vesta's optional infestation moon and an outer Obsidiax arc

Obsidiax moves from radius 50 / turn 0.245 to radius 68 / turn 0.25,
above-right of Vesta's orbit (radius 56 / turn 0.30). The 21,000 km
Vesta-Obsidiax connection is an elegant diagonal outer spur with no
second Shattered Divide crossing or observed static segment intersection.
The optional Obsidiax discovery still requires Vesta.

**Abacayba 0.0.42+**, when enabled, remains source-owned, but is
reparented to planet Vesta as a real moon, distance 9.5 and turn 0.85.
Its only curated travel connection is Vesta-Abacayba (10,000 km).
Obsolete native links to Nauvis/Aquilo are removed after their custom
asteroid resources are transferred to the new corridor. The real
source discovery is gated by planet-discovery-vesta without replacing
science costs, research effects, enemies, surface generation, Itaverax
recipes, or UMR/UFP machinery.

Abacayba is recommended, not mandatory, because it remains alpha and
pulls in the substantial Ultimate Core/UMR/UFP mod family. It is not a
requirement of the seven-system campaign or the finale. Live Factorio
startup and rendered moon-orbit validation are still needed.

## October 2026: Vespera mineral world and outer-orbit cleanup

- Athos has moved from Solaris into Vespera at radius 33 / turn
  0.565. It is an optional 24,000 km side route off Muria; the main
  Muria–Rubia–Maraxsis/Aquilo spine remains intact. The source's
  original Nauvis/Vulcanus connections are retired only after their
  original custom asteroid resource definitions are preserved on the
  new approved route. The existing discovery unlock and Particulate
  Science content remain native; only the obsolete Solaris/Vulcanus
  discovery prerequisite is replaced by Muria when safe.
- Shchierbin now follows Paracelsin closely at radius 65 / turn
  0.675 with an 18,000 km exterior route. Its route stays outside
  the Vibrant belt and retains its original vanadium gameplay.
- Obsidiax is now at radius 50 / turn 0.245 in outer Umbra, directly
  adjacent to Vesta by an 18,000 km exterior connection. No interior
  asteroid-belt shortcut was added. Both its optional-world integration
  and the primary star layout now use exactly the same coordinates.
- Source planet surfaces, native technology IDs, moon orbits, factories,
  minerals and atmosphere effects are not rewritten.

## 2.1.87: Outer-systems route and label refinement

**Beetlejuice:** Ferrum's remote-controlled metal industry now occupies a
43-unit western orbit with a single local Slip Stream spur (22,500 km).
The obsolete Ferrum–Fulgora and Ferrum–Vulcanus source routes are removed
only after their rare custom asteroid definitions are transferred onto the
approved local connection. Cubium, Linox, Secretas and Frozeta are unchanged.

**Umbra:** Obsidiax joins Vesta beyond the physical Shattered Divide
(radius 54, turn 0.18; 19,000 km exterior route to Vesta). Carna, Arcanyx,
Crucible and Tenebris remain **inside** the mandatory surveyed crossing.
The external Slip Stream is not connected directly to inner planets.

**Vibrant:** Shchierbin moves to radius 73/turn 0.64, well away from the
Slip Stream and remaining connected to Paracelsin by a short 21,000 km
outside-belt side route. Ferrum no longer adds congestion around the rock
crossing.

**Solaris:** Athos has a 34-unit western orbit at turn 0.73 and a 13,500 km
spur from nearby Vulcanus; this avoids the long diagonal next to the
gateway. No old arrival, science ID or planet prototype was replaced.

**Map readability:** Umbra and its two rim locations now have short map
names. Navigational briefings and warnings remain in location descriptions
and technology tooltips. Decorative Carna/Velora orbit sprites and Razi
dotted highlights for their small-world connections are suppressed;
their original planet icons, parents and travel routes remain intact.

The four planned new connections were checked geometrically against
known curated route endpoints: no line intersections, solar-corona incursions
or new crossings of either asteroid annulus were detected. Confirm the
actual PlanetsLib-rendered appearance on a live 2.1.87 Factorio starmap.

## Outer-star breathing room expanded again (October 2026)

Umbra and Beetlejuice are now 124 chart units from Calidus, rather
than 112. Their bearings remain precisely 11/12 and 1/12, retaining
a balanced northwestern/northeastern pair with more breathing room
for their expanded optional worlds and native orbital rings.
All descendant planets and slipstreams move with their parent.
The route geometry check found no new interstellar crossings or
solar intrusions; source-authored travel kilometers are unchanged.

The supplied screenshot also exposed long locale descriptions
mistaken for space-location names. The short map labels were fixed
by the latest shared maintenance update; this pass preserves them
and removes stale duplicate descriptions that contradicted the
present-day exterior belt entry. Vespera's retired asteroid survey
description was also corrected.

## Outer-star breathing room (2.1.78)

Umbra and Beetlejuice now sit at 112 rather than 104 chart units from
Calidus. Their relative bearings (11/12 and 1/12) stay the same. This
gives the deepest systems slightly more breathing room without moving
their individual planet orbits, breaking the six-system travel graph,
or changing physical route kilometers, science unlocks or native artwork.
The two star anchor sprites move in the pre-render PlanetsLib pass and
their descendants receive matching Factorio-native origins in final-fixes.

The red dotted half-tails near Carna and Velora are consistent with the
old decorative route-highlight renderer painting arbitrary third-party
connections as short sprite sections. Colored atlas strokes are now
restricted to approved interstellar waypoints and real physical belt
crossings; native planet links stay visible as normal gray Factorio
lines. This does not delete a space-connection or disable travel.

## Vespera without the Debris Divide (October 2026)

Vespera no longer registers the synthetic inner and outer asteroid-belt
waypoints, their single-purpose technology, its old belt crossing, the
optional decorative ring, or their resource profiles. A clean direct
planet network is used instead: Slip Stream → Muria → Rubia; Rubia
branches to Maraxsis (greenhouse ocean) and Aquilo (distant ice).
Rubia now sits at turn 0.70 to preserve minimum clearance from the
stellar disc. Obsidiax was subsequently relocated to Umbra in 2.1.87; Balack
remains connected to Aquilo. The original Vibrant and Umbra physical
belts are untouched. Existing platform schedules that include the
removed waypoint IDs should be updated before loading a long-running
save.

## Umbra outer gateway and restrained native curves (October 2026)

The previous Slip Stream was at radius 30, intersecting the
31–39-unit debris field and forcing two incoming external routes
through the rocks. It now sits at radius 54, southeast of Umbra.
Both interstellar arrivals approach it wholly outside the belt.
A clean line from the gateway to Outer Rim leads into ONE physical
belt crossing (Outer Rim 39 → Inner Rim 31). Only then do routes
reach Tenebris, Crucible, and two optional inner worlds.

The outer Rim→Vesta leg takes a subtle Factorio-native arc around
the star rather than dipping into the rocks. The Tenebris→Crucible
leg also curves gently along its inner orbit. These use native
`shape="arc"` with Umbra's real `origin` on Factorio 2.1.20+.
Unsupported builds retain straight chords, with no rendered
fake overlay or extra game tick work. Planet native orbit rings
remain available in Full/Balanced/Clean/Off chart settings.

To avoid stranding new players outside the belt, the existing
`razi-umbra-belt-survey` now requires `umbra-discovery` rather
than Crucible. Tenebris requires that survey, Crucible still follows
Tenebris and Vesta still requires Crucible and the survey.
No travel kilometers, asteroid resources, or source-owned moon
connections were changed.

## Umbra gravel field and farther Deep Space (October 2026)

Umbra's former glowing broken wreath is replaced with one static
512px indexed texture of separate shadowed rocks and smaller grit
at the true 31–39-unit asteroid annulus. Both Subtle and Cinematic
modes omit the old smoky ring. The native belt crossing and its
hazards remain fully active and clickable.

Vesta now sits 56 rather than 48 chart units from Umbra.
The Solar System Edge is moved north from 190 to 215 chart units.
Its original dependent Nexus, Shattered, Black Hole, Oort/Sol and
Pulsar/Aegis locations follow the parent coordinate automatically.
Gameplay route lengths, science gates and source orbital ownership
remain unchanged. Review saved platform schedules after updating.

## Native orbital rings for all positioned planets (October 2026)

PlanetsLib 2.0 and Factorio 2.1.20+ use native orbital rings based
on `origin`, `distance`, `orientation` and `draw_orbit`.
Our previous Balanced default deliberately suppressed rings for most
planets. This explains why Solaris showed Castra but not the other
worlds even though each had a valid orbit.

Full is the new default for the six outer systems. It shows every
positioned planet orbit without extra static sprites or runtime
rendering. Balanced and Clean remain as lower-density choices.
Existing players may retain their saved Balanced startup setting;
choose Galaxy Visuals -> Orbital chart detail -> Full to opt in.

Moons and custom source orbit sprites remain source-owned. Slip Streams,
belt markers, decorative stars and deep-space waypoints do not gain
misleading giant rings. Khemia is now validated with a Vibrant-centered
native origin in its final compatibility pass, including a duplicate
prototype guard, rather than a Calidus-centered absolute orbit.

## Vibrant outer-world spacing (October 2026)

Paracelsin now orbits 48 chart units from Vibrant rather than 58, and
Khemia 52 instead of 61. Their bearings shift slightly to 0.68 and
0.625 turns respectively, retaining clear names and a short exterior
route. Both remain outside the fixed 39-unit Outer Rim and the visible
rocks. The sole Outer Rim / Inner Rim hazardous crossing, the separate
Ferrum orbit, all route lengths, research and asteroid resources are
unchanged. Khemia's early pre-render positioning reads the same orbit
plan as its final fix, avoiding stale coordinates that previously
placed its sprite in Calidus.

## Vibrant: western asteroid entrance (October 2026)

The slipstream and both asteroid entry markers sit west of the star.
The 31/39-unit rim markers are nearly radial, creating the only route
that physically crosses the rocky artwork. Interior Ribbonia and Fulgora
have a short connecting road; exterior Paracelsin, Khemia and Ferrum are
spread between the northwest and southwest of Vibrant. All other
Vibrant space connections are plain, belt-safe straight lines, including
the Beetlejuice departure. The old native 5,000 km crossing and its
technology ID remain stable. Platform schedules using earlier waypoint
positions should be reviewed on existing saves.

## Local planetary route networks (October 2026)

The star systems now support nearby transport alternatives instead of a
single mandatory chain:

- Solaris links Vulcanus to Arig and Hyarion to Corrundum as short hops
  within the existing closed orbital circuit.
- Nyxaris links Gleba and the Apia/Carnova orbit directly, alongside the
  established Moshine junction.
- Vibrant routes arriving traffic through the sole western asteroid
  crossing before the interior Ribbonia/Fulgora connection.
- Vespera places boiling Muria before the debris divide, then branches
  toward Rubia/greenhouse-ocean Maraxsis or the farther frozen Aquilo.
  The sole physical belt crossing divides its inner and outer regions.
- Beetlejuice already has a Cubium/Linox/Secretas alternative circuit
  and needs no extra crossed line at its gateway.
- Umbra now starts beyond its rocks, just like Vibrant. The southeast
  Slip Stream (54) and outer rim (39) share a safe arrival corridor;
  the sole hazardous Outer Rim → Inner Rim (31) route enters the inner
  Tenebris → Crucible region. Carna reaches the native Crucible approach
  and Arcanyx branches from Tenebris, so optional worlds do not
  introduce a second rock crossing. Vesta (56) is on an outer northeast
  spur. Only Tenebris → Crucible Approach and Outer Rim → Vesta use
  centered native Factorio 2.1.20+ curves; every belt and external
  connection remains a straight, physically safe chord.

The original three asteroid belt crossings, source-owned moons,
research-gated destinations and interstellar hub connections are
preserved. Vespera now surveys its debris crossing after Muria instead
of Aquilo to prevent an inaccessible outer-world research prerequisite.
Only available destinations receive their matching links.
Test older platform schedules on a backed-up save after updating.

## Solaris closed orbital circuit (2.1.48)

Solaris now forms one complete eight-connection circuit:
`Slip Stream → Vulcanus → Castra → Arig → Hyarion → Tellus → Corrundum → Igrys → Slip Stream`.

The sun and seven planets retain their 2.1.46 orbital positions and climate
order. The **Slip Stream moves to 44 chart units at orientation 0.84**, west
and somewhat north of the star. Its Calidus, Nyxaris and Vibrant departures
radiate outward, with no intersection against the local orbital loop.
Igrys moves a few degrees clockwise to orientation 0.905, keeping that
northern connection short and clear. The Corrundum ↔ Igrys link is restored at 32,000 km and uses a direct native
connection with the existing industrial-deep asteroid profile.

This does not introduce new discovery gates or bypass asteroid-belt science.
The final curated-route authority includes the restored pair automatically.
After loading an older save, check existing platform schedules.

> **2.1.47 authoritative navigation:** Razi now removes the extra native
> planetary route pairs that other installed mods put into our seven
> systems. Approved corridors, asteroid belts, moons, Dyson stations and
> source-only endgame subnetworks remain reachable. The planned Solaris
> network no longer has hidden source mod shortcuts behind our route art.
> See [Authoritative route catalog](ASTEROID_ROUTES.md#authoritative-route-catalog-2147).

## Solaris compact orbital polish (2.1.46)

Solaris is now an intentionally **compact** first-frontier system. The
worlds orbit their original Solaris parent; the values below are chart
distances, not temperature or astronomical units. Original world
conditions, science gates, planet art and gravity are unchanged.

| World | Orbital chart radius | Orientation (turns) | Place in system |
| --- | ---: | ---: | --- |
| Vulcanus | 17 | 0.69 | Inner magma world |
| Hyarion | 21 | 0.37 | Hot inner crystals and lava |
| Arig | 24 | 0.52 | Warm desert orbit |
| Castra | 27 | 0.61 | Industrial/military middle zone |
| Tellus | 29 | 0.26 | Temperate visual belt |
| Corrundum | 33 | 0.13 | Outer atmospheric industry |
| Igrys | 35 | 0.89 | Northwest outer-world expedition |
| Solaris Slip Stream | 28 | 0.75 | Western navigation gateway |

### Navigation and map readability

The local travel network is now a **seven-connection, branching corridor**.
The main arc follows
`Slip Stream → Vulcanus → Castra → Arig → Hyarion → Tellus → Corrundum`.
The existing independent `Slip Stream → Igrys` expedition spur remains.
The retired `Corrundum → Igrys` giant sky chord is cleaned up if present.
This is strictly a Razi-authored route-topology adjustment: required
planet discoveries, seven-system expedition links and all existing
science chains are unchanged. Factorio continues to own clickable
connections, travel time and source-owned asteroid resources.

All eight chart markers now fit into a 35-unit orbital area instead of
the earlier 54-unit outer radius. We verify every local planet icon
remains at least 12.5 chart units from any other and no local line
cuts across Solaris's central star.

To keep native orbit rings from piling up, **Balanced** now shows one
Solaris reference orbit (Castra), while **Full** still shows all
source-orbit rings. The synthetic Slip Stream orbit ring stays hidden.

### Solar atmosphere and chart surroundings

Solaris's native high-resolution sun icon is unchanged, but its extra
Razi atlas corona is smaller, warmer and more transparent. The full
galaxy keeps the crisp indexed sky tiles with lower default opacity.
Four large decorative clouds inside the first-frontier travel corridor
have been removed; distant dust details are dimmer. We don't need to
draw an extra fake route or fog feature to identify the system.

### Test checklist

Load an actual Factorio 2.1 save and examine Solaris at system
and wide-galaxy zoom. Verify the compact planets remain accessible,
planet labels don't overlap, source-owned research progression still
permits each discovery, Igrys retains its gateway link, route overlays
stay aligned, and platforms with old Corrundum/Igrys schedules
are corrected if necessary. These static checks do not prove the
rendered result with every third-party planet source installed.

---

> **2.1.45 route rendering:** The native Solaris direct-line geometry from
> 2.1.44 remains. Razi now owns a rebuilt, path-aware hazard overlay.
> It uses short, fixed-width segments and verified regional arc origins,
> with an optional chapter palette. Install no external overlay. For
> full settings and technical details see
> [ROUTE_HIGHLIGHTS.md](ROUTE_HIGHLIGHTS.md).

> **2.1.44 Solaris route correction:** The eight authored Solaris local
> connections are now direct native Space Age lines, not the previous wide
> arcs that circled the system and neighboring sectors. Igrys retains its
> outer radius of 54 chart units but is moved to turn 0.95 to sit more
> naturally above Solaris. Space Route Overlay 0.2.7+ is the optional
> risk-color renderer; Razi's fixed segmented overlay was removed.

## Solaris local orbital chart (2.1.43)

Solaris is the first detailed region-by-region map polish pass after Calidus
Drift's retirement. The source planets keep all original surface conditions,
research, science recipes, facilities, native moon relations and graphics.

The final starmap uses Razi-relative radii, not astronomical AU or a new
planet-temperature simulation:

| World | Map radius | Turn | Interpretation |
| --- | ---: | ---: | --- |
| Vulcanus | 18 | 0.67 | Inner volcanic orbit |
| Hyarion | 24 | 0.40 | Crystal/lava inner orbit |
| Arig | 30 | 0.53 | Hot desert orbit |
| Castra | 37 | 0.61 | Mid-system military industry |
| Tellus | 43 | 0.25 | Temperate-biosphere visual band |
| Corrundum | 50 | 0.13 | Dense-atmosphere industrial outer orbit |
| Igrys | 54 | 0.86 | Remote rocky industry (not assumed icy) |
| Solaris Slip Stream | 34 | 0.75 | Western departure approach |

The deliberately sparse local corridor follows:

`Slip Stream → Vulcanus → Castra → Arig → Hyarion → Tellus → Corrundum → Igrys`

and has a second Slip Stream → Igrys outer arrival. This is transport
connectivity, **not a change to research/planet discovery requirements**.
The long Corrundum/Igrys leg is an arc around Solaris, not a diameter across
the sun. Prior Razi-authored `sye-solaris-castra`, `castra-hyarion`,
`hyarion-corrundum` and similar redundant route IDs are removed only when
they still connect their expected endpoints, preserving unrelated native and
special third-party connections.

The final map keeps the 1024px Solaris sun, with a weaker decorative ambient
halo. The galaxy and other stars remain in their established locations.

**Engine verification remains necessary:** check at full-system and galaxy
zoom for sprite-only star offset, icon/label overlap, source-owned extra
connections, in-game arc centres (2.1.20+), actual research gates and
platform schedules following an update. Regression fixtures exercise
the intended graph and layout but cannot replace the installed modpack.

> **2.1.42 current map:** Calidus Drift has been retired. Older experimental
> descriptions below are historical. The active home system contains Nauvis,
> Muluna, and the Calidus Slip Stream, with no extra Drift orbit or sprite.

# Razi Protocol starmap: Calidus and the six-star circle

Factorio and PlanetsLib use clockwise turns: **0 north**, **0.25 east**,
**0.5 south**, **0.75 west**. The native map formula is
`x = radius * sin(2π * orientation)`, `y = -radius * cos(2π * orientation)`.

This design is an intentional ring centered on Calidus, with the expedition
chapters advancing upward to Deep Space and Bellicos.

```text
                         BELLICOS / AEGIS
                              /
                         DEEP SPACE
                              |
                UMBRA                  BEETLEJUICE
                     \                 /
               VESPERA    CALIDUS    VIBRANT
                     /                 \
                NYXARIS                SOLARIS
```

| Anchor | X | Y |
| --- | ---: | ---: |
| Calidus / Nauvis | 0 | 0 |
| Solaris | 59 | 102.19 |
| Nyxaris | -59 | 102.19 |
| Vibrant | 118 | 0 |
| Vespera | -118 | 0 |
| Beetlejuice | 71.5 | -123.84 |
| Umbra | -71.5 | -123.84 |
| Required Asteroid Belt inner edge | Vibrant + 31 at 0.17 turns | Inner side |
| Required Asteroid Belt outer edge | Vibrant + 39 at 0.17 turns | Outer side |
| Deep Space / solar-system-edge | 0 | -268 |

## Design rules

- Solaris, Nyxaris, Vibrant and Vespera now sit at **118 chart units** from
  Nauvis (formerly 104). Outer Beetlejuice and Umbra sit at **143 units**
  (formerly 124). Planetary orbits remain unchanged.
- The widest optional planet rings reach about 51 map units from their stars.
  A wider stellar separation clears the neighboring optional orbital rings.
- Planet climates guide visual orbital distances: hot Vulcanus (18),
  Hyarion (19), Arig (27), Muria (20), Moshine (22) and Crucible orbit
  (19) move inward. Remote/icy Paracelsin (49), Aquilo (40),
  Maraxsis (44) and Secretas (40) sit farther away.
  Source game temperatures, solar yields and moon orbits are unchanged.
- Calidus opens two branches through Solaris/Nyxaris into
  Vibrant/Vespera. The Vibrant to Beetlejuice stage now physically
  requires the original native AsteroidBelt crossing. Only seven
  direct interstellar lines remain, plus the belt, with the two useful
  crosslinks Solaris↔Nyxaris and Beetlejuice↔Umbra.
- The Calidus departure slipstream is 20 units due south of home
  (previously 25), clear of Nauvis and Muluna but closer to the center.
  Planet orbits and star textures stay put; only interstellar spacing changes.
- Neighboring planets now have short return routes: Vulcanus↔Castra,
  Arig↔Hyarion, Gleba↔Moshine, Moshine↔Apia-Carnova Orbit,
  outer AsteroidBelt edge↔Paracelsin, Linox↔Secretas,
  and Umbra slipstream↔Crucible Orbit. These are 12–22k km local
  expeditions, not new interstellar shortcuts. They reuse existing
  asteroid difficulty profiles; world discovery prerequisites are unchanged.
- Vespera and the remaining Umbra rim routes intentionally keep a
  single dangerous crossing. Extra shortcuts there either bypass the
  surveys or run over Rubia/Crucible map markers. Old same-system
  crossings directly from Vibrant's inner planets to its outer planets
  are removed while preserving the original native belt core.
- The original discovery technologies continue to gate travel:
  the first two frontiers use Nauvis science, the middle frontiers
  require the earlier branches, and outer discoveries still require
  `space-discovery-asteroid-belt` plus both middle branches.
- Routes increase in challenge: early 60–65k km, midgame 90–100k km,
  Umbra branch 120k km and Vibrant→Beetlejuice 137.5k km total through
  Ribbonia and the source-native asteroid crossing (23.5+24+5+85k).
  The original belt-core 5k segment and its native asteroid spawns
  remain untouched.
- Route distance audit also addressed the three clearest local mismatches:
  Nyxaris ↔ Apia-Carnova planned 17k → 23k km, Nyxaris ↔ Moshine 18k →
  22k, and Cubium ↔ Secretas 19k → 23k. Native in-system lengths still
  use the existing source-preserving 75–135% clamp.
- The original source AsteroidBelt graphic surrounds Vibrant at
  1.12 scale, its native inner/outer gateway at radii 31/39 and
  0.17 clockwise turns north-east. The gateways orbit the root star
  because PlanetsLib removes sprite-only stars in final fixes.
  Fulgora and Ribbonia are inside; Shchierbin and frozen Paracelsin
  outside. To reach the outer worlds: Ribbonia → inner edge →
  native belt → outer edge → Shchierbin / Beetlejuice.
  The direct Vibrant→Beetlejuice and Ribbonia→Paracelsin shortcuts
  are removed. Shchierbin requires native belt science, Paracelsin
  requires Shchierbin.
- **Native rings for every planet around a Razi star** use the Factorio 2.1
  origin-based renderer provided by PlanetsLib >= 2.0.9. The previous code
  set `draw_orbit=false` for all except six handpicked planets, hiding most
  of the orbits. That suppression has been removed.
- Synthetic star icons, artificial slipstreams, and hazard/belt edge markers
  do not draw meaningless extra rings. Secretas, an orbiting world represented
  as a space-location, does receive a native orbit.
- Never copy old PlanetsLib orbit sprites into `PlanetsLib:update` calls.
  Preserve *source-owned* special sprites and moon orbits rather than globally
  deleting other mods' artwork.
- Deep Space now sits north at **(0, -268)**. Its pre-render and final
  native positions use the same orbit manifest. Nexus, the Oort Cloud and Sol
  spread east; Shattered Planet lies southeast; the Black Hole approach lies
  west. Synthetic giant orbit circles are hidden, not functional routes.
- Bellicos/Aegis has a separate northern annex, 170 visual units from
  Deep Space (formerly 110). Its entry stargate is 62 visual units away
  (formerly 28). Preserve the pulsar artwork, native internal connection
  network and the original 250,000 km entry-route gameplay distance.
- Keep the two short same-tier crosslinks, the required asteroid expedition
  around Vibrant, and both distinct outer branches to Deep Space. Avoid
  additional Calidus spokes and unnecessary neighboring-star loops.

### Skewer Shattered expedition and final victory

- Skewer's real `skewer_shattered_planet` now sits **5 chart units
  almost directly SOUTH** of the original `shattered-planet` Approach.
  Their source route is only **1,000 km**: the short map hop finally matches
  the feel of the gameplay length. Its `skewer_lost_beyond` child remains
  145 units from the planet but heads north-east, clear of Oort/Sol.
  The source orbit parents, original routes and all gameplay kilometers
  remain unchanged, and both Skewer prototypes are still optional.
- Opposite Shattered caption directions stop the Approach/planet labels
  colliding. The giant synthetic orbit rings stay disabled.

### Bellicos caption and native-coordinate cleanup

- The Bellicos near-orbit remains a short 3-unit hop from the remote pulsar.
  The Aegis Inner Edge now sits above-right of near-orbit (29, .205);
  Point Warden east in its own branch (48, .255); Aegis Outer Edge
  turns south-east (66, .345); and the Bellicos-side stargate continues
  just beyond it (81, .37), without the old western detour.
  Distinct departure bearings from Inner Edge prevent doubled-looking
  ribbons. Source routes, asteroid hazards, the original 250,000 km
  access journey, and the pulsar artwork are unchanged.
- The layout writer now synchronizes **native origin, distance and
  orientation** after PlanetsLib's orbit update in both data and
  final-fixes. This prevents an old horizontal marker row from surviving
  despite the intended new orbit metadata.
- The Convergence physical transmission remains the only Razi-authored win
  call. A runtime guard reasserts the published Space Age/K2SO/legacy
  silo `set_no_victory` APIs without guessing at foreign scripts.
  Unsupported independently scripted wins still require source integration.

## Verification

- `tests/test_starmap_clarity.py` verifies compact ring radius, exact
  six-star positions, northern Deep Space, belt integration, stellar clearance,
  segment crossings, and the minimum room for outer optional planet orbits.
- `tests/lua/test_galaxy_layout.lua` covers final-stage parent updates,
  native moon persistence and signature rings.
- `tests/lua/test_asteroid_belt_integration.lua` protects the original
  upstream sprite, its shift to Vibrant's sun, native hazards, and missing
  gateway safety. `tests/test_starmap_clarity.py` verifies that the belt
  doesn't intersect surrounding planets.
- `tests/lua/test_bellicos_layout.lua` covers absent and retyped source
  locations, gate routing and remote-orbit positioning.
- `scripts/audit_route_distances.py` validates actual travel kilometers,
  entirely independent of starmap art.

Real Factorio screenshots are still necessary to judge shader scale, label
overlaps, and third-party system art. Tests do not replace live rendering.

## Why earlier maps ignored the star positions

PlanetsLib 2.0.9 renders `sprite_only` stars into `utility-sprites`
and **deletes their space-location prototypes during its own
`data-final-fixes`**. Because PlanetsLib runs before Razi at that stage,
the old Razi layout encountered missing parents and skipped every star and
many planets. Our test mocks failed to reproduce that deletion.

The new two-stage design performs `galaxy_layout.data_updates()` in
`data-updates.lua` to move the actual star sprites **before rendering**.
`galaxy_layout.data_final_fixes()` subsequently reapplies the exact
native `origin/distance/orientation` coordinates to all surviving
planets, slipstreams, and nested moons without restoring removed stars.
Original unique source orbit sprites are retained.

## Verifying the running mod

On a mod-data rebuild, Razi writes a single
`[Razi Protocol/starmap] PRE-RENDER-2026-10-11-v3` line and a later
`[Razi Protocol/starmap] NATIVE-2026-10-11-v3` line to
`factorio-current.log`, followed by the final **native** starmap
coordinates calculated from each location's `origin`, `distance`,
and `orientation`. These are the same fields Factorio uses to draw
the map; the old geometry tests only checked `orbit` metadata.

If either log marker is absent, the client is loading an outdated build.
If the pre-render star positions differ from the expected positions,
the custom star sprites will be misplaced. The native pass logs virtual
star-art positions explicitly because PlanetsLib correctly removed
those prototypes before Razi's final fixes.

## Design follow-up

The six-star ring centered on Calidus works as an at-a-glance map. Keep
Deep Space to the north and Bellicos beyond it. Treat the required
Vibrant sun asteroid ring as a distinct midgame hazard landmark, not
something every new player sees circling Nauvis. Avoid additional direct
outer-system routes that would bypass the native asteroid crossing.

## First-party asteroid frontier (2.1.14)

Razi now replaces the required upstream AsteroidBelt with three Razi-owned
physical crossings: Vibrant, Vespera and Umbra. The original Vibrant waypoint
and research names remain for save migration; the surrounding ring uses
existing Razi textures rather than external art. Four longer routes also have
concentrated midroute asteroid fields and dim decorative field markers.
See [ASTEROID_ROUTES.md](ASTEROID_ROUTES.md) for the current implementation;
earlier references in this file to source-owned AsteroidBelt are historical.

## Visual orbit density (October 2026)

**Full** is the default: all positioned, visible planets draw native
orbit rings. Players can choose **Balanced** (several rings per system),
**Clean** (a few reference rings), or **Off** (no Razi-managed native
planetary rings). Off also hides Secretas's native space-location
circle and Khemia's native ring without moving those worlds. Custom
source orbit sprites and moon rings are not touched.

This setting changes only `draw_orbit`. Existing saved startup settings
can retain Balanced until the player selects Full. All star coordinates,
planet/moon positions, campaign routes, custom orbit graphics, technology
gates and travel distances remain untouched.

The geometry is intentionally not moved during this polish pass. Moving star
anchors requires regenerating pre-aligned highlight masks and repeating all
campaign-clearance tests.

The Apia/Carnova waypoint and recognized nearby moons have opposite text orientations for readability. Coordinates, native orbits, and connected routes remain unchanged.

## Optional planet relocation fix, October 2026

The optional outer-system worlds Igrys, Foliax, Obsidiax, Carna, Ferrum,
Khemia, Arcanyx and Balack now participate in both the early PlanetsLib
star-art pass and the final Factorio-native coordinate pass. Previously their
late PlanetsLib update could silently skip a deleted sprite-only parent star,
leaving them near Calidus. Their intended host stars, radius and orientation
are unchanged. Moon parentage, source routes and progression remain intact.

## Calidus Drift and Khemia correction (October 2026)

The Calidus salvage destination now sits at radius 27, orientation 0.56
(southwest of the star), closer to the main southward departure hub. It
never draws a native orbital circle. The mod's source prototype and its
shared layout agree, preventing a next-load jump.

Khemia's optional chemistry world is explicitly resolved as a planet or
space-location depending on the installed source mod. Before star-art
cleanup and again in the native final pass, it is positioned with Vibrant's
absolute origin, radius 61, turn 0.61, outside Vibrant's belt. A targeted
pass protects Khemia and Drift if another late compatibility adjustment
reapplies old origin values. No research prerequisites or space route
lengths are changed.

## Khemia double-prototype guard

The final safeguard now audits both potential Factorio types (planet and
space-location) for Khemia, preserving any custom orbit sprite and
reanchoring every visible matching prototype to Vibrant. This avoids
leaving a second instance next to Calidus if a dependency exposes both.
Coordinates are logged in the Factorio log for future screenshots.

## Calidus visual pass (October 2026)

The home star keeps Nauvis/Muluna and the Dyson solar stations near the
centre while the Calidus Slip Stream and Drift form one short outbound
freight spur. Source Nauvis-Muluna routes remain, and redundant Razi
spokes are pruned when native moon access exists. The original warm
halo is smaller and the Drift locator quieter. The frontier star anchors,
asteroid-gate connections and research gates remain untouched.

Khemia is anchored twice to Vibrant, before the irreversible PlanetsLib
rendering and in the last Factorio-native geometry pass. Source-owned
solar-orbit IDs are recognized by native technology unlock effects, and
obsolete Khemia-to-Calidus routes retired. A final coordinate assertion
and log provide concrete diagnostics.


## Calidus 2.1.38 visual integration

The original central PlanetsLib source star art is replaced at data-updates,
while source planets, star magnitude, solar power and other stellar sprites
remain intact. Drift now sits just west and below the Slip Stream, giving
its freight spur a short diagonal instead of an awkward horizontal stroke.
Dual Khemia planet/space-location prototypes are both reparented to Vibrant
before PlanetsLib's irreversible starmap baking, with distinct source-owned
orbit sprite properties preserved. Their final native positions are
verified and any marked PlanetsLib orbit-art layers logged for diagnosis.

A per-force research-driven Dyson badge appears beside Galactic Operations
in Remote View. Galactic Operations > Stellar Works displays seven art
stages. The actual starmap star is intentionally static, since Factorio's
native prototype sprites cannot switch per force at runtime.
