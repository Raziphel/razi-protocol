# Space route distance coherence

Factorio uses **kilometres** for the platform travel length recorded by a
`space-connection`. The expanded Razi chart uses **stylized visual units**
for orbits and star-system spacing. Visual positions are **not light-years**.

Razi now preserves the 1,000 km trip from Shattered Planet Approach to
the actual Skewer Shattered Planet because the map icons are now only 5 units apart, with opposite-facing
captions to keep both locations readable. Lost Beyond is 145 units away from that planet and no longer
qualifies for a 1,000 km native commute.

The source-owned distance safety pass runs once at the end of the Factorio
prototype loading process, after final map positioning and route ownership.
It applies increasing minimum lengths only for routes with both real, known
endpoints and **at least 40 units** of visual separation. It skips
unpositioned optional worlds, belt-to-belt crossings, Nauvis/Muluna,
stargates, wormholes, teleporters, portals and Dyson transfers.

It does not remove or create routes or change their asteroid tables or
progression. Existing short hops stay short. Very long source journeys are
never shortened. Changed journeys naturally extend platform travel time,
so they also expose a platform to its route's asteroids for longer.

The fixed curated inconsistencies are Cubium-Secretas (23k to 32k),
Umbra Outer Rim-Vesta (11k to 19k), and Foliax-Nyxaris Slip Stream
(18.5k to 24k). Other native links are corrected only when necessary.

For installed-modpack validation, export the final `data.raw` prototypes
and run:

```bash
python3 scripts/audit_route_distances.py factorio-raw.json
```

This checks the seven curated crossings, physical belt ecology, bypasses,
and visibly remote source routes against the same minimum-distance bands.
The default Python fixtures do not substitute for a full Factorio startup.
