# Calidus: Nauvis, Muluna, and the departure corridor

Calidus is deliberately the smallest home system. Its sun and source-owned
solar-orbit destinations stay intact. Nauvis remains the starting world and
Muluna remains the required landable moon.

**Calidus Drift was retired in Razi Protocol Dev 2.1.42.** No new drift
location, unlock, halo, or freight route is registered. Existing saves should
be backed up before updating: any space-platform schedule pointing at the
retired destination will need a new target.

| Location | Gameplay purpose |
| --- | --- |
| Nauvis | Starting factories and rocket launches |
| Muluna | Native Nauvis moon and early science |
| Calidus Slip Stream (`sye-calidus`) | Departure hub toward Solaris and Nyxaris |
| Native solar engineering orbits | SLP Dyson Sphere source locations |

## Travel and safety

- Nauvis to Calidus Slip Stream remains **25,000 km**.
- Native Nauvis-to-Muluna access remains unchanged.
- Muluna to the Slip Stream remains a **14,000 km fallback** if the native
  Nauvis/Muluna route is missing.
- All older routes pointing to Calidus Drift are cleaned from the final map.
- Calidus retains its small-vanilla-asteroid ceiling; custom source
  asteroid chunks and native Dyson routes are not removed.

## Star chart

The Calidus sun remains the compact, warm counterpart of the outer stellar
artwork. The native star and solar-orbit labels are retained, but there is no
second salvage-node halo or extra orbit clutter. A quieter static starfield
gives labels and travel lines more breathing room.

Khemia still belongs to Vibrant and is positioned before PlanetsLib renders
its sprite and again in the final native coordinate pass. Dyson progression
continues to appear in the Galactic Operations UI, not as a fake stage of
the source star on everybody's static map.

## Save migration checklist

Try old saves with a backup. Change any platform schedule that targeted
Calidus Drift, confirm native Nauvis/Muluna travel still works, verify the
Calidus hub opens Solaris and Nyxaris independently, and inspect the
sun-orbit Dyson destinations. Source/static tests cannot certify in-game
platform state or the complete Factorio 2.1 modpack load.
