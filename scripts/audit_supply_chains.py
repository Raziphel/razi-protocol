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
    for limit in seq(prototype.get("surface_conditions")):
        if not isinstance(limit, dict):
            continue
        value = properties.get(limit.get("property"))
        if not isinstance(value, (int, float)):
            continue
        if limit.get("min") is not None and value < limit["min"]:
            return False
        if limit.get("max") is not None and value > limit["max"]:
            return False
    return True

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

    def recipe_available(self, name, recipe, researched):
        if recipe.get("enabled") is not False:
            return True
        return bool(self.unlockers[name].intersection(researched))

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
            elif surface_allowed(recipe, properties):
                return True
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
                elif surface_allowed(machine, properties):
                    return True
        if not matching:
            return False
        return None if uncertain or not places else False

    def trace(self, name, researched, places, trail=(), depth=0):
        if name in trail:
            return {"item": name, "status": "cycle", "path": list(trail) + [name]}
        if name in self.natural:
            return {"item": name, "status": "natural-source-unverified"}
        if depth >= 7:
            return {"item": name, "status": "depth-limit"}
        candidates = []
        for recipe_name in self.producers.get(name, ()):
            recipe = self.recipes[recipe_name]
            if not self.recipe_available(recipe_name, recipe, researched):
                unlocks = sorted(self.unlockers.get(recipe_name, ()))
                candidates.append({"recipe": recipe_name, "status": "locked",
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
                                   trail + (name,), depth + 1)
                        for item in input_names(recipe) if item != name]
            if name in input_names(recipe):
                children.append({"item": name, "status": "cycle",
                                 "path": list(trail) + [name, name]})
            statuses = {child["status"] for child in children}
            if "blocked" in statuses or "cycle" in statuses:
                status = "blocked"
            elif "locked" in statuses or "surface-excluded" in statuses or "no-machine" in statuses:
                status = "blocked"
            elif "depth-limit" in statuses or "unresolved" in statuses:
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
        preference = {"traceable": 0, "unverified": 1, "blocked": 2,
                      "locked": 3, "no-machine": 4, "surface-excluded": 5}
        best = min(candidates, key=lambda c: (
            preference.get(c["status"], 6), len(c.get("inputs", ()))))
        status = best["status"]
        if status in ("locked", "no-machine", "surface-excluded"):
            status = "blocked"
        return {"item": name, "status": status,
                "best": best, "producer_count": len(candidates)}

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
                    self.trace(item, before, before_places)
                    for item in science_names(tech)],
                "after_discovery_production": [
                    self.trace(item, after, after_places)
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
                if best.get("status") in ("locked", "surface-excluded", "no-machine"):
                    print(f"       {best['recipe']}: {best['status']}")
        print("  Note: possible chains require an in-game supply/transport check.")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path,
                        help="Factorio script-output/data-raw-dump.json")
    parser.add_argument("--json", action="store_true",
                        help="Emit nested recipe chains as JSON")
    args = parser.parse_args()
    with args.dump.open(encoding="utf-8") as f:
        raw = json.load(f)
    raw = obj(raw)
    if isinstance(raw.get("raw"), dict):
        raw = raw["raw"]
    if not obj(raw.get("recipe")) or not obj(raw.get("technology")):
        parser.error("Full Factorio post-load recipe/technology tables are required")
    results = SupplyTrace(raw).analyze()
    if args.json:
        print(json.dumps(results, indent=2))
    else:
        summarize(results)
    return 0  # Advisory; never claim a partial chain proves engine failure.

if __name__ == "__main__":
    raise SystemExit(main())
