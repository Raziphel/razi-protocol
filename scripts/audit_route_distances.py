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

STARTER_BRANCHES = (
    ("sye-calidus", "sye-solaris"), ("sye-calidus", "sye-nyxaris"),
)
MIDDLE_BRANCHES = (
    ("sye-solaris", "sye-vibrant"), ("sye-nyxaris", "sye-vespera"),
)
OUTER_BRANCHES = (("sye-vespera", "sye-umbra"),)
LATERAL_LINKS = (
    ("sye-solaris", "sye-nyxaris"), ("sye-beetlejuice", "sye-umbra"),
)
CAMPAIGN_ROUTES = STARTER_BRANCHES + MIDDLE_BRANCHES + OUTER_BRANCHES + LATERAL_LINKS
VIBRANT_BELT_ROUTES = (
    ("sye-vibrant", "fulgora"),
    ("fulgora", "ribbonia"),
    ("ribbonia", "asteroid-belt-inner-edge"),
    ("asteroid-belt-inner-edge", "asteroid-belt-outer-edge"),
    ("asteroid-belt-outer-edge", "paracelsin"),
    ("asteroid-belt-outer-edge", "sye-beetlejuice"),
)
LATERAL_BANDS = (
    (("sye-solaris", "sye-nyxaris"), 68000, 96000),
    (("sye-beetlejuice", "sye-umbra"), 124000, 176000),
)
CAMPAIGN_HUBS = {"sye-calidus", "sye-solaris", "sye-nyxaris",
                 "sye-vibrant", "sye-vespera", "sye-beetlejuice", "sye-umbra"}
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
    key("sye-solaris", "sye-vibrant"): 80000,
    key("sye-nyxaris", "sye-vespera"): 72000,
    key("sye-vespera", "sye-umbra"): 96000,
    key("sye-solaris", "sye-nyxaris"): 65000,
    key("sye-beetlejuice", "sye-umbra"): 120000,
    key("secretas", "solar-system-edge"): 100000,
    key("vesta", "solar-system-edge"): 120000,
    key("ribbonia", "asteroid-belt-inner-edge"): 16000,
    key("asteroid-belt-outer-edge", "paracelsin"): 11000,
    key("asteroid-belt-outer-edge", "sye-beetlejuice"): 65000,
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

BELT_ECOLOGY = (
    ("vibrant", "asteroid-belt-inner-edge", "asteroid-belt-outer-edge",
     "metallic-asteroid-chunk"),
    ("vespera", "razi-vespera-belt-inner", "razi-vespera-belt-outer",
     "oxide-asteroid-chunk"),
    ("umbra", "razi-umbra-belt-inner", "razi-umbra-belt-outer",
     "carbonic-asteroid-chunk"),
)


def belt_ecology_issues(raw, links):
    """Audit harvested material in a REAL post-load prototype dump.

    The light source-geometry fixture has no asteroid prototypes and skips
    these checks. No simulated route traffic or production is inferred.
    """
    if not obj(raw.get("asteroid-chunk")):
        return set()
    locations = obj(raw.get("space-location"))
    results = set()
    for system, inner, outer, specialty in BELT_ECOLOGY:
        if inner not in locations or outer not in locations:
            results.add(f"Missing {system} resource rim")
            continue
        for rim in (inner, outer):
            definitions = locations[rim].get("asteroid_spawn_definitions", [])
            available = {d.get("asteroid"): d for d in definitions
                         if isinstance(d, dict)}
            chunk = available.get(specialty)
            if not chunk or chunk.get("type") != "asteroid-chunk" or (
                    not isinstance(chunk.get("probability"), (int, float))
                    or chunk["probability"] <= 0):
                results.add(f"{system} rim lacks its expected {specialty} ore")
            if any(d.get("type") == "entity" and
                   isinstance(d.get("probability"), (int, float))
                   and d["probability"] > 0
                   for d in definitions if isinstance(d, dict)):
                results.add(f"Unsafe combat asteroid on {system} safe rim")
        matching = links.get(key(inner, outer), [])
        if len(matching) != 1:
            results.add(f"{system} belt should have one physical crossing")
            continue
        route = matching[0][1]
        definitions = route.get("asteroid_spawn_definitions", [])
        chunks = {d.get("asteroid"): d for d in definitions
                  if isinstance(d, dict) and d.get("type") == "asteroid-chunk"}
        native = chunks.get(specialty)
        if not native:
            results.add(f"{system} crossing lacks {specialty} seam")
            continue
        points = native.get("spawn_points", [])
        center = next((p.get("probability") for p in points
                       if isinstance(p, dict) and p.get("distance") == 0.5), None)
        entry = next((p.get("probability") for p in points
                      if isinstance(p, dict) and p.get("distance") == 0.05), None)
        if (not isinstance(center, (int, float)) or
                not isinstance(entry, (int, float)) or center <= entry):
            results.add(f"{system} crossing has no richer mid-belt ore seam")
    return results


