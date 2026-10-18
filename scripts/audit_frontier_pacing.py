#!/usr/bin/env python3
"""Read-only first/middle optional factory pacing audit using loaded prototypes."""
import argparse
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0,str(ROOT))

from scripts.audit_exchange_economy import outputs,ingredients,deterministic_results

RULES={
 "first":{
  "razi-frontier-moshine-biometal-silicon":("silicon-cell","silicon-cell"),
  "razi-frontier-gleba-photofiber":("carbon-fiber","carbon-fiber"),
  "razi-frontier-castra-composite-rounds":("piercing-rounds-magazine","piercing-rounds-magazine")
 },
 "middle":{
  "razi-middle-fulgora-resilient-capacitors":("supercapacitor","supercapacitor"),
  "razi-middle-aquilo-capacitor-controls":("kr-energy-control-unit","kr-energy-control-unit"),
  "razi-middle-paracelsin-shielded-coils":("electric-coil","electric-coil"),
  "razi-middle-rubia-conductive-frames":("craptonite-casting","craptonite-frame")
 }
}
LATE={
 "first":{"vibrant-discovery","vespera-discovery","beetlejuice-discovery","umbra-discovery"},
 "middle":{"beetlejuice-discovery","umbra-discovery"}
}

def ancestors(techs,name):
    seen=set()
    pending=list((techs.get(name) or {}).get("prerequisites") or [])
    while pending:
        parent=pending.pop()
        if parent in seen: continue
        seen.add(parent)
        pending.extend((techs.get(parent) or {}).get("prerequisites") or [])
    return seen

def inspect(document):
    raw=document.get("raw",document)
    recipes=raw.get("recipe") or {}
    techs=raw.get("technology") or {}
    rows=[]
    summary={}
    for stage,definitions in RULES.items():
        for name,(source,product) in definitions.items():
            alt,native,tech=recipes.get(name),recipes.get(source),techs.get(name)
            if alt is None and tech is None:
                rows.append({"stage":stage,"name":name,"status":"not-installed","issues":[]})
                continue
            issues=[]
            if not all(isinstance(x,dict) for x in (alt,native,tech)):
                rows.append({"stage":stage,"name":name,"status":"review",
                             "issues":["missing-native-premium-or-research"]})
                continue
            normal,bonus=outputs(native,product),outputs(alt,product)
            old_time,new_time=native.get("energy_required",.5),alt.get("energy_required",.5)
            valid=all(isinstance(x,(int,float)) and x>0 for x in
                      (normal,bonus,old_time,new_time))
            ratio=fraction=None
            if valid:
                ratio=(bonus/new_time)/(normal/old_time)
                fraction=bonus/(4*normal)-1
                if fraction<=0 or fraction>.25+1e-6: issues.append("invalid-output-bonus")
                if ratio<1.04-1e-6: issues.append("less-than-four-percent-machine-margin")
            else: issues.append("invalid-product-or-crafting-time")
            standard=ingredients(native)
            premium=ingredients(alt)
            if any(premium.get(key,0)+1e-6<4*qty for key,qty in standard.items()):
                issues.append("native-inputs-reduced")
            source_products=deterministic_results(native)
            upgraded_products=deterministic_results(alt)
            if source_products is None or upgraded_products is None:
                issues.append("non-deterministic-byproducts")
            elif any(upgraded_products.get(key,0)+1e-6<4*qty
                     for key,qty in source_products.items()
                     if key!=("item",product)):
                issues.append("native-byproducts-reduced")
            if alt.get("allow_productivity") is not False or alt.get("auto_recycle") is not False:
                issues.append("unsafe-productivity-or-recycling")
            if alt.get("enabled") is not False: issues.append("recipe-not-research-locked")
            if not any(e.get("type")=="unlock-recipe" and e.get("recipe")==name
                       for e in tech.get("effects") or []):
                issues.append("missing-recipe-unlock")
            late=sorted(ancestors(techs,name) & LATE[stage])
            if late: issues.append("late-stage-ancestor")
            count=(tech.get("unit") or {}).get("count")
            if not isinstance(count,(int,float)) or count<=0:
                issues.append("invalid-research-price")
            rows.append({"stage":stage,"name":name,
                "status":"review" if issues else "verified-prototype-shape",
                "research_units":count,"bonus_fraction":fraction,
                "machine_throughput_ratio":ratio,"late_ancestors":late,
                "issues":sorted(set(issues))})
        subset=[r for r in rows if r["stage"]==stage]
        counts=sorted(r["research_units"] for r in subset
                      if isinstance(r.get("research_units"),(int,float)))
        summary[stage]={"declared":len(definitions),
            "installed":sum(r["status"]!="not-installed" for r in subset),
            "reviews":sum(r["status"]=="review" for r in subset),
            "research_unit_range":[counts[0],counts[-1]] if counts else None}
    return {"stages":summary,"rows":rows,
            "limitations":["No freight cost or platform logistics modeled.",
                           "Absent optional integrations are not errors.",
                           "Use loaded data.raw and live game tests before repricing."]}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dump-data-raw",type=Path,required=True)
    parser.add_argument("--json",action="store_true")
    parser.add_argument("--strict",action="store_true")
    args=parser.parse_args()
    result=inspect(json.loads(args.dump_data_raw.read_text(encoding="utf-8")))
    print(json.dumps(result,indent=2) if args.json else str(result["stages"]))
    return int(args.strict and any(r["status"]=="review" for r in result["rows"]))

if __name__=="__main__":
    raise SystemExit(main())
