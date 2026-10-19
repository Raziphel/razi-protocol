#!/usr/bin/env python3
"""Read-only, loaded-modpack check for late power unlocked before Razi's gates.

Pass Factorio's FINAL --dump-data-raw JSON, not individual mod source files.
This checks actual technology prerequisites, alternate recipe unlocks and
quality unlock effects. It does not prove that recipes are craftable in-game.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

RULES = {
    "foundation": ("planet-discovery-paracelsin",
                   "planet-discovery-maraxsis"),
    "fusion-reactor": ("planet-discovery-cubium",
                       "planet-discovery-tenebris"),
    "legendary-quality": ("razi-outer-frontier-mastery",),
}


def active(node):
    return isinstance(node, dict) and node.get("enabled") is not False and (
        node.get("hidden") is not True
    )


def ancestors(techs, name):
    """Return transitive prerequisite names and cycles, without infinite loops."""
    found, loops = set(), set()
    visited, visiting = set(), set()

    def walk(node):
        if node in visiting:
            loops.add(node)
            return
        if node in visited:
            return
        visiting.add(node)
        for parent in (techs.get(node) or {}).get("prerequisites") or []:
            if not isinstance(parent, str):
                continue
            found.add(parent)
            walk(parent)
        visiting.remove(node)
        visited.add(node)

    walk(name)
    return found, sorted(loops)


def recipe_enabled(recipe):
    if not isinstance(recipe, dict):
        return False
    # Both 2.1 prototypes and older compatibility exports can exist.
    for node in (recipe, recipe.get("normal"), recipe.get("expensive")):
        if isinstance(node, dict) and node.get("enabled") is True:
            return True
    return False


def effects_unlock(tech, recipe=None, quality=None):
    for effect in tech.get("effects") or []:
        if not isinstance(effect, dict):
            continue
        if recipe and effect.get("type") == "unlock-recipe" and (
            effect.get("recipe") == recipe
        ):
            return True
        if quality and effect.get("type") == "unlock-quality":
            q = effect.get("quality")
            name = q.get("name") if isinstance(q, dict) else q
            if name == quality:
                return True
    return False


def inspect(document):
    raw = document.get("raw", document)
    techs = raw.get("technology") or {}
    recipes = raw.get("recipe") or {}
    rows = []
    for target, parents in RULES.items():
        technology = techs.get(target)
        if not active(technology):
            rows.append({"technology": target, "status": "unavailable",
                         "issues": [], "required": list(parents)})
            continue

        lineage, loops = ancestors(techs, target)
        issues = []
        missing = [parent for parent in parents if parent not in lineage]
        if missing:
            issues.append("missing-staged-gates:" + ",".join(missing))
        for parent in parents:
            if not active(techs.get(parent)):
                issues.append("unavailable-gate:" + parent)
        if loops:
            issues.append("research-cycle:" + ",".join(loops))
        dead = sorted(parent for parent in lineage
                      if parent not in techs or not active(techs[parent]))
        if dead:
            issues.append("blocked-ancestry:" + ",".join(dead[:8]))

        if target in ("foundation", "fusion-reactor"):
            if recipe_enabled(recipes.get(target)):
                issues.append("recipe-enabled-before-research")
            alternate = []
            for name, node in techs.items():
                if name != target and active(node) and effects_unlock(node, recipe=target):
                    other_lineage, _ = ancestors(techs, name)
                    if target not in other_lineage:
                        alternate.append(name)
            if alternate:
                issues.append("alternative-recipe-unlock:" + ",".join(sorted(alternate)))
        elif target == "legendary-quality":
            alternate = []
            for name, node in techs.items():
                if name != target and active(node) and effects_unlock(
                    node, quality="legendary"
                ):
                    other_lineage, _ = ancestors(techs, name)
                    if target not in other_lineage:
                        alternate.append(name)
            if alternate:
                issues.append("alternative-quality-unlock:" + ",".join(sorted(alternate)))

        rows.append({
            "technology": target,
            "status": "review" if issues else "staged-in-technology-graph",
            "required": list(parents),
            "confirmed_parents": sorted(set(parents) & lineage),
            "issues": issues,
        })
    return {
        "rows": rows,
        "reviews": sum(r["status"] == "review" for r in rows),
        "limitations": [
            "Prerequisite graph, not a live research or craftability simulation.",
            "A missing staging gate may be intentional if the startup setting is off.",
            "Alternate unlocks are potential bypasses requiring source-mod review.",
            "Quality asteroid levels are hostile difficulty, not new research tiers.",
        ],
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dump-data-raw", required=True, type=Path)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--strict", action="store_true",
                        help="Fail if an installed late-power technology needs review")
    args = parser.parse_args()
    result = inspect(json.loads(args.dump_data_raw.read_text(encoding="utf-8")))
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        for row in result["rows"]:
            print(row["technology"] + ": " + row["status"])
            for issue in row["issues"]:
                print("  review: " + issue)
    return int(args.strict and result["reviews"] > 0)


if __name__ == "__main__":
    raise SystemExit(main())