def audit(raw):
    routes = obj(raw.get("space-connection"))
    coords = positions(raw)
    links = defaultdict(list)
    for name, route in routes.items():
        if isinstance(route, dict) and route.get("from") and route.get("to"):
            links[key(route["from"], route["to"])].append((name, route))
    issues = belt_ecology_issues(raw, links)
    for a, b in BELT_BYPASSES:
        if key(a, b) in links:
            issues.add(f"Unsafe belt bypass remains: {a} -> {b}")

    for a, b in CAMPAIGN_ROUTES + VIBRANT_BELT_ROUTES + DEEP_EDGES:
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

    # Precisely seven direct interstellar routes. Vibrant/Beetlejuice
    # must be bridged through the original 5000 km native asteroid crossing.
    managed={p for p in links if p[0] in CAMPAIGN_HUBS and p[1] in CAMPAIGN_HUBS}
    required={key(a,b) for a,b in CAMPAIGN_ROUTES}
    for pair in managed-required:
        issues.add(f"Unwanted cross-system route: {pair[0]} <-> {pair[1]}")
    for pair in required-managed:
        issues.add(f"Missing constellation corridor: {pair[0]} <-> {pair[1]}")
    for a,b in (
        ("sye-vibrant","sye-beetlejuice"),
        ("ribbonia","paracelsin"),
        ("paracelsin","asteroid-belt-inner-edge"),
    ):
        if key(a,b) in links:
            issues.add(f"Razi metallic belt physical bypass: {a} <-> {b}")
    native=links.get(key("asteroid-belt-inner-edge","asteroid-belt-outer-edge"))
    if native and native[0][1].get("length")!=5000:
        issues.add("Original native AsteroidBelt crossing changed")
    for (a,b),low,high in LATERAL_BANDS:
        match=links.get(key(a,b))
        if match and isinstance(match[0][1].get("length"),(int,float)):
            if not low<=match[0][1]["length"]<=high:
                issues.add(f"Lateral corridor distance mismatch: {a} <-> {b}")
    for index,strand in enumerate((
        (STARTER_BRANCHES[0],MIDDLE_BRANCHES[0]),
        (STARTER_BRANCHES[1],MIDDLE_BRANCHES[1],OUTER_BRANCHES[0]),
    ),start=1):
        if all(key(a,b) in links for a,b in strand):
            amounts=[links[key(a,b)][0][1].get("length") for a,b in strand]
            if not all(isinstance(n,(int,float)) for n in amounts):
                issues.add(f"Non-numeric distance in branch {index}")
            elif any(a>=b for a,b in zip(amounts,amounts[1:])):
                issues.add(f"Branch {index} distances not rising by chapter")
    journey=(
        ("sye-vibrant","fulgora"),
        ("fulgora","ribbonia"),
        ("ribbonia","asteroid-belt-inner-edge"),
        ("asteroid-belt-inner-edge","asteroid-belt-outer-edge"),
        ("asteroid-belt-outer-edge","sye-beetlejuice"),
    )
    if all(key(a,b) in links for a,b in journey):
        distance=sum(links[key(a,b)][0][1].get("length",0) for a,b in journey)
        middle=links.get(key("sye-solaris","sye-vibrant"))
        if middle and distance<=middle[0][1].get("length",0):
            issues.add("Native belt journey underpriced vs middle tier")
    first=links.get(key("sye-solaris","sye-nyxaris"))
    if first and all(key(a,b) in links for a,b in STARTER_BRANCHES):
        direct=first[0][1].get("length")
        via=sum(links[key(a,b)][0][1].get("length",0) for a,b in STARTER_BRANCHES)
        if isinstance(direct,(int,float)) and direct>=via:
            issues.add("Solaris/Nyxaris link longer than journey via Calidus")
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
        print("Seven star links, mandatory native Vibrant belt, and tier distances passed.")
    return int(bool(issues))

if __name__ == "__main__":
    raise SystemExit(main())
