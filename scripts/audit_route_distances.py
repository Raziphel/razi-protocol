#!/usr/bin/env python3
"""Audit Razi's interstellar travel lengths against post-load starmap geometry.

Factorio route.length is kilometres; orbit.distance is map layout scale.
The ratio is *not* physical astronomy. Compact galaxy artwork projects
more kilometres per map unit than the old sprawling layout. It is a signal intended
to catch a 30,000 km cross-star route placed beside a 140,000 km neighbor.
Native orbital hops and mod-specific transit routes are deliberately excluded.
"""
import argparse
import json
import math
from collections import defaultdict
from pathlib import Path

HOMEWARD_SPOKES = (
    ("sye-calidus", "sye-solaris"),
    ("sye-calidus", "sye-nyxaris"),
    ("sye-calidus", "sye-vibrant"),
    ("sye-calidus", "sye-vespera"),
    ("sye-calidus", "sye-beetlejuice"),
    ("sye-calidus", "sye-umbra"),
)
STAR_STAGES = (
    HOMEWARD_SPOKES[:2],
    HOMEWARD_SPOKES[2:4],
    HOMEWARD_SPOKES[4:],
)
NEIGHBOR_LINKS = (
    ("sye-solaris", "sye-nyxaris"),
    ("sye-solaris", "sye-vibrant"),
    ("sye-nyxaris", "sye-vespera"),
    ("sye-vibrant", "sye-beetlejuice"),
    ("sye-vespera", "sye-umbra"),
    ("sye-beetlejuice", "sye-umbra"),
)
NEIGHBOR_BANDS = (
    (("sye-solaris", "sye-nyxaris"), 68000, 96000),
    (("sye-solaris", "sye-vibrant"), 83000, 117000),
    (("sye-nyxaris", "sye-vespera"), 74000, 106000),
    (("sye-vibrant", "sye-beetlejuice"), 112000, 158000),
    (("sye-vespera", "sye-umbra"), 99000, 141000),
    (("sye-beetlejuice", "sye-umbra"), 124000, 176000),
)
DEEP_EDGES = (
    ("secretas", "solar-system-edge"),
    ("vesta", "solar-system-edge"),
)
BELT_BYPASSES = (
    ("aquilo", "rubia"),
    ("crucible-orbit", "vesta"),
    ("vesta", "secretas"),
    ("sye-vibrant", "sye-vespera"),
    ("sye-nyxaris", "sye-vibrant"),
    ("sye-solaris", "sye-vespera"),
)

def obj(x):
    return x if isinstance(x, dict) else {}

def key(a, b):
    return tuple(sorted((a, b)))

# Kilometres and display coordinates are independent. Enforce deliberate
# minimum travel times instead of requiring a fixed km/visual-unit scale.
MIN_LENGTHS = {
    key("sye-calidus", "sye-solaris"): 45000,
    key("sye-calidus", "sye-nyxaris"): 45000,
    key("sye-calidus", "sye-vibrant"): 85000,
    key("sye-calidus", "sye-vespera"): 85000,
    key("sye-calidus", "sye-beetlejuice"): 145000,
    key("sye-calidus", "sye-umbra"): 145000,
    key("sye-solaris", "sye-nyxaris"): 65000,
    key("sye-solaris", "sye-vibrant"): 80000,
    key("sye-nyxaris", "sye-vespera"): 72000,
    key("sye-vibrant", "sye-beetlejuice"): 108000,
    key("sye-vespera", "sye-umbra"): 96000,
    key("sye-beetlejuice", "sye-umbra"): 120000,
    key("secretas", "solar-system-edge"): 100000,
    key("vesta", "solar-system-edge"): 120000,
    key("shchierbin", "asteroid-belt-inner-edge"): 32000,
    key("asteroid-belt-outer-edge", "sye-beetlejuice"): 42000,
}

def positions(raw):
    locations = {**obj(raw.get("space-location")),
                 **obj(raw.get("planet"))}
    cache, visiting = {"star": (0.0, 0.0)}, set()

    def locate(name):
        if name in cache:
            return cache[name]
        if name in visiting:
            return None
        place = obj(locations.get(name))
        orbit = obj(place.get("orbit"))
        parent = obj(orbit.get("parent")).get("name")
        distance, direction = orbit.get("distance"), orbit.get("orientation")
        if not parent or not isinstance(distance, (int, float)) or not isinstance(
                direction, (int, float)):
            return None
        visiting.add(name)
        start = locate(parent)
        visiting.remove(name)
        if start is None:
            return None
        angle = direction * math.tau
        cache[name] = (start[0] + distance * math.sin(angle),
                       start[1] - distance * math.cos(angle))
        return cache[name]

    for name in locations:
        locate(name)
    return cache

