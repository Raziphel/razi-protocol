#!/usr/bin/env python3
"""Trace K2SO and planetary ingredient supply at key seven-system milestones.

Uses real Factorio 2.1 --dump-data-raw output. This is an advisory analyzer:
a possible recipe path does not prove its resources or transport are available
on the chosen planet. Never auto-remove a surface or research restriction.
"""
import argparse
import json
from collections import defaultdict
from pathlib import Path

MILESTONES = {
    "Panglia": ("panglia_planet_discovery_panglia", (
        "datacell-raw-data", "panglia_panglite_glass")),
    "Aquilo": ("planet-discovery-aquilo", (
        "cryogenic-science-pack", "kr-cryogenic-research-data",
        "kr-matter-research-data", "kr-quantum-computer")),
    "Linox": ("linox-technology_planet-discovery-linox", (
        "linox-item_lava-data-card", "linox-item_linox-science-pack",
        "kr-ai-core")),
    "Crucible": ("planet-discovery-crucible", (
        "planet-crucible-science-pack", "kr-high-pressure-tech-card",
        "metallic-hydrogen")),
    "Vesta": ("planet-discovery-vesta", (
        "gas-manipulation-science-pack", "kr-hydrogen", "kr-ammonia")),
    "Outer frontier": ("razi-outer-frontier-mastery", (
        "beetlejuice-tech-card", "umbra-tech-card",
        "kr-singularity-tech-card"))
}
CARD_NAMES = (
    "calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card",
    "vibrant-tech-card", "vespera-tech-card", "beetlejuice-tech-card",
    "umbra-tech-card", "deep-space-tech-card"
)
ENTITY_FAMILIES = ("resource", "simple-entity", "simple-entity-with-owner",
                   "tree", "fish", "asteroid")
MACHINE_FAMILIES = ("assembling-machine", "furnace", "rocket-silo")

def obj(value):
    return value if isinstance(value, dict) else {}

def seq(value):
    return value if isinstance(value, list) else []

def name_of(entry):
    if isinstance(entry, str):
        return entry
    if isinstance(entry, list) and entry:
        return entry[0]
    if isinstance(entry, dict):
        return entry.get("name")
    return None

def recipe_variants(recipe):
    yield recipe
    for key in ("normal", "expensive"):
        variant = obj(recipe.get(key))
        if variant:
            yield variant

def output_names(recipe):
    output = set()
    for variant in recipe_variants(recipe):
        if variant.get("result"):
            output.add(variant["result"])
        for product in seq(variant.get("results")):
            if name_of(product) and (
                    not isinstance(product, dict)
                    or product.get("probability", 1) > 0):
                output.add(name_of(product))
    return output

def input_names(recipe):
    return sorted({name for variant in recipe_variants(recipe)
                   for ingredient in seq(variant.get("ingredients"))
                   if (name := name_of(ingredient))})

def science_names(tech):
    return sorted({name for entry in seq(obj(tech.get("unit")).get("ingredients"))
                   if (name := name_of(entry))})

def technology_ancestors(technologies, goal):
    seen = set()
    pending = list(seq(obj(technologies.get(goal)).get("prerequisites")))
    while pending:
        name = pending.pop()
        if name in seen or name not in technologies:
            continue
        seen.add(name)
        pending.extend(seq(obj(technologies[name]).get("prerequisites")))
    return seen

def surface_allowed(prototype, properties):
    """True, False, or None when the dump lacks a needed surface property."""
    unknown = False
    for limit in seq(prototype.get("surface_conditions")):
        if not isinstance(limit, dict):
            continue
        value = properties.get(limit.get("property"))
        if not isinstance(value, (int, float)):
            unknown = True
            continue
        if limit.get("min") is not None and value < limit["min"]:
            return False
        if limit.get("max") is not None and value > limit["max"]:
            return False
    return None if unknown else True

