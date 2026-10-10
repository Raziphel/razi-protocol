#!/usr/bin/env python3
"""Audit cross-mod recipe, recycling, research-trigger and surface compatibility.

Consumes the actual Factorio 2.1 --dump-data-raw JSON. Reports warnings for
heuristic findings; hard errors are reserved for demonstrably missing Razi
card ingredients/products or obsolete, unproducible research trigger targets.

No recipe is changed automatically. This report helps review Alex's and
upstream fixes before making narrow, version-guarded patches.
"""
import argparse
import json
from pathlib import Path

CARDS = (
    "calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card",
    "vibrant-tech-card", "vespera-tech-card",
    "beetlejuice-tech-card", "umbra-tech-card", "deep-space-tech-card",
)
ITEM_TYPES = (
    "item", "tool", "module", "ammo", "capsule", "gun", "armor",
    "item-with-entity-data", "item-with-label", "item-with-tags",
    "rail-planner", "space-platform-starter-pack", "repair-tool",
)
K2SO_RENAMES = (
    "oxygen", "hydrogen", "chlorine", "sand", "glass", "silicon",
    "lithium", "ammonia",
)
# All category assignments are intentionally limited to native-machine parity.
# Exclusive planet-specific recipe categories must never be granted globally.
K2SO_MACHINE_PARITY = (
    ("kr-advanced-assembling-machine", "assembling-machine-3", "crafting",
     ("crafting", "advanced-crafting", "crafting-with-fluid")),
    ("kr-advanced-chemical-plant", "chemical-plant", "chemistry",
     ("chemistry", "chemistry-or-cryogenics")),
    ("kr-advanced-furnace", "foundry", "metallurgy", ("metallurgy",)),
)
K2SO_CARD_BRIDGES = (
    ("solaris-tech-card", "kr-metallurgic-research-data", "vulcanus"),
    ("nyxaris-tech-card", "kr-agricultural-research-data", "gleba"),
    ("vibrant-tech-card", "kr-electromagnetic-research-data", "fulgora"),
    ("vespera-tech-card", "kr-cryogenic-research-data", "aquilo"),
    ("beetlejuice-tech-card", "kr-matter-research-data", "aquilo"),
    ("umbra-tech-card", "kr-matter-research-data", "aquilo"),
    ("deep-space-tech-card", "kr-promethium-research-data", "shattered-planet"),
)

def obj(value):
    return value if isinstance(value, dict) else {}

def seq(value):
    return value if isinstance(value, list) else []

def name_of(value):
    if isinstance(value, dict):
        return value.get("name")
    if isinstance(value, str):
        return value
    if isinstance(value, list) and value:
        return value[0]
    return None

def recipe_products(recipe):
    """Only actual final recipe variants, including legacy fork metadata."""
    sources = [recipe]
    sources.extend(obj(recipe.get(key)) for key in ("normal", "expensive"))
    output = set()
    for source in sources:
        if source.get("result"):
            output.add(source["result"])
        for result in seq(source.get("results")):
            name = name_of(result)
            if name:
                output.add(name)
    return output

def crafting_categories(recipe):
    """Use final Factorio 2.1 categories, with a guarded legacy fallback."""
    categories = recipe.get("categories")
    if isinstance(categories, list):
        return set(categories)
    return {recipe.get("category") or "crafting"}


def fluid_interfaces(machine):
    """Count usable input/output fluid boxes, excluding nonproduction metadata."""
    inputs = outputs = 0
    for box in seq(machine.get("fluid_boxes")):
        if not isinstance(box, dict):
            continue
        direction = box.get("production_type")
        if direction in ("input", "input-output"):
            inputs += 1
        if direction in ("output", "input-output"):
            outputs += 1
    return inputs, outputs


def matches_known_surface(prototype, surface_properties):
    """Reject only explicitly contradictory planet/machine requirements."""
    for condition in seq(prototype.get("surface_conditions")):
        if not isinstance(condition, dict):
            continue
        value = surface_properties.get(condition.get("property"))
        if not isinstance(value, (int, float)):
            continue
        minimum, maximum = condition.get("min"), condition.get("max")
        if ((minimum is not None and value < minimum)
                or (maximum is not None and value > maximum)):
            return False
    return True


def can_craft_with_machine(recipe, machine):
    if not isinstance(machine, dict):
        return False
    if not crafting_categories(recipe).intersection(
            seq(machine.get("crafting_categories"))):
        return False
    fixed_recipe = machine.get("fixed_recipe")
    if fixed_recipe:
        # A fixed-recipe machine is not generally available to other science.
        return False
    # Fluid boxes are required for each distinct input/output fluid. This
    # intentionally ignores connections and placement direction, which need
    # in-engine testing.
    fluid_inputs = {name_of(x) for x in seq(recipe.get("ingredients"))
                    if isinstance(x, dict) and x.get("type") == "fluid"}
    fluid_outputs = {name_of(x) for x in seq(recipe.get("results"))
                     if isinstance(x, dict) and x.get("type") == "fluid"}
    inputs, outputs = fluid_interfaces(machine)
    return inputs >= len(fluid_inputs) and outputs >= len(fluid_outputs)


