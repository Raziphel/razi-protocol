# Calidus: a small but genuine home system

Calidus remains deliberately smaller than the six frontier regions.

| Location | Purpose | Can land? |
| --- | --- | --- |
| Nauvis | Starting factories and launch economy | Yes |
| Muluna | Required landable moon, early space science | Yes |
| Calidus Drift | New light orbital salvage/collection point | No |
| Calidus Slip Stream | Existing departure corridor | No |

## Local shipping

- Nauvis ↔ Calidus Slip Stream: **25,000 km**, the main outward corridor.
- Calidus Slip Stream ↔ Calidus Drift: **17,500 km**, a clean freight spur.
- Nauvis ↔ Muluna: source-owned native moon access, preserved unchanged.
- If the source moon route is absent, Muluna ↔ Slip Stream **14,000 km**
  remains as a fallback so the moon does not become isolated.

The older Nauvis ↔ Drift shortcut and redundant direct Muluna ↔ Slip
Stream shortcut are removed when native moon access exists.
Drift sits southwest of the star at radius 28 / turn 0.625, aligned near
the departure hub instead of spawning a competing upper-star orbit. It uses a Razi-owned existing 64px
route icon and generates **no planetary surface or new art asset**.

This orbital stop provides metallic, carbonic and oxide asteroid chunks
at 55% of the existing Razi belt-edge intensity. It has no hostile
stationary asteroid encounters. As with every Calidus route, the small-only
vanilla asteroid ceiling is enforced by route reconciliation.

It unlocks from the existing `space-science-pack` research, or falls back
to `planet-discovery-muluna` for unusual dependency forks. No research
prerequisite is added to the central seven-system progression, and neither
Solaris nor Nyxaris can be reached early because of the new freight links.

*Compatibility:* Old prototype IDs, native moon orbits and existing
platform schedules are preserved. Real Factorio runtime testing with the
full modpack and older saves is still required before public release.

## Calidus visual pass (October 2026)

Calidus is now a restrained two-spoke transit hub. Razi-authored local
freight links use direct short native paths; source Nauvis/Muluna and
SLP Dyson machinery connections remain source-owned. The optional Dyson
hub connector is only added when the outer solar station has no local
homeward approach. The Calidus background is a smaller warm halo rather
than an oversized brown circular field; the Drift gets a softer amber
locator bloom. Existing platform schedules on removed Razi routes may
need a reachable destination selected after a mod update.

Khemia belongs to Vibrant. It is positioned before PlanetsLib renders
its source graphics and again at final Factorio-native coordinates.
Obsolete native Calidus and Dyson solar-orbit routes are only removed for
positively identified endpoints. Its genuine Vibrant industrial routes,
recipes and planet surface remain source owned. Look for Razi Protocol
Calidus Khemia coordinate log entries to diagnose the in-game map.

Players in Remote View see a small Dyson phase badge beside GALACTIC OPS.
It advances through visual phases 0-6 for their force; selecting the badge
opens the full research-driven Stellar Works display. The badge is a native
GUI control, not an inaccurate world-space sprite overlay, and the sun's
starmap icon stays a fixed orange-gold star for everyone.