class SupplyTrace:
    def __init__(self, raw):
        self.raw = raw
        self.technologies = obj(raw.get("technology"))
        self.recipes = obj(raw.get("recipe"))
        self.worlds = {**obj(raw.get("planet")), **obj(raw.get("space-location"))}
        self.producers = defaultdict(list)
        self.unlockers = defaultdict(set)
        self.natural = set()

        for name, recipe in self.recipes.items():
            if isinstance(recipe, dict):
                for product in output_names(recipe):
                    self.producers[product].append(name)
        for name, tech in self.technologies.items():
            for effect in seq(obj(tech).get("effects")):
                if isinstance(effect, dict) and effect.get("type") == "unlock-recipe":
                    self.unlockers[effect.get("recipe")].add(name)
        for family in ENTITY_FAMILIES:
            for entity in obj(raw.get(family)).values():
                minable = obj(obj(entity).get("minable"))
                if minable.get("result"):
                    self.natural.add(minable["result"])
                for product in seq(minable.get("results")):
                    if name_of(product):
                        self.natural.add(name_of(product))
        for pump in obj(raw.get("offshore-pump")).values():
            if isinstance(pump, dict) and pump.get("fluid"):
                self.natural.add(pump["fluid"])
        self.machines = [
            machine for family in MACHINE_FAMILIES
            for machine in obj(raw.get(family)).values()
            if isinstance(machine, dict)]

    def known_worlds(self, researched):
        places = {"nauvis"} if "nauvis" in self.worlds else set()
        for technology_name in researched:
            tech = obj(self.technologies.get(technology_name))
            for effect in seq(tech.get("effects")):
                if (isinstance(effect, dict)
                        and effect.get("type") == "unlock-space-location"):
                    location = effect.get("space_location")
                    if location in self.worlds:
                        places.add(location)
        return places

    def recipe_unlock_status(self, name, recipe, researched, goal):
        if recipe.get("enabled") is not False:
            return "ready"
        if self.unlockers[name].intersection(researched):
            return "ready"
        unlockers = self.unlockers[name]
        if not unlockers:
            return "no-unlocker"
        # No prerequisite ancestry means an independent research branch may
        # still unlock this producer. It is not proof of an impossible recipe.
        if goal and all(unlocker == goal or
                        goal in technology_ancestors(self.technologies, unlocker)
                        for unlocker in unlockers):
            return "future-unlock"
        return "independent-research"

    def recipe_locations(self, recipe, places):
        if not seq(recipe.get("surface_conditions")):
            return True
        if not places:
            return None
        uncertain = False
        for place in places:
            properties = obj(obj(self.worlds.get(place)).get("surface_properties"))
            if not properties:
                uncertain = True
            else:
                allowed = surface_allowed(recipe, properties)
                if allowed is True:
                    return True
                if allowed is None:
                    uncertain = True
        return None if uncertain else False

    def category_machines(self, recipe, places):
        categories = set(seq(recipe.get("categories")))
        if not categories:
            categories = {recipe.get("category") or "crafting"}
        if categories == {"crafting"}:
            return True  # Hand crafting can satisfy some basic intermediates.
        matching = False
        uncertain = False
        for machine in self.machines:
            if not categories.intersection(seq(machine.get("crafting_categories"))):
                continue
            if machine.get("fixed_recipe"):
                continue
            matching = True
            for place in places:
                properties = obj(obj(self.worlds.get(place)).get("surface_properties"))
                if not properties:
                    uncertain = True
                else:
                    allowed = surface_allowed(machine, properties)
                    if allowed is True:
                        return True
                    if allowed is None:
                        uncertain = True
        if not matching:
            return False
        return None if uncertain or not places else False

    def trace(self, name, researched, places, trail=(), depth=0, goal=None):
        if name in trail:
            return {"item": name, "status": "cycle", "path": list(trail) + [name]}
        if name in self.natural:
            return {"item": name, "status": "natural-source-unverified"}
        if depth >= 7:
            return {"item": name, "status": "depth-limit"}
        candidates = []
        for recipe_name in self.producers.get(name, ()):
            recipe = self.recipes[recipe_name]
            unlock_state = self.recipe_unlock_status(
                recipe_name, recipe, researched, goal)
            if unlock_state != "ready":
                unlocks = sorted(self.unlockers.get(recipe_name, ()))
                candidates.append({"recipe": recipe_name, "status": unlock_state,
                                   "unlockers": unlocks})
                continue
            surface = self.recipe_locations(recipe, places)
            if surface is False:
                candidates.append({"recipe": recipe_name,
                                   "status": "surface-excluded"})
                continue
            machine = self.category_machines(recipe, places)
            if machine is False:
                candidates.append({"recipe": recipe_name,
                                   "status": "no-machine"})
                continue
            children = [self.trace(item, researched, places,
                                   trail + (name,), depth + 1, goal)
                        for item in input_names(recipe) if item != name]
            if name in input_names(recipe):
                children.append({"item": name, "status": "cycle",
                                 "path": list(trail) + [name, name]})
            statuses = {child["status"] for child in children}
            if "blocked" in statuses or "cycle" in statuses:
                status = "blocked"
            elif ("future-unlock" in statuses or "no-unlocker" in statuses
                  or "surface-excluded" in statuses or "no-machine" in statuses):
                status = "blocked"
            elif ("independent-research" in statuses or "unverified" in statuses
                  or "depth-limit" in statuses or "unresolved" in statuses):
                status = "unverified"
            elif surface is None or machine is None:
                status = "unverified"
            else:
                status = "traceable"
            candidates.append({"recipe": recipe_name,
                               "status": status, "inputs": children})
        if not candidates:
            return {"item": name, "status": "unresolved",
                    "reason": "No recipe or mineable source in loaded prototypes"}
        preference = {"traceable": 0, "unverified": 1,
                      "independent-research": 2, "blocked": 3,
                      "future-unlock": 4, "no-unlocker": 5,
                      "no-machine": 6, "surface-excluded": 7}
        best = min(candidates, key=lambda c: (
            preference.get(c["status"], 6), len(c.get("inputs", ()))))
        status = best["status"]
        if status in ("future-unlock", "no-unlocker", "no-machine",
                      "surface-excluded"):
            status = "blocked"
        elif status == "independent-research":
            status = "unverified"
        return {"item": name, "status": status,
                "best": best, "producer_count": len(candidates)}

    def audit_planets(self):
        """All installed planets, not just the handful of known risky worlds.

        Alternative discoverers are checked separately. An uncertain recipe
        branch is not enough to declare a world impossible to reach.
        """
        unlocks = defaultdict(list)
        for name, tech in self.technologies.items():
            if not isinstance(tech, dict) or tech.get("hidden") is True \
                    or tech.get("enabled") is False:
                continue
            for effect in seq(tech.get("effects")):
                if isinstance(effect, dict) and effect.get("type") == "unlock-space-location":
                    world = effect.get("space_location")
                    if world in obj(self.raw.get("planet")):
                        unlocks[world].append(name)

        reports = {}
        for world in sorted(obj(self.raw.get("planet"))):
            if world == "nauvis":
                continue
            options = []
            for name in sorted(set(unlocks.get(world, ()))):
                tech = self.technologies[name]
                before = technology_ancestors(self.technologies, name)
                known = self.known_worlds(before)
                science = [self.trace(pack, before, known, goal=name)
                           for pack in science_names(tech)]
                states = {node["status"] for node in science}
                if "blocked" in states or "cycle" in states:
                    status = "blocked"
                elif states.intersection({"unverified", "depth-limit", "unresolved"}):
                    status = "unverified"
                elif not science:
                    status = "trigger-or-scripted" if tech.get("research_trigger") \
                        else "no-science"
                else:
                    status = "traceable"
                options.append({"technology": name, "status": status,
                                "science": science,
                                "prearrival_worlds": sorted(known)})
            if not options:
                state = "no-visible-native-unlock"
            elif all(choice["status"] == "blocked" for choice in options):
                state = "blocked"
            elif any(choice["status"] == "traceable" for choice in options):
                state = "traceable"
            else:
                state = "unverified"
            reports[world] = {
                "status": state, "unlockers": options,
                "note": "Supply is inferred. Native routes, scripted unlocks, "
                        "surface mining and transport require an in-game check."
            }
        return reports

    def analyze(self):
        report = {}
        known = set(obj(self.raw.get("item"))) | set(obj(self.raw.get("tool")))
        known |= set(obj(self.raw.get("fluid"))) | set(self.producers)
        for label, (goal, focus) in MILESTONES.items():
            if goal not in self.technologies:
                continue
            before = technology_ancestors(self.technologies, goal)
            after = before | {goal}
            before_places = self.known_worlds(before)
            after_places = self.known_worlds(after)
            tech = self.technologies[goal]
            report[label] = {
                "discovery": goal,
                "before_discovery_science": [
                    self.trace(item, before, before_places, goal=goal)
                    for item in science_names(tech)],
                "after_discovery_production": [
                    self.trace(item, after, after_places, goal=goal)
                    for item in focus if item in known],
                "reachable_location_prototypes": sorted(after_places),
                "caveat": ("Sources and machines inferred from prototypes; "
                           "natural resources, power, transport, scripted "
                           "unlocks and world exploration not proven.")
            }
        return report

