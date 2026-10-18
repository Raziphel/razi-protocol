#!/usr/bin/env python3
"""Inspect real optional industrial upgrades in a loaded Factorio prototype dump.

This is an audit of technology/recipe integrity and potential freight value,
not a claim that machines are running or that distant cargo is profitable.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def obj(value):
    return value if isinstance(value, dict) else {}


def seq(value):
    return value if isinstance(value, list) else []


def name_of(entry):
    if isinstance(entry, dict):
        return entry.get("name")
    if isinstance(entry, (list, tuple)) and entry:
        return entry[0]
    return None


def quantity(entry):
    if isinstance(entry, dict):
        return entry.get("amount")
    if isinstance(entry, (list, tuple)) and len(entry) > 1:
        return entry[1]
    return None


def kind_of(entry):
    return entry.get("type", "item") if isinstance(entry, dict) else "item"


def catalog(path: Path = ROOT / "scripts" / "razi_journal_industry.lua"):
    """Authoritative Razi journal catalog. No separate list to get stale."""
    text = path.read_text(encoding="utf-8")
    found = re.findall(
        r'\{id="([a-z0-9-]+)",chapter="alliances",tech="([^"]+)"',
        text,
    )
    return dict(found)


def machine_categories(raw):
    categories = set()
    for family in ("assembling-machine", "furnace"):
        for machine in obj(raw.get(family)).values():
            if not isinstance(machine, dict) or machine.get("fixed_recipe"):
                continue
            categories.update(seq(machine.get("crafting_categories")))
    return categories


def analyze(document, listed=None):
    raw = obj(document)
    raw = obj(raw.get("raw")) or raw
    technologies = obj(raw.get("technology"))
    recipes = obj(raw.get("recipe"))
    machines = machine_categories(raw)
    labs = [set(seq(lab.get("inputs"))) for lab in
            obj(raw.get("lab")).values() if isinstance(lab, dict)]
    names = listed if listed is not None else catalog()
    rows = []
    for quest, technology_name in names.items():
        tech = obj(technologies.get(technology_name))
        recipe = obj(recipes.get(technology_name))
        if not tech and not recipe:
            rows.append({"quest": quest, "technology": technology_name,
                         "status": "not-registered", "issues": []})
            continue
        issues = []
        if not tech:
            issues.append("recipe-has-no-owning-technology")
        if not recipe:
            issues.append("technology-has-no-recipe")
        if recipe:
            if recipe.get("hidden") or recipe.get("hide_from_player_crafting"):
                issues.append("premium-recipe-hidden")
            if recipe.get("enabled") is not False:
                issues.append("premium-recipe-not-research-locked")
            if recipe.get("allow_productivity") is not False:
                issues.append("premium-recipe-allows-productivity")
            if recipe.get("auto_recycle") is not False:
                issues.append("premium-recipe-allows-auto-recycling")
            output_names = {name_of(x) for x in seq(recipe.get("results"))}
            input_names = {name_of(x) for x in seq(recipe.get("ingredients"))}
            output_names.discard(None)
            input_names.discard(None)
            if not output_names:
                issues.append("no-declared-products")
            if output_names & input_names:
                issues.append("self-consuming-output")
            for entry in seq(recipe.get("ingredients")) + seq(recipe.get("results")):
                amount = quantity(entry)
                if not isinstance(amount, (int, float)) or amount <= 0:
                    issues.append("invalid-recipe-amount")
                    break
            categories = set(seq(recipe.get("categories")))
            if not categories:
                categories = {recipe.get("category") or "crafting"}
            if machines and not (categories & machines):
                issues.append("no-loaded-crafting-category-machine")
            if any(x.get("probability") is not None or
                   x.get("amount_min") is not None or
                   x.get("amount_max") is not None
                   for x in seq(recipe.get("results")) if isinstance(x, dict)):
                issues.append("non-deterministic-premium-output")
        if tech:
            if not any(e.get("type") == "unlock-recipe" and
                       e.get("recipe") == technology_name
                       for e in seq(tech.get("effects")) if isinstance(e, dict)):
                issues.append("missing-own-recipe-unlock")
            science = {name_of(x) for x in
                       seq(obj(tech.get("unit")).get("ingredients"))}
            science.discard(None)
            if labs and science and not any(science <= lab for lab in labs):
                issues.append("no-lab-accepts-full-science-set")
        rows.append({
            "quest": quest, "technology": technology_name,
            "status": "review" if issues else "verified-prototype-shape",
            "issues": sorted(set(issues)),
            "ingredient_types": sorted({kind_of(x) for x in
                                        seq(recipe.get("ingredients"))}),
            "prerequisite_count": len(seq(tech.get("prerequisites"))),
        })
    counts = {"not-registered": 0, "review": 0,
              "verified-prototype-shape": 0}
    for row in rows:
        counts[row["status"]] += 1
    return {
        "declared_optional_partnerships": len(names),
        "registered": len(names) - counts["not-registered"],
        "counts": counts,
        "machine_catalog_present": bool(machines),
        "lab_catalog_present": bool(labs),
        "rows": rows,
        "caveats": [
            "Absent optional recipes are normal when dependencies are missing.",
            "Valid prototype shapes do not establish freight profitability.",
            "Check source surface restrictions, factory machines and save migration in game.",
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dump-data-raw", required=True, type=Path)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--strict", action="store_true",
                        help="Nonzero exit if a registered recipe needs review")
    args = parser.parse_args()
    with args.dump_data_raw.open(encoding="utf-8") as source:
        report = analyze(json.load(source))
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print("Optional factory partnerships:", report["declared_optional_partnerships"])
        print("Registered:", report["registered"], "Review:",
              report["counts"]["review"])
        for row in report["rows"]:
            if row["status"] == "review":
                print("  ", row["technology"], ":", ", ".join(row["issues"]))
        print("This is a prototype-shape audit, not a freight-cost simulation.")
    return int(args.strict and report["counts"]["review"] > 0)


if __name__ == "__main__":
    raise SystemExit(main())
