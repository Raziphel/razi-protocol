#!/usr/bin/env python3
"""Run the Razi campaign checks against a real post-load Factorio prototype dump.

This audit cannot simulate autoplace, cargo logistics or Lua control scripts.
"Blocked" means the available prototype evidence has no usable supply path;
"unverified" is deliberately not treated as a release-stopping failure.
"""
import argparse
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audit_prototypes
import audit_supply_chains
import audit_exchange_economy
import audit_research_balance

FOCUS = {
    "Panglia": "panglia",
    "Aquilo": "aquilo",
    "Linox": "linox-planet_linox",
    "Crucible": "crucible",
    "Vesta": "vesta",
}


def examine(raw, route_checks=True):
    """Structured report shared by CLI and regression fixtures."""
    graph_issues = audit_prototypes.audit(
        raw, check_campaign_routes=route_checks)
    tracer = audit_supply_chains.SupplyTrace(raw)
    planets = tracer.audit_planets()
    milestones = tracer.analyze()
    economy = audit_exchange_economy.inspect(raw)
    research = audit_research_balance.examine(raw)
    focus = {}
    for label, name in FOCUS.items():
        data = planets.get(name)
        focus[label] = {
            "planet": name,
            "status": data["status"] if data else "not-installed",
            "discovery": data["unlockers"] if data else [],
            "manufacturing": milestones.get(label, {}).get(
                "after_discovery_production", []),
        }
    blocked = sorted(name for name, info in planets.items()
                     if info["status"] == "blocked")
    routes = audit_prototypes.reachable_locations(
        raw.get("space-connection", {}), "nauvis")
    isolated = sorted(name for name in planets if name not in routes)
    # Keep every installed world visible to the release review. A missing
    # route or uncertain supplier is a manual review task, not a fabricated
    # source-mod defect or permission to rewrite its discovery research.
    planet_review_queue=[]
    for name,info in planets.items():
        status=info["status"]
        notes=[]
        if status=="blocked":
            notes.append("Discovery production path is statically blocked")
        elif status!="traceable":
            notes.append("Discovery requires in-game verification: "+status)
        if name in isolated:
            notes.append("No listed route to Nauvis in the prototype graph")
        priority=("blocker" if status=="blocked"
                  else "review" if notes else "static-clear")
        planet_review_queue.append({
            "planet":name, "priority":priority, "discovery_status":status,
            "unlockers":info.get("unlockers",[]),
            "has_listed_route":name not in isolated,
            "notes":notes
        })
    priority_order={"blocker":0,"review":1,"static-clear":2}
    planet_review_queue.sort(key=lambda row:(
        priority_order[row["priority"]],row["planet"]))
    return {
        "prototype_issues": graph_issues,
        "research_tree": research,
        "research_errors": research["errors"],
        "research_advisories": research["advisories"],
        "economy": economy,
        "economy_issues": audit_exchange_economy.problems(economy),
        "worlds_checked": len(planets),
        "world_status_counts": dict(sorted(
            Counter(info["status"] for info in planets.values()).items())),
        "blocked_discoveries": blocked,
        "no_geometric_route_from_nauvis": isolated,
        "focus": focus,
        "planets": planets,
        "planet_review_queue": planet_review_queue,
        "milestones": milestones,
        "limitations": [
            "Routes are checked as geometry, not as an executable travel path.",
            "Mineable resources, item imports, and scripted exploration are not proven.",
            "Unverified discovery chains need a full in-game test.",
        ],
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump", type=Path,
                        help="Factorio script-output/data-raw-dump.json")
    parser.add_argument("--output", type=Path,
                        help="Write the full JSON report to a file")
    parser.add_argument("--json", action="store_true",
                        help="Print the full JSON report to stdout")
    parser.add_argument("--no-campaign-route-checks", action="store_true",
                        help="Disable the hardcoded seven-hub route assertions")
    args = parser.parse_args(argv)

    with args.dump.open(encoding="utf-8") as source:
        raw = json.load(source)
    if isinstance(raw, dict) and isinstance(raw.get("raw"), dict):
        raw = raw["raw"]
    if not isinstance(raw, dict) or not isinstance(raw.get("technology"), dict) \
            or not isinstance(raw.get("recipe"), dict):
        parser.error("Expected complete post-load technology and recipe tables")

    report = examine(raw, route_checks=not args.no_campaign_route_checks)
    output = json.dumps(report, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        args.output.write_text(output, encoding="utf-8")
    if args.json:
        print(output, end="")
    else:
        print(f"Prototype problems: {len(report['prototype_issues'])}")
        for issue in report["prototype_issues"]:
            print(f"  ERROR: {issue}")
        print(f"Research-tree errors: {len(report['research_errors'])}")
        print(f"Research-tree advisory notes: {len(report['research_advisories'])}")
        for issue in report["research_errors"]+report["research_advisories"]:
            print(f"  {issue['severity'].upper()} {issue['code']}: "
                  +", ".join(issue["targets"]))
        print(f"Factory freight issues: {len(report['economy_issues'])}")
        for recipe, issues in report["economy_issues"].items():
            for issue in issues:
                print(f"  REVIEW {recipe}: {issue}")
        print(f"Planet discovery checks: {report['worlds_checked']}")
        for name, status in report["world_status_counts"].items():
            print(f"  {name}: {status}")
        print("Five-world progression focus:")
        for label, result in report["focus"].items():
            print(f"  {label}: {result['status']}")
        if report["no_geometric_route_from_nauvis"]:
            print("Planet route connections to inspect (advisory):")
            for planet in report["no_geometric_route_from_nauvis"]:
                print(f"  {planet}")
        review=[row for row in report["planet_review_queue"]
                if row["priority"]!="static-clear"]
        if review:
            print("Planet-by-planet review queue (first 12):")
            for row in review[:12]:
                print(f"  {row['priority'].upper()} {row['planet']}: "
                      +"; ".join(row["notes"]))
            if len(review)>12:
                print(f"  And {len(review)-12} more in the JSON report")
        if report["blocked_discoveries"]:
            print("Confirmed blocked discovery chains:")
            for planet in report["blocked_discoveries"]:
                print(f"  {planet}")
        if args.output:
            print(f"Full JSON report: {args.output}")
        print("Unverified paths require in-game checks, not automatic fixes.")
    return 1 if (report["prototype_issues"] or report["blocked_discoveries"]
                 or report["economy_issues"] or report["research_errors"]) else 0


if __name__ == "__main__":
    raise SystemExit(main())
