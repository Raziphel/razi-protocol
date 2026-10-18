#!/usr/bin/env python3
"""One offline factory/industry health report for a complete Factorio data.raw dump.

No edits, no CI jobs, and no guessed gameplay measurements. Run after the
source modpack completes all data stages. Missing optional content is normal.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0,str(ROOT))

from scripts import audit_crafting_navigation
from scripts import audit_exchange_economy
from scripts import audit_industry_portfolio
from scripts import audit_tech_tree


def build_report(document):
    raw=document.get("raw",document) if isinstance(document,dict) else {}
    report={
        "optional_factory_partnerships":audit_industry_portfolio.analyze(raw),
        "premium_recipe_budget":audit_exchange_economy.inspect(raw),
        "crafting_navigation":audit_crafting_navigation.analyze(raw),
        "research_graph":audit_tech_tree.analyze(raw)
    }
    issues=[]
    for item in report["optional_factory_partnerships"]["rows"]:
        if item["status"]=="review":
            issues.append({"area":"factory-partnership","name":item["technology"],
                           "reasons":item["issues"]})
    for name,causes in audit_exchange_economy.problems(
            report["premium_recipe_budget"]).items():
        issues.append({"area":"premium-recipe-budget","name":name,
                       "reasons":causes})
    for name,causes in report["research_graph"]["missing_prerequisites"].items():
        issues.append({"area":"missing-research-prerequisite","name":name,
                       "reasons":causes})
    for name,causes in report["research_graph"][
            "unresearchable_science_combinations"].items():
        issues.append({"area":"science-lab-coverage","name":name,
                       "reasons":causes})
    report["review_issues"]=issues
    report["review_count"]=len(issues)
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dump-data-raw",required=True,type=Path)
    parser.add_argument("--json",action="store_true")
    parser.add_argument("--strict",action="store_true",
                        help="Return nonzero when concrete audit issues are found")
    args=parser.parse_args()
    with args.dump_data_raw.open(encoding="utf-8") as source:
        report=build_report(json.load(source))
    if args.json:
        print(json.dumps(report,indent=2))
    else:
        factory=report["optional_factory_partnerships"]
        recipes=report["crafting_navigation"]
        print("RAZI INDUSTRIES / FACTORY HEALTH")
        print("Optional partnerships installed:",factory["registered"],
              "/",factory["declared_optional_partnerships"])
        print("Crafting recipes:",recipes["total_recipes"])
        print("Potential research and economy issues:",report["review_count"])
        for issue in report["review_issues"][:30]:
            print(" ",issue["area"],issue["name"],":",", ".join(issue["reasons"]))
        print("Run with --json for the full evidence, not a simulated factory.")
    return int(args.strict and report["review_count"]>0)


if __name__=="__main__":
    raise SystemExit(main())
