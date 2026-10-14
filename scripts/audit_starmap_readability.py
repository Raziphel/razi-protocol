#!/usr/bin/env python3
"""Static starmap geometry report for the hand-authored Razi seven-system ring.

Run manually: python scripts/audit_starmap_readability.py
Only Razi's explicitly listed Lua anchors and corridor manifest are inspected.
Curved Factorio 2.1 arcs, source mods, screen labels and actual zoom can differ.
No images are changed, and no client/Factorio process is needed.
"""
from __future__ import annotations
from collections import defaultdict
from pathlib import Path
import argparse
import json
import math
import re

ROOT = Path(__file__).resolve().parents[1]
ANCHOR = re.compile(
    r'\{"(space-location|planet)","([^"]+)","([^"]+)",([0-9.]+),([0-9.]+)\}'
)
ROUTE = re.compile(
    r'\{"([^"]+)", "([^"]+)", ([0-9]+), "([^"]+)"\}'
)
OPTIONAL = re.compile(
    r'\{name="([^"]+)",star="([^"]+)",radius=([0-9.]+),turn=([0-9.]+)\}'
)
BELTS = {
    "razi-vespera-belt-inner", "razi-vespera-belt-outer",
    "razi-umbra-belt-inner", "razi-umbra-belt-outer",
}
SYSTEMS = ("solaris", "nyxaris", "vibrant", "vespera", "beetlejuice", "umbra")


def load(root: Path = ROOT):
    layout = (root / "prototypes/system/galaxy_layout.lua").read_text()
    routes = (root / "prototypes/system/route_reconcile.lua").read_text()
    anchors = [
        dict(kind=m[1], name=m[2], parent=m[3], radius=float(m[4]),
             orientation=float(m[5]))
        for m in ANCHOR.finditer(layout)
    ]
    # Optional locations use keyed Lua entries. Include them in geometry
    # checks so their side routes cannot slip between the chart markers.
    anchors.extend(
        dict(kind="planet", name=m[1], parent=m[2], radius=float(m[3]),
             orientation=float(m[4]))
        for m in OPTIONAL.finditer(layout)
    )
    edges = [
        dict(source=m[1], destination=m[2], distance=int(m[3]), profile=m[4])
        for m in ROUTE.finditer(routes)
    ]
    return anchors, edges


def positions(anchors):
    coords = {"star": (0.0, 0.0)}
    unresolved = list(anchors)
    for _ in range(len(anchors) + 1):
        remaining = []
        for anchor in unresolved:
            if anchor["parent"] not in coords:
                remaining.append(anchor)
                continue
            px, py = coords[anchor["parent"]]
            theta = 2 * math.pi * anchor["orientation"]
            coords[anchor["name"]] = (
                px + anchor["radius"] * math.sin(theta),
                py - anchor["radius"] * math.cos(theta),
            )
        if not remaining:
            break
        if len(remaining) == len(unresolved):
            raise ValueError("Unknown parent or orbit cycle: " + repr(remaining))
        unresolved = remaining
    return coords


def distance(a, b):
    return math.dist(a, b)


def chord_clearance(point, start, end):
    dx, dy = end[0] - start[0], end[1] - start[1]
    size = dx * dx + dy * dy
    if not size:
        return math.inf
    t = ((point[0] - start[0]) * dx +
         (point[1] - start[1]) * dy) / size
    if not 0.05 < t < 0.95:
        return math.inf
    return distance(point, (start[0] + t * dx, start[1] + t * dy))


def segments_cross(a, b, c, d):
    def side(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (
            q[1] - p[1]) * (r[0] - p[0])
    return side(a, b, c) * side(a, b, d) < 0 and (
        side(c, d, a) * side(c, d, b) < 0
    )


def report(anchors, routes):
    coords = positions(anchors)
    grouped = defaultdict(list)
    for anchor in anchors:
        if anchor["parent"] in SYSTEMS:
            grouped[anchor["parent"]].append(anchor)
    output = {}
    for system in SYSTEMS:
        points = grouped[system]
        names = {point["name"] for point in points}
        local_routes = [
            route for route in routes
            if route["source"] in names and route["destination"] in names
        ]
        short, rings, near, crossing = [], [], [], []
        for i, left in enumerate(points):
            for right in points[i + 1:]:
                a, b = left["name"], right["name"]
                sep = distance(coords[a], coords[b])
                if sep < 18:
                    short.append(dict(a=a, b=b, units=round(sep, 1),
                                      belt_waypoints=a in BELTS and b in BELTS))
                if (left["kind"] == "planet" or right["kind"] == "planet") and (
                    abs(left["radius"] - right["radius"]) < 3
                ):
                    rings.append(dict(a=a, b=b, radial_gap=round(abs(
                        left["radius"] - right["radius"]), 1)))
        for route in local_routes:
            a, b = route["source"], route["destination"]
            for point in points:
                name = point["name"]
                if name in (a, b):
                    continue
                gap = chord_clearance(coords[name], coords[a], coords[b])
                if gap < 7:
                    near.append(dict(a=a, b=b, near=name, gap=round(gap, 1)))
        for i, first in enumerate(local_routes):
            for second in local_routes[i + 1:]:
                ends = (first["source"], first["destination"],
                        second["source"], second["destination"])
                if len(set(ends)) != 4:
                    continue
                if segments_cross(*(coords[name] for name in ends)):
                    crossing.append(dict(
                        a=first["source"] + " / " + first["destination"],
                        b=second["source"] + " / " + second["destination"],
                    ))
        output[system] = dict(
            locations=len(points), routes=len(local_routes),
            close_markers=short, close_orbit_rings=rings,
            near_chords=near, crossing_chords=crossing,
        )
    output["belt_separation"] = {
        name: round(distance(coords[name + "-inner"], coords[name + "-outer"]), 1)
        for name in ("razi-vespera-belt", "razi-umbra-belt")
    }
    output["note"] = (
        "Chord warnings are approximate: Factorio draws curved local "
        "connections, and this report does not measure screen text."
    )
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true",
                        help="Emit structured report for a dev comparison")
    opts = parser.parse_args()
    result = report(*load())
    if opts.json:
        print(json.dumps(result, indent=2, sort_keys=True))
        return
    for system in SYSTEMS:
        data = result[system]
        print(f"{system.upper()}: {data['locations']} locations, "
              f"{data['routes']} managed local routes; "
              f"{len(data['close_markers'])} nearby pairs, "
              f"{len(data['close_orbit_rings'])} similar orbit bands, "
              f"{len(data['near_chords'])} near-chord notes, "
              f"{len(data['crossing_chords'])} crossing-chord notes")
        for row in data["crossing_chords"]:
            print(f"  potential chord crossing: {row['a']} x {row['b']}")
    for name, gap in result["belt_separation"].items():
        print(f"{name}: inner/outer {gap} chart units")
    print(result["note"])


if __name__ == "__main__":
    main()