def audit(raw):
    routes = obj(raw.get("space-connection"))
    coords = positions(raw)
    links = defaultdict(list)
    for name, route in routes.items():
        if isinstance(route, dict) and route.get("from") and route.get("to"):
            links[key(route["from"], route["to"])].append((name, route))
    issues = set()
    for a, b in BELT_BYPASSES:
        if key(a, b) in links:
            issues.add(f"Unsafe belt bypass remains: {a} -> {b}")

    for a, b in HOMEWARD_SPOKES + NEIGHBOR_LINKS + (
            ("shchierbin", "asteroid-belt-inner-edge"),
            ("asteroid-belt-outer-edge", "sye-beetlejuice")
        ) + DEEP_EDGES:
        match = links.get(key(a, b))
        if not match:
            if a in coords and b in coords:
                issues.add(f"Missing required corridor: {a} <-> {b}")
            continue  # Some source planets are optional.
        if len(match) > 1:
            issues.add(f"Duplicate interstellar route: {a} <-> {b}")
        length = match[0][1].get("length")
        if not isinstance(length, (int, float)) or length <= 0:
            issues.add(f"Invalid travel distance: {a} <-> {b}")
            continue
        if a not in coords or b not in coords:
            continue  # Another source mod has not exposed both parent orbits.
        if length < MIN_LENGTHS.get(key(a, b), 0):
            issues.add(f"Too-short interstellar route: {a} <-> {b}, "
                       f"{length:,.0f} km")
        span = math.dist(coords[a], coords[b])
        if span < 1:
            continue
        density = length / span
        if density < 300:
            issues.add(f"Too-short interstellar route: {a} <-> {b}, "
                       f"{length:,.0f} km across {span:.0f} map units")
        if density > 5000:
            issues.add(f"Disproportionate interstellar route: {a} <-> {b}, "
                       f"{length:,.0f} km across {span:.0f} map units")

    # Adjacent journeys must be useful but not cheap campaign bypasses.
    for (a,b), low, high in NEIGHBOR_BANDS:
        links_here = links.get(key(a,b))
        if not links_here:
            continue
        length = links_here[0][1].get("length")
        if isinstance(length,(int,float)) and not low <= length <= high:
            issues.add(f"Neighbor tier distance mismatch: {a} <-> {b}")
        via_a = links.get(key(a,"sye-calidus"))
        via_b = links.get(key(b,"sye-calidus"))
        if (isinstance(length,(int,float)) and via_a and via_b
                and all(isinstance(x[0][1].get("length"),(int,float))
                        for x in (via_a,via_b))
                and length >= via_a[0][1]["length"]+via_b[0][1]["length"]):
            issues.add(f"Neighbor is longer than its hub detour: {a} <-> {b}")

    # Stage research gates unlock the visible spokes. Ensure tier travel
    # costs increase even when the visual chart is geometrically compact.
    stage_costs = []
    for stage in STAR_STAGES:
        values = [links[key(a,b)][0][1].get("length")
                  for a,b in stage if key(a,b) in links]
        if values and all(isinstance(n,(int,float)) for n in values):
            stage_costs.append(min(values))
    if len(stage_costs)==3 and not (
            stage_costs[0]<stage_costs[1]<stage_costs[2]):
        issues.add("Direct Calidus routes violate escalating tier costs")
    return sorted(issues)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path,
                        help="Factorio script-output/data-raw-dump.json")
    args = parser.parse_args()
    with args.dump.open(encoding="utf-8") as handle:
        raw = obj(json.load(handle))
    raw = obj(raw.get("raw")) if isinstance(raw.get("raw"), dict) else raw
    if not obj(raw.get("space-connection")):
        parser.error("A full data.raw space-connection table is required")
    issues = audit(raw)
    for issue in issues:
        print("ROUTE: " + issue)
    if not issues:
        print("Interstellar distances, belt detours and tier ladder passed.")
    return int(bool(issues))

if __name__ == "__main__":
    raise SystemExit(main())