def audit_k2so_planet_machinery(raw, recipes, items, planets, warnings):
    """Spot lost standard machine recipes or K2SO data with no production path."""
    assemblers = obj(raw.get("assembling-machine"))
    machines = [*assemblers.values(), *obj(raw.get("furnace")).values()]
    possible = set()
    for machine in machines:
        if isinstance(machine, dict):
            possible.update(seq(machine.get("crafting_categories")))

    for upgraded_name, native_name, anchor, categories in K2SO_MACHINE_PARITY:
        upgraded = obj(assemblers.get(upgraded_name))
        native = obj(assemblers.get(native_name))
        if not upgraded or not native:
            continue
        native_categories = set(seq(native.get("crafting_categories")))
        upgraded_categories = set(seq(upgraded.get("crafting_categories")))
        if anchor not in upgraded_categories:
            continue  # Another mod fundamentally changed the machine's identity.
        native_inputs, native_outputs = fluid_interfaces(native)
        upgrade_inputs, upgrade_outputs = fluid_interfaces(upgraded)
        if (upgrade_inputs < native_inputs or upgrade_outputs < native_outputs):
            warnings.add(
                f"K2SO machine {upgraded_name} lacks the fluid connections of "
                f"its standard counterpart {native_name}"
            )
            continue
        for category in categories:
            if category in native_categories and category not in upgraded_categories:
                warnings.add(
                    f"K2SO machine {upgraded_name} cannot craft native "
                    f"{native_name} category {category}"
                )

    locations = set(planets) | set(obj(raw.get("space-location")))
    for card, research_data, world in K2SO_CARD_BRIDGES:
        card_recipe = obj(recipes.get(card))
        data_recipe = obj(recipes.get(research_data))
        # K2SO can be missing entirely, and source-mod data may not exist.
        if (not card_recipe or research_data not in items
                or world not in locations or not data_recipe
                or research_data not in recipe_products(data_recipe)):
            continue
        if research_data not in {name_of(item)
                                 for item in seq(card_recipe.get("ingredients"))}:
            warnings.add(
                f"K2SO system-card research link absent: {card} should consume "
                f"{research_data} from {world}"
            )
        categories = crafting_categories(data_recipe)
        if not possible.intersection(categories):
            warnings.add(
                f"K2SO research data {research_data} has no compatible "
                f"crafting machine for {', '.join(sorted(categories))}"
            )

        # A global category match can still be unusable on the home planet:
        # all suitable machines may be excluded by the surface properties.
        # Only reject conditions when both sides declare comparable values.
        planet = obj(planets.get(world))
        properties = obj(planet.get("surface_properties"))
        if planet and properties:
            candidates = [machine for machine in machines
                          if can_craft_with_machine(data_recipe, machine)]
            if candidates and not any(
                    matches_known_surface(machine, properties)
                    for machine in candidates):
                warnings.add(
                    f"K2SO research data {research_data} has no suitable "
                    f"crafting machine permitted on {world}"
                )
        for condition in seq(data_recipe.get("surface_conditions")):
            if not isinstance(condition, dict):
                continue
            property_name = condition.get("property")
            value = properties.get(property_name)
            if not isinstance(value, (int, float)):
                continue
            minimum, maximum = condition.get("min"), condition.get("max")
            if ((minimum is not None and value < minimum)
                    or (maximum is not None and value > maximum)):
                warnings.add(
                    f"K2SO research data {research_data} excludes source "
                    f"planet {world} by {property_name}={value}"
                )


def audit_k2so_stale_materials(raw, recipes, warnings):
    """Find hidden old K2SO aliases in final planetary production outputs."""
    substitutions = {}
    for kind in ("item", "fluid"):
        prototypes = obj(raw.get(kind))
        for original in K2SO_RENAMES:
            hidden = obj(prototypes.get(original))
            canonical = obj(prototypes.get("kr-" + original))
            if hidden.get("hidden") is True and canonical and not canonical.get("hidden"):
                substitutions[(kind, original)] = "kr-" + original
    if not substitutions:
        return

    def check(name, kind, context):
        replacement = substitutions.get((kind, name))
        if replacement:
            warnings.add(f"K2SO stale {kind} {name} in {context}: use {replacement}")

    def entries(values, context):
        for value in seq(values):
            name = name_of(value)
            if name:
                kind = value.get("type", "item") if isinstance(value, dict) else "item"
                check(name, kind, context)

    for name, recipe in recipes.items():
        if not isinstance(recipe, dict):
            continue
        for variant in (recipe, obj(recipe.get("normal")), obj(recipe.get("expensive"))):
            entries(variant.get("ingredients"), f"recipe {name} input")
            entries(variant.get("results"), f"recipe {name} result")

    for family in ("resource", "simple-entity", "simple-entity-with-owner",
                   "tree", "fish"):
        for name, entity in obj(raw.get(family)).items():
            minable = obj(obj(entity).get("minable"))
            if minable.get("result"):
                check(minable["result"], "item", f"{family} {name} mining")
            entries(minable.get("results"), f"{family} {name} mining")

    for name, tile in obj(raw.get("tile")).items():
        fluid = obj(tile).get("fluid")
        if fluid:
            check(fluid, "fluid", f"tile {name}")


