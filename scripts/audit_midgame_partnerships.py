#!/usr/bin/env python3
"""Audit four optional midgame factory partnerships in a loaded Factorio dump.

The native source recipe must remain available. Installed supplier recipes
must be able to produce the added ingredients; this does not prove transport
availability, planet access or ongoing output. Absent optional mods are fine.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0,str(ROOT))
from scripts.audit_exchange_economy import outputs,ingredients,deterministic_results

# Premium ID: (native recipe, native item, imports as item: supplier recipe)
PARTNERSHIPS={
 "razi-middle-fulgora-resilient-capacitors":(
  "supercapacitor","supercapacitor",
  {"kr-energy-control-unit":"kr-energy-control-unit","optical-cable":"optical-cable"}),
 "razi-middle-aquilo-capacitor-controls":(
  "kr-energy-control-unit","kr-energy-control-unit",
  {"supercapacitor":"supercapacitor","optical-cable":"optical-cable"}),
 "razi-middle-paracelsin-shielded-coils":(
  "electric-coil","electric-coil",
  {"craptonite-frame":"craptonite-casting","holmium-plate":"holmium-plate"}),
 "razi-middle-rubia-conductive-frames":(
  "craptonite-casting","craptonite-frame",
  {"electric-coil":"electric-coil","supercapacitor":"supercapacitor"})
}
LATE={"beetlejuice-discovery","umbra-discovery"}

def obj(value):
    return value if isinstance(value,dict) else {}

def ancestors(techs,name):
    seen=set()
    todo=list(obj(techs.get(name)).get("prerequisites") or [])
    while todo:
        parent=todo.pop()
        if parent in seen: continue
        seen.add(parent)
        todo.extend(obj(techs.get(parent)).get("prerequisites") or [])
    return seen

def analyze(document):
    raw=obj(document)
    raw=obj(raw.get("raw")) or raw
    recipes=obj(raw.get("recipe"))
    techs=obj(raw.get("technology"))
    labs=obj(raw.get("lab"))
    rows=[]
    for name,(native,product,imports) in PARTNERSHIPS.items():
        recipe=recipes.get(name)
        tech=techs.get(name)
        if recipe is None and tech is None:
            rows.append({"name":name,"status":"not-installed","issues":[]})
            continue
        issues=[]
        if not isinstance(recipe,dict) or not isinstance(tech,dict):
            rows.append({"name":name,"status":"review",
                         "issues":["missing-recipe-or-research"]})
            continue
        source=recipes.get(native)
        if not isinstance(source,dict):
            issues.append("missing-native-recipe")
        else:
            original=outputs(source,product)
            upgrade=outputs(recipe,product)
            if not original or not upgrade:
                issues.append("missing-native-or-premium-product")
            elif upgrade<=original*4:
                issues.append("no-bonus-over-four-native-crafts")
            original_inputs=ingredients(source)
            upgrade_inputs=ingredients(recipe)
            if any(upgrade_inputs.get(key,0)+1e-6<value*4
                   for key,value in original_inputs.items()):
                issues.append("original-inputs-not-preserved")
            old_products=deterministic_results(source)
            new_products=deterministic_results(recipe)
            if old_products is None or new_products is None:
                issues.append("non-deterministic-source-products")
            elif any(new_products.get(key,0)+1e-6<value*4
                     for key,value in old_products.items()
                     if key!=("item",product)):
                issues.append("original-byproducts-not-preserved")
        supplied=ingredients(recipe)
        native_costs=ingredients(source) if isinstance(source,dict) else {}
        for item,producer in imports.items():
            # The manufacturing incentive must really add this import,
            # not merely rename a material already in the native recipe.
            additional=supplied.get(("item",item),0)-4*native_costs.get(("item",item),0)
            if additional<=0:
                issues.append("missing-import:"+item)
                continue
            origin=recipes.get(producer)
            if not isinstance(origin,dict) or not outputs(origin,item):
                issues.append("no-native-supplier:"+item)
        prerequisite=ancestors(techs,name)
        for late in sorted(prerequisite&LATE):
            issues.append("late-system-prerequisite:"+late)
        if not any(isinstance(e,dict) and e.get("type")=="unlock-recipe"
                   and e.get("recipe")==name for e in tech.get("effects") or []):
            issues.append("research-does-not-unlock-recipe")
        required=set()
        for entry in obj(tech.get("unit")).get("ingredients") or []:
            science=entry.get("name") if isinstance(entry,dict) else (
                entry[0] if isinstance(entry,list) and entry else None)
            if science: required.add(science)
        if labs and required and not any(
            required.issubset(set(lab.get("inputs") or []))
            for lab in labs.values() if isinstance(lab,dict)):
            issues.append("no-single-lab-supports-research")
        rows.append({"name":name,"status":"review" if issues else "prototype-verified",
                     "issues":sorted(set(issues)),
                     "imports":sorted(imports),
                     "research_units":obj(tech.get("unit")).get("count")})
    return {"declared":len(PARTNERSHIPS),
            "installed":sum(r["status"]!="not-installed" for r in rows),
            "needs_review":sum(r["status"]=="review" for r in rows),
            "rows":rows,
            "limitations":["A registered producer is not evidence of shipping.",
                           "Native source technology and planetary availability need in-game review.",
                           "No science prices or source recipes are changed."]}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dump-data-raw",required=True,type=Path)
    parser.add_argument("--json",action="store_true")
    parser.add_argument("--strict",action="store_true")
    args=parser.parse_args()
    result=analyze(json.loads(args.dump_data_raw.read_text(encoding="utf-8")))
    if args.json:
        print(json.dumps(result,indent=2))
    else:
        print("Installed midgame partnerships:",result["installed"],"/4",
              "; for review:",result["needs_review"])
        for row in result["rows"]:
            if row["issues"]: print(row["name"],", ".join(row["issues"]))
    return int(args.strict and result["needs_review"]>0)

if __name__=="__main__":
    raise SystemExit(main())
