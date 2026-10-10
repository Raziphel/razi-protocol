#!/usr/bin/env python3
"""Audit a Factorio --dump-data-raw snapshot for Razi Protocol progression regressions.

This consumes the real, post-mod data.raw JSON. It deliberately does not pretend
that static source parsing can model the full Factorio data-stage load order.
"""
import argparse
import json
from collections import deque
from pathlib import Path

SYSTEM_LOCATIONS = (
    "sye-calidus",
    "sye-solaris",
    "sye-nyxaris",
    "sye-vibrant",
    "sye-vespera",
    "sye-beetlejuice",
    "sye-umbra",
)
SYSTEM_CARDS = (
    "calidus-tech-card",
    "solaris-tech-card",
    "nyxaris-tech-card",
    "vibrant-tech-card",
    "vespera-tech-card",
    "beetlejuice-tech-card",
    "umbra-tech-card",
    "deep-space-tech-card",
)
OPTIONAL_PLANET_DESTINATIONS = {
    # Planet: (expected orbit parent, expected local route entry, chapter gate)
    "igrys": ("solaris", "sye-solaris", "solaris-discovery"),
    "rabbasca": ("gleba", "gleba", "planet-discovery-gleba"),
    "foliax": ("nyxaris", "sye-nyxaris", "nyxaris-discovery"),
    "obsidiax": ("vespera", "sye-vespera", "vespera-discovery"),
    "carna": ("umbra", "sye-umbra", "umbra-discovery"),
    "athos": ("solaris", "sye-solaris", "solaris-discovery"),
}

CAMPAIGN_TECHNOLOGIES = (
    "solaris-discovery",
    "nyxaris-discovery",
    "vibrant-discovery",
    "vespera-discovery",
    "beetlejuice-discovery",
    "umbra-discovery",
    "razi-outer-frontier-mastery",
    "razi-singularity-theory",
    "razi-singularity-test-fire",
    "razi-stable-intergalactic-singularity",
)


def sequence(value):
    """Factorio JSON sometimes represents empty Lua arrays as {}."""
    return value if isinstance(value, list) else []


def table(value):
    return value if isinstance(value, dict) else {}


def name_of(value):
    if isinstance(value, str):
        return value
    if isinstance(value, dict):
        return value.get("name")
    if isinstance(value, list) and value:
        return value[0]
    return None


def tech_ingredients(technology):
    unit = table(technology.get("unit"))
    return {name for ingredient in sequence(unit.get("ingredients"))
            if (name := name_of(ingredient))}


def reachable_locations(connections, starting_at):
    neighbors = {}
    for connection in connections.values():
        a, b = connection.get("from"), connection.get("to")
        if a and b:
            neighbors.setdefault(a, set()).add(b)
            neighbors.setdefault(b, set()).add(a)
    visited = {starting_at}
    queue = deque([starting_at])
    while queue:
        for neighbor in neighbors.get(queue.popleft(), ()):
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
    return visited


