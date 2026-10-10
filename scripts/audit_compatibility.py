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
