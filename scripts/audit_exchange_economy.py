#!/usr/bin/env python3
"""Inspect optional freight rewards using final Factorio recipe prototypes.

Quantifies output, craft time and imported inputs. It cannot price cargo
travel, power, module bonuses or the cost of making imported intermediates.
"""
import argparse
import json
from pathlib import Path

# (alternative: native recipe, output item, native batches, max gross bonus)
WATCH = {
    "razi-bio-rare-metal-casting":
        ("kr-casting-rare-metals", "kr-rare-metals", 4, 0.30),
    "razi-electrobiological-components":
        ("kr-electronic-components", "kr-electronic-components", 4, 0.25),
    "razi-cryo-energy-control":
        ("kr-energy-control-unit", "kr-energy-control-unit", 4, 0.25),
    "razi-vesta-frontier-foundations":
        ("vesta-foundation", "vesta-foundation", 4, 0.25),
    "razi-network-bond-paracelsin-coils":
        ("electric-coil", "electric-coil", 4, 0.25),
    "razi-network-bond-linox-refining":
        ("linox-recipe_rare-earth-refining", "rare-earth-powder", 4, 0.25),
    "razi-network-frame-vesta-foundations":
        ("vesta-foundation", "vesta-foundation", 4, 0.25),
    "razi-network-frame-aquilo-controllers":
        ("kr-energy-control-unit", "kr-energy-control-unit", 4, 0.25),
}


def outputs(recipe, product):
    if recipe.get("result") == product:
        return recipe.get("result_count", 1)
    total = 0
    for entry in recipe.get("results", []):
        if isinstance(entry, list) and entry and entry[0] == product:
            if len(entry) < 2:
                return None
            total += entry[1]
        elif isinstance(entry, dict) and entry.get("name") == product:
            if entry.get("probability", 1) != 1 or "amount_min" in entry \
                    or "amount_max" in entry:
                return None
            total += entry.get("amount", 0)
    return total or None


def ingredients(recipe):
    result = {}
    for entry in recipe.get("ingredients", []):
        if isinstance(entry, list) and len(entry) > 1:
            name, quantity, kind = entry[0], entry[1], "item"
        elif isinstance(entry, dict):
            name = entry.get("name")
            quantity = entry.get("amount")
            kind = entry.get("type", "item")
        else:
            continue
        if name and isinstance(quantity, (int, float)):
            result[(kind, name)] = result.get((kind, name), 0) + quantity
    return result


def inspect(raw):
    recipes = raw.get("recipe", {})
    report = {}
    for name, (source_name, product, batches, cap) in WATCH.items():
        alt, native = recipes.get(name), recipes.get(source_name)
        if alt is None:
            report[name] = {"status": "not-registered"}
            continue
        if native is None:
            report[name] = {"status": "unverified", "reason": "native recipe absent"}
            continue
        base = outputs(native, product)
        actual = outputs(alt, product)
        if not isinstance(base, (int, float)) or not isinstance(actual, (int, float)) \
                or base <= 0 or actual <= 0:
            report[name] = {"status": "unverified",
                            "reason": "non-deterministic or missing target result"}
            continue
        old_time = native.get("energy_required", 0.5)
        new_time = alt.get("energy_required", 0.5)
        if not isinstance(old_time, (int, float)) or old_time <= 0 \
                or not isinstance(new_time, (int, float)) or new_time <= 0:
            report[name] = {"status": "unverified", "reason": "invalid recipe time"}
            continue
        nominal = base * batches
        extra = actual - nominal
        ratio = extra / nominal
        throughput = (actual / new_time) / (base / old_time) - 1
        scaled_original = {key: amount * batches
                           for key, amount in ingredients(native).items()}
        imported = {}
        for key, amount in ingredients(alt).items():
            surplus = amount - scaled_original.get(key, 0)
            if surplus > 0:
                imported[f"{key[0]}:{key[1]}"] = surplus
        reasons = []
        if extra <= 0:
            reasons.append("No bonus target product")
        if ratio > cap + 1e-6:
            reasons.append("Extra output exceeds guarded bonus ceiling")
        if throughput < -0.00001:
            reasons.append("Slower output per machine than the native recipe")
        if not imported:
            reasons.append("Freight recipe adds no real imported ingredient")
        if alt.get("allow_productivity") is not False:
            reasons.append("Bonus output permits productivity multiplication")
        if alt.get("auto_recycle") is not False:
            reasons.append("Bonus recipe permits automatic recycling")
        report[name] = {
            "status": "review" if reasons else "passes-budget",
            "native_recipe": source_name,
            "native_output_per_batch": base,
            "native_batches": batches,
            "bonus_output": extra,
            "bonus_fraction": round(ratio, 4),
            "machine_throughput_change": round(throughput, 4),
            "extra_imports_per_craft": dict(sorted(imported.items())),
            "research_units": raw.get("technology", {}).get(name, {}).get(
                "unit", {}).get("count"),
            "issues": reasons,
            "caveat": "Does not value shipping, upstream crafting or research inputs."
        }
    return report


def problems(report):
    return {name: entry["issues"] for name, entry in report.items()
            if entry["status"] == "review"}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path, help="Factorio post-load data.raw JSON")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)
    with args.dump.open(encoding="utf-8") as fd:
        raw = json.load(fd)
    if isinstance(raw, dict) and isinstance(raw.get("raw"), dict):
        raw = raw["raw"]
    if not isinstance(raw, dict) or not isinstance(raw.get("recipe"), dict):
        parser.error("Expected full post-load recipe prototypes")
    report = inspect(raw)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        for name, row in report.items():
            line = f"{name}: {row['status']}"
            if row["status"] in {"review", "passes-budget"}:
                line += (f"  output {row['bonus_fraction']:+.1%}; "
                         f"machine throughput {row['machine_throughput_change']:+.1%}")
            print(line)
            for issue in row.get("issues", []):
                print(f"  REVIEW: {issue}")
        print("Shipping time and upstream costs require a real factory benchmark.")
    return 1 if problems(report) else 0


if __name__ == "__main__":
    raise SystemExit(main())
