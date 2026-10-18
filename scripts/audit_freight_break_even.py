#!/usr/bin/env python3
"""Freight break-even scenarios from real Factorio recipes, not guessed prices.

Only the eight watched source-vs-alternative recipe pairs in
audit_exchange_economy.WATCH are modeled. Other factory partnerships remain
in the independent prototype integrity report.

Example:
  python scripts/audit_freight_break_even.py --dump-data-raw raw.json \
    --values estimates.json --shipping-costs freight.json \
    --machine-second-value 0.02 --lane moshine,fulgora

Values are user-provided *factory-gate credits per individual item or fluid
unit*, not market prices. Freight costs are credits per alternative craft.
We derive the maximum freight budget; route kilometres are descriptive only.
"""
from __future__ import annotations
import argparse
import heapq
import json
import math
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0,str(ROOT))

from scripts import audit_exchange_economy


def nonnegative(value, label):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{label} must be a finite nonnegative number")
    if not math.isfinite(value) or value < 0:
        raise ValueError(f"{label} must be a finite nonnegative number")
    return value


def validate_prices(prices, label):
    if prices is None:
        return {}
    if not isinstance(prices, dict):
        raise ValueError(f"{label} must be a JSON object")
    return {name: nonnegative(value, f"{label}[{name}]")
            for name, value in prices.items()}


def shortest_route(raw, origin, destination):
    """Shortest total registered kilometres, treating connections as undirected.

    This is not travel time, fuel cost or proof that a platform can make the trip.
    """
    if origin == destination:
        return {"kilometres": 0, "route": [origin]}
    connections = raw.get("space-connection", {})
    edges = {}
    for route in connections.values():
        if not isinstance(route, dict):
            continue
        src, dst, length = route.get("from"), route.get("to"), route.get("length")
        if not isinstance(src, str) or not isinstance(dst, str):
            continue
        if not isinstance(length, (int, float)) or isinstance(length, bool):
            continue
        if not math.isfinite(length) or length <= 0:
            continue
        edges.setdefault(src, []).append((dst, length))
        edges.setdefault(dst, []).append((src, length))
    best = {origin: 0.0}
    heap = [(0.0, origin, (origin,))]
    while heap:
        km, node, route = heapq.heappop(heap)
        if km != best.get(node):
            continue
        if node == destination:
            return {"kilometres": km, "route": list(route)}
        for neighbor, length in sorted(edges.get(node, [])):
            total = km + length
            if total < best.get(neighbor, math.inf):
                best[neighbor] = total
                heapq.heappush(heap, (total, neighbor, route + (neighbor,)))
    return {"kilometres": None, "route": [], "reason": "no-known-connection-path"}


def analyze(document, values=None, shipping_costs=None, machine_second_value=0, lanes=()):
    raw = document.get("raw", document) if isinstance(document, dict) else {}
    raw = raw if isinstance(raw, dict) else {}
    values = validate_prices(values, "values")
    shipping_costs = validate_prices(shipping_costs, "shipping_costs")
    rate = nonnegative(machine_second_value, "machine_second_value")
    market = {}
    for name, row in audit_exchange_economy.inspect(raw).items():
        if row["status"] not in ("passes-budget", "review"):
            market[name] = {"status": row["status"],
                            "reason": row.get("reason")}
            continue
        source, target, batch, _ = audit_exchange_economy.WATCH[name]
        alt = raw.get("recipe", {}).get(name, {})
        native = raw.get("recipe", {}).get(source, {})
        native_seconds = native.get("energy_required", 0.5) * batch
        premium_seconds = alt.get("energy_required", 0.5)
        added_seconds = max(0, premium_seconds - native_seconds)
        budget = None
        missing = []
        target_value = values.get("item:" + target)
        if target_value is None:
            missing.append("item:" + target)
        value_of_imports = 0.0
        for item, amount in row["extra_imports_per_craft"].items():
            if item not in values:
                missing.append(item)
            else:
                value_of_imports += amount * values[item]
        if not missing:
            # A maximum for all freight handling combined, not per component.
            budget = (row["bonus_output"] * target_value - value_of_imports
                      - added_seconds * rate)
        shipping = shipping_costs.get(name)
        # Never label a broken or weakened native recipe "worthwhile",
        # regardless of optimistic user price assumptions.
        trustworthy = row["status"] == "passes-budget"
        margin = (budget - shipping if trustworthy and budget is not None
                  and shipping is not None else None)
        market[name] = {
            "status": "priced" if budget is not None else "needs-input-values",
            "recipe_integrity": row["status"],
            "bonus_output": row["bonus_output"],
            "bonus_fraction": row["bonus_fraction"],
            "machine_throughput_change": row["machine_throughput_change"],
            "extra_imports_per_craft": row["extra_imports_per_craft"],
            "extra_machine_seconds_per_craft": round(added_seconds, 6),
            "maximum_freight_credits_per_craft": round(budget, 6) if budget is not None else None,
            "assumed_shipping_credits_per_craft": shipping,
            "scenario_margin_credits_per_craft": round(margin, 6) if margin is not None else None,
            "scenario_verdict": ("within-assumed-budget" if margin >= 0 else
                                 "over-assumed-budget") if margin is not None else None,
            "missing_input_values": sorted(missing),
            "integrity_issues": row.get("issues", []),
        }
    routes = [{"from": a, "to": b, **shortest_route(raw, a, b)}
              for a, b in lanes]
    return {
        "price_basis": "user-supplied factory-gate credits per unit",
        "shipping_basis": "user-supplied credits per premium recipe craft",
        "machine_second_value": rate,
        "watched_recipe_pairs": len(market),
        "recipes": market,
        "route_context": routes,
        "limitations": [
            "No market prices, travel times or freight costs were invented.",
            "Route kilometres do not automatically imply credits, fuel, risk or speed.",
            "Only watched source recipes with deterministic outputs are modeled.",
            "A positive scenario margin is not proof of real-world factory profitability.",
        ]
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dump-data-raw", type=Path, required=True)
    parser.add_argument("--values", type=Path, help="JSON unit-value assumptions")
    parser.add_argument("--shipping-costs", type=Path,
                        help="JSON alternative-recipe shipping credits per craft")
    parser.add_argument("--machine-second-value", type=float, default=0.0)
    parser.add_argument("--lane", action="append", default=[],
                        metavar="ORIGIN,DESTINATION")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    pairs = []
    for pair in args.lane:
        endpoints = pair.split(",")
        if len(endpoints) != 2 or not all(x.strip() for x in endpoints):
            parser.error("--lane must use ORIGIN,DESTINATION")
        pairs.append(tuple(x.strip() for x in endpoints))
    def read(path):
        return json.loads(path.read_text(encoding="utf-8")) if path else None
    try:
        report = analyze(read(args.dump_data_raw), read(args.values),
                         read(args.shipping_costs), args.machine_second_value,
                         pairs)
    except ValueError as e:
        parser.error(str(e))
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print("RAZI FREIGHT / BREAK-EVEN SCENARIOS")
        for name, row in report["recipes"].items():
            if row["status"] == "priced":
                print(name, "maximum all-in freight credits/craft:",
                      row["maximum_freight_credits_per_craft"])
            elif row["status"] == "needs-input-values":
                print(name, "add unit prices for:",
                      ", ".join(row["missing_input_values"]))
        for route in report["route_context"]:
            print(route["from"], "->", route["to"], ":",
                  route["kilometres"], "km (known route segments only)")
        print("All costs are user assumptions, not measured platform freight.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