def audit(raw):
    """Return (hard_errors, advisory_warnings), both sorted and deduplicated."""
    recipes = obj(raw.get("recipe"))
    technologies = obj(raw.get("technology"))
    planets = obj(raw.get("planet"))
    items = set()
    for category in ITEM_TYPES:
        items.update(obj(raw.get(category)))
    fluids = set(obj(raw.get("fluid")))
    available = items | fluids
    problems, warnings = set(), set()

    # The user-facing system card chain must remain craftable. These definite
    # missing prototypes are stronger evidence than generic recipe heuristics.
    for card in CARDS:
        recipe = recipes.get(card)
        if not isinstance(recipe, dict):
            continue  # Missing card recipes are checked by audit_prototypes.py.
        for ingredient in seq(recipe.get("ingredients")):
            name = name_of(ingredient)
            kind = ingredient.get("type", "item") if isinstance(ingredient, dict) else "item"
            valid = fluids if kind == "fluid" else items
            if name and name not in valid:
                problems.add(f"{card} requires missing {kind} ingredient {name}")
        results = recipe_products(recipe)
        for result in results:
            if result not in available:
                problems.add(f"{card} produces missing prototype {result}")
        if results and card not in results:
            problems.add(f"{card} does not produce its own tech card item")

    made = set()
    for recipe in recipes.values():
        if isinstance(recipe, dict):
            made.update(recipe_products(recipe))

    for name, technology in technologies.items():
        trigger = obj(technology.get("research_trigger"))
        for key in ("item", "fluid"):
            item = trigger.get(key)
            if not isinstance(item, str):
                continue
            new = ("kr-uranium-rifle-magazine" if item == "uranium-rounds-magazine"
                   else f"kr-{item}" if item in K2SO_RENAMES else None)
            if new and item not in made and new in made:
                problems.add(f"Unproducible {key} research trigger in {name}: "
                             f"{item} (produced replacement: {new})")

    # Recycling validation is deliberately advisory: some special recipes
    # intentionally multiply products or have unconventional cost structures.
    for name, recipe in recipes.items():
        if not ("recycl" in name.lower() and isinstance(recipe, dict)):
            continue
        if recipe.get("allow_productivity") is True and recipe.get("maximum_productivity") != 0:
            warnings.add(f"Review productivity on recycling recipe {name}")
        if not recipe_products(recipe):
            warnings.add(f"Review recycling recipe without products: {name}")

    # Planet restrictions should survive recipe/card rewrites by K2SO forks.
    for name, planet in (
        ("galvanization-research-data", "paracelsin"),
        ("biorecycling-research-data", "rubia"),
    ):
        recipe = recipes.get(name)
        if recipe and planet in planets and not seq(recipe.get("surface_conditions")):
            warnings.add(f"Missing surface conditions for {name} ({planet})")

    for name in ("water-electrolysis-shchierbin", "ske_h2o", "ske_water_electrolysis"):
        recipe = recipes.get(name)
        if recipe and recipe.get("maximum_productivity") != 0:
            warnings.add(f"Water-loop recipe {name} lacks a 0 productivity cap")

    audit_k2so_planet_machinery(raw, recipes, items, planets, warnings)
    audit_k2so_stale_materials(raw, recipes, warnings)

    return sorted(problems), sorted(warnings)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path, help="Factorio script-output/data-raw-dump.json")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON instead of lines")
    parser.add_argument("--strict-warnings", action="store_true",
                        help="Also exit nonzero for heuristic warnings")
    args = parser.parse_args()
    with args.dump.open(encoding="utf-8") as handle:
        raw = json.load(handle)
    raw = obj(raw)
    if isinstance(raw.get("raw"), dict):
        raw = raw["raw"]
    if not obj(raw.get("recipe")) or not obj(raw.get("technology")):
        parser.error("Expected the complete data.raw dump with recipe and technology tables")
    errors, warnings = audit(raw)
    if args.json:
        print(json.dumps({"errors": errors, "warnings": warnings}, indent=2))
    else:
        print(f"Compatibility audit: {len(errors)} error(s), {len(warnings)} warning(s)")
        for entry in errors:
            print("ERROR: " + entry)
        for entry in warnings:
            print("WARN:  " + entry)
    return int(bool(errors or (args.strict_warnings and warnings)))

if __name__ == "__main__":
    raise SystemExit(main())