def audit(raw, extra_locations=(), check_campaign_routes=True):
    """Return a sorted collection of human-readable errors."""
    technologies = table(raw.get("technology"))
    recipes = table(raw.get("recipe"))
    tools = table(raw.get("tool"))
    labs = table(raw.get("lab"))
    connections = table(raw.get("space-connection"))
    locations = set(table(raw.get("planet"))) | set(table(raw.get("space-location")))
    errors = set()

    if not technologies or not locations:
        return ["Not a complete Factorio data.raw dump (technology or locations missing)"]

    # Missing prereqs and cycles, including cycles created by third-party mods.
    parents = {}
    for name, tech in technologies.items():
        prereqs = [p for p in sequence(tech.get("prerequisites")) if isinstance(p, str)]
        parents[name] = prereqs
        for prerequisite in prereqs:
            if prerequisite not in technologies:
                errors.add(f"Technology {name} requires missing {prerequisite}")

    state = {}
    path = []
    def visit(node):
        status = state.get(node, 0)
        if status == 2:
            return
        if status == 1:
            cycle = path[path.index(node):] + [node]
            errors.add("Research prerequisite cycle: " + " -> ".join(cycle))
            return
        state[node] = 1
        path.append(node)
        for parent in parents.get(node, ()):
            if parent in technologies:
                visit(parent)
        path.pop()
        state[node] = 2

    for name in technologies:
        if not state.get(name):
            visit(name)

    # Validate that Razi's own expensive research can be run in one lab. A
    # collection of labs accepting separate packs isn't sufficient.
    lab_inputs = [set(sequence(lab.get("inputs"))) for lab in labs.values()]
    for name in CAMPAIGN_TECHNOLOGIES:
        if name not in technologies:
            errors.add(f"Missing Razi campaign technology {name}")
            continue
        tech = technologies[name]
        required = tech_ingredients(tech)
        if not required and not tech.get("research_trigger"):
            errors.add(f"Campaign technology {name} has no science or research trigger")
        elif required and not any(required.issubset(inputs) for inputs in lab_inputs):
            errors.add(f"No single lab accepts all science for {name}: "
                       + ", ".join(sorted(required)))

    # Every milestone card must be craftable once its unlocking tech is
    # researched. The dump captures the final state after other mods patch it.
    unlocked = set()
    unlockers = {}
    for tech_name, tech in technologies.items():
        for effect in sequence(tech.get("effects")):
            if isinstance(effect, dict) and effect.get("type") == "unlock-recipe":
                recipe_name = effect.get("recipe")
                unlocked.add(recipe_name)
                unlockers.setdefault(recipe_name, set()).add(tech_name)

    def depends_on(technology_name, target):
        """Does technology_name require target, directly or transitively?"""
        visited = set()
        queue = list(parents.get(technology_name, ()))
        while queue:
            current = queue.pop()
            if current == target:
                return True
            if current in visited:
                continue
            visited.add(current)
            queue.extend(parents.get(current, ()))
        return False
    if check_campaign_routes:
        # A drawn route is not an unlock. Verify that the endpoint discovery
        # is owned by its chapter technology and cannot come from an earlier
        # independent technology provided by a dependency.
        systems = (
            ("solaris", ("solaris-discovery",)),
            ("nyxaris", ("nyxaris-discovery",)),
            ("vibrant", ("vibrant-discovery",)),
            ("vespera", ("vespera-discovery",)),
            ("beetlejuice", ("beetlejuice-discovery",)),
            ("umbra", ("umbra-discovery",)),
            ("calidus", ("solaris-discovery", "nyxaris-discovery")),
        )
        for system, legitimate in systems:
            location = "sye-" + system
            if location not in locations:
                continue
            discoverers = set()
            for name, technology in technologies.items():
                if any(isinstance(effect, dict) and
                       effect.get("type") == "unlock-space-location" and
                       effect.get("space_location") == location
                       for effect in sequence(technology.get("effects"))):
                    discoverers.add(name)
            for required in legitimate:
                if required in technologies and required not in discoverers:
                    errors.add(f"Shared or chapter travel hub {location} missing "
                               f"unlock from {required}")
            if system != "calidus":
                owner = legitimate[0]
                for other in discoverers - {owner}:
                    if not depends_on(other, owner):
                        errors.add(f"Premature unlock of {location} by {other} "
                                   f"(must follow {owner})")

        pair_gates = (
            ("vibrant-discovery", ("solaris-discovery", "nyxaris-discovery")),
            ("vespera-discovery", ("solaris-discovery", "nyxaris-discovery")),
            ("beetlejuice-discovery", ("vibrant-discovery", "vespera-discovery")),
            ("umbra-discovery", ("vibrant-discovery", "vespera-discovery")),
        )
        for destination, required in pair_gates:
            if destination in technologies:
                for predecessor in required:
                    if not depends_on(destination, predecessor):
                        errors.add(f"Premature {destination}: missing {predecessor} gate")
        if depends_on("solaris-discovery", "nyxaris-discovery") or \
                depends_on("nyxaris-discovery", "solaris-discovery"):
            errors.add("First-frontier systems are no longer independent")
        if "stellar-discovery-solar-system-edge" in technologies and not \
                depends_on("stellar-discovery-solar-system-edge",
                           "razi-outer-frontier-mastery"):
            errors.add("Deep Space exit bypasses Outer Frontier Mastery")

    for card in SYSTEM_CARDS:
        if card not in tools:
            errors.add(f"Missing system tech card item: {card}")
        recipe = recipes.get(card)
        if not recipe:
            errors.add(f"Missing system tech card recipe: {card}")
        elif recipe.get("enabled") is not True and card not in unlocked:
            errors.add(f"No technology unlocks system tech card recipe: {card}")

        # A tech consuming a card cannot be the only route to unlock that
        # card's recipe. This catches cross-mod softlocks missed by tech cycle
        # detection because recipe gates are not prerequisite edges.
        if recipe and recipe.get("enabled") is not True and unlockers.get(card):
            for consumer, technology in technologies.items():
                if card not in tech_ingredients(technology):
                    continue
                sources = unlockers[card]
                if all(unlocker == consumer or depends_on(unlocker, consumer)
                       for unlocker in sources):
                    errors.add(f"System card {card} cannot be made before "
                               f"{consumer} researches it (recipe unlock deadlock)")

    for route_name, route in connections.items():
        for endpoint in ("from", "to"):
            place = route.get(endpoint)
            if place not in locations:
                errors.add(f"Space route {route_name} has invalid {endpoint}: {place}")

    if check_campaign_routes:
        for location in SYSTEM_LOCATIONS:
            if location not in locations:
                errors.add(f"Missing campaign system location: {location}")

    required_locations = set(extra_locations)
    if check_campaign_routes:
        required_locations.update(SYSTEM_LOCATIONS)
    if required_locations:
        reachable = reachable_locations(connections, "nauvis")
        for location in sorted(required_locations):
            if location not in locations:
                errors.add(f"Required location does not exist: {location}")
            elif location not in reachable:
                errors.add(f"No space route from Nauvis to {location}")

    # Conditional validation: never demand an optional planet if its mod
    # is not installed. Validate its real post-load orbit/route/gate if present.
    planets = table(raw.get("planet"))
    for planet_name, (parent, entry, gate) in OPTIONAL_PLANET_DESTINATIONS.items():
        if planet_name not in planets:
            continue
        orbit = table(planets[planet_name].get("orbit"))
        observed_parent = table(orbit.get("parent")).get("name")
        if observed_parent != parent:
            errors.add(f"Optional planet {planet_name} orbits {observed_parent}, "
                       f"expected {parent}")
        has_route = any({route.get("from"), route.get("to")} == {planet_name, entry}
                        for route in connections.values())
        if not has_route:
            errors.add(f"Optional planet {planet_name} lacks route to {entry}")
        discoverers = [
            name for name, technology in technologies.items()
            if any(isinstance(effect, dict) and
                   effect.get("type") == "unlock-space-location" and
                   effect.get("space_location") == planet_name
                   for effect in sequence(technology.get("effects")))
        ]
        if not discoverers:
            errors.add(f"Optional planet {planet_name} has no native discovery research")
        elif not any(depends_on(name, gate) for name in discoverers):
            errors.add(f"Optional planet {planet_name} discovery lacks {gate} gate")

    return sorted(errors)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path, help="script-output/data-raw-dump.json")
    parser.add_argument("--required-location", action="append", default=[],
                        help="Also require this planet or space location to be reachable")
    parser.add_argument("--no-campaign-route-checks", action="store_true",
                        help="Skip Razi system reachability assertions")
    args = parser.parse_args()

    with args.dump.open(encoding="utf-8") as handle:
        raw = json.load(handle)
    raw = table(raw)
    # Accept both the normal top-level data.raw and wrapped fixtures.
    if "raw" in raw and isinstance(raw["raw"], dict):
        raw = raw["raw"]

    errors = audit(raw, args.required_location, not args.no_campaign_route_checks)
    if errors:
        print(f"Razi Protocol audit failed with {len(errors)} issue(s):")
        for issue in errors:
            print(f"  - {issue}")
        return 1
    print("Razi Protocol audit passed: research graph, system cards, labs and starmap routes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
