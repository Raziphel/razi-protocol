# Planet Field Guide: Seven-System Expedition

> Design-stage player reference. Hazards, discovery gates and optional add-ons
> need confirmation in the full Factorio 2.1 modpack. This document does not
> claim the Celestial Weather add-ons are active on a particular world.

| System | Main destinations | Main purpose | Known mod context |
| --- | --- | --- | --- |
| Calidus | Nauvis, Muluna | Home automation and lunar spaceflight; lunar expansion | Base Space Age and Muluna |
| Solaris | Vulcanus, Castra, Arig, Hyarion, Tellus, Corrundum | Metallurgy, industrial and military breakthroughs; multiple initial approaches | Planetaris and Castra Prime |
| Nyxaris | Gleba, Moshine, Apia/Carnova, Panglia | Data science, twin-world biology, timewarp experimentation, DNA collection and cloning | Source Panglia Moshine data-cell chain and original Apia/Carnova subsystem |
| Vibrant | Fulgora, Ribbonia, Paracelsin | Electromagnetics, alien chemistry, galvanization and specialist processing | Preserve source surface requirements |
| Vespera | Muria, Aquilo, Rubia, Maraxsis | Harsh environments, cooling, fluid and materials engineering | Muria entrance; native Aquilo/Maraxsis content |
| Beetlejuice | Cubium, Linox, Secretas, Frozeta | Outer-rim production and resource specialization | Secretas to Frozeta; Linox fork |
| Umbra | Tenebris, Crucible, Vesta | Late experimental engineering, high-risk planet sciences | Crucible Orbit and Vesta routes |
| Deep Space | Solar System Edge, Aegis, Bellicos, Shattered Planet | Pulsar research, Promethium, stable singularity and transceiver | Aegis/Bellicos required; Nexus/Void optional |

## Additional expeditions

The additional planet adventures are Igrys (Solaris), Rabbasca (Gleba's
moon), Foliax (Nyxaris), Obsidiax (Vespera), and Carna (Umbra). All retain
native discovery and science, and are excluded from mandatory chapter mastery.

See [Optional Planet Expeditions](OPTIONAL_PLANETS.md) for installation notes
and upstream links.

Cerys follows Fulgora to Vibrant. Pelagos and Dea Dia extend Nyxaris,
with Dea Dia retaining its native subsystem. Nexus-Updated and
VoidProcessing-Updated extend the late-game universe without being mandatory
for the normal Razi victory condition.

## Before departure

* Review the actual planet technology and the unique science it unlocks.
* Confirm that your spaceship has appropriate asteroid defense and logistics.
* Check surface-specific recipes and building restrictions before carrying
  expensive machines from a different system.
* If weather add-ons are enabled, verify the destination's active conditions
  in-game rather than assuming every planet uses the same weather rules.
* Expect to use both systems within a pair before leaving that frontier tier.

## Planned Informatron entry format

For each planet: image, source mod and optional/required status; parent star;
discovery gate; unique science and resources; machine/surface restrictions;
native enemies, verified weather hazards; preferred starter logistics; routes
to neighboring planets; and what its chapter mastery needs from that planet.
No unconfirmed recipe or weather claims should appear as gameplay facts.

## Asteroid safety

Razi-managed connections now have progressively stronger region-specific hazards.
Original modded asteroid species, their source spawn curves, and native internal
space routes remain intact. See [Asteroid Routes](ASTEROID_ROUTES.md).

## In-game planet descriptions

Razi Protocol keeps the native planet/space-location description first and
appends a compact expedition briefing explaining its position in the seven-
system campaign. The original mod's lore, environment and mechanical warnings
are retained through Factorio's localised strings, including available source
translations. English and Russian versions of the new briefing are provided.

This is applied in `data-final-fixes.lua` **after** optional planets and the
final galaxy layout. Entries are explicitly listed, exist-guarded and
idempotent: they never create a missing optional world, rename a planet, or
change travel, progression, resource or recipe prototypes. Locations with no
source description use a safe locale fallback without showing unknown keys.

The briefing covers all currently known campaign planets plus relevant moons,
shared orbits, six named stars, slipstreams, belts, native Aegis/Bellicos
stargates, and optional Dea Dia/Nexus destinations. Unknown third-party planets
are not changed. Descriptions do not imply that optional expeditions are
required for victory. Validate a full game load to confirm source text and rich
text formatting display correctly across the installed mod combinations.