def summarize(report):
    for label, result in report.items():
        print(f"\n{label}  [{result['discovery']}]")
        for section in ("before_discovery_science", "after_discovery_production"):
            print("  " + section.replace("_", " ") + ":")
            for node in result[section]:
                print(f"    {node['status']}: {node['item']}")
                best = node.get("best", {})
                if best.get("status") in ("future-unlock", "no-unlocker",
                                          "independent-research",
                                          "surface-excluded", "no-machine"):
                    print(f"       {best['recipe']}: {best['status']}")
        print("  Note: possible chains require an in-game supply/transport check.")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path,
                        help="Factorio script-output/data-raw-dump.json")
    parser.add_argument("--json", action="store_true",
                        help="Emit nested recipe chains as JSON")
    parser.add_argument("--all-worlds", action="store_true",
                        help="Also audit all installed planet discoveries")
    parser.add_argument("--strict", action="store_true",
                        help="Exit nonzero for definite blocked discovery chains "
                             "(requires --all-worlds)")
    args = parser.parse_args()
    if args.strict and not args.all_worlds:
        parser.error("--strict requires --all-worlds")
    with args.dump.open(encoding="utf-8") as f:
        raw = json.load(f)
    raw = obj(raw)
    if isinstance(raw.get("raw"), dict):
        raw = raw["raw"]
    if not obj(raw.get("recipe")) or not obj(raw.get("technology")):
        parser.error("Full Factorio post-load recipe/technology tables are required")
    tracer = SupplyTrace(raw)
    results = tracer.analyze()
    planets = tracer.audit_planets() if args.all_worlds else {}
    if args.json:
        payload = {"milestones": results, "planets": planets} \
            if args.all_worlds else results
        print(json.dumps(payload, indent=2))
    else:
        summarize(results)
        if args.all_worlds:
            print(f"\\nPlanet research sweep: {len(planets)} installed worlds")
            for name, entry in planets.items():
                owners = ", ".join(choice["technology"]
                                   for choice in entry["unlockers"])
                print(f"  {entry['status']}: {name}" +
                      (f"  ({owners})" if owners else "  (no visible unlock)"))
    blocked = [name for name, entry in planets.items()
               if entry["status"] == "blocked"]
    if args.strict and blocked:
        print(f"Blocked planet research detected: {', '.join(blocked)}")
        return 1
    return 0  # An unverified path alone must not block a release.

if __name__ == "__main__":
    raise SystemExit(main())
