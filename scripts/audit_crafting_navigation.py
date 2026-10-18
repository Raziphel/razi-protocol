#!/usr/bin/env python3
"""Inspect recipe-navigation clutter in a post-load Factorio data.raw JSON dump.

Advisory only. This does not change recipes or claim any mod is broken.
Usage: python scripts/audit_crafting_navigation.py --dump-data-raw dump.json
"""
from __future__ import annotations
import argparse
from collections import Counter
import json
from pathlib import Path
import re

def objects(value):
    return value if isinstance(value,dict) else {}

def entries(value):
    return value if isinstance(value,list) else []

def component(entry):
    if isinstance(entry,dict):
        return entry.get("type","item"),entry.get("name")
    if isinstance(entry,(list,tuple)) and entry:
        return "item",entry[0]
    return None,None

def has(parts,kind,predicate):
    return any(t==kind and isinstance(n,str) and predicate(n)
               for t,n in map(component,entries(parts)))

def barrel_recipe(name,recipe):
    """Mirror the conservative, name AND actual ingredient/product Lua guard."""
    if not isinstance(recipe,dict) or recipe.get("hidden") or recipe.get("hide_from_player_crafting"):
        return False
    filling=re.fullmatch(r"fill-.+-barrel",name) is not None
    emptying=re.fullmatch(r"empty-.+-barrel",name) is not None
    if not (filling or emptying):
        return False
    inputs=recipe.get("ingredients")
    outputs=recipe.get("results")
    filled=lambda n:n!="empty-barrel" and n.endswith("-barrel")
    if filling:
        return (has(inputs,"fluid",lambda n:True)
                and has(inputs,"item",lambda n:n=="empty-barrel")
                and has(outputs,"item",filled))
    return (has(inputs,"item",filled)
            and has(outputs,"fluid",lambda n:True)
            and has(outputs,"item",lambda n:n=="empty-barrel"))

def spoilable_recipe(recipe,items,subgroups):
    """Match the opt-in, source-preserving intermediate-only Lua rule."""
    if recipe.get("hidden") or recipe.get("hide_from_player_crafting"):
        return False
    products=entries(recipe.get("results"))
    if len(products)!=1:
        return False
    kind,name=component(products[0])
    if kind=="fluid" or not name:
        return False
    item=objects(items.get(name))
    if not isinstance(item.get("spoil_ticks"),(int,float)) or item["spoil_ticks"]<=0:
        return False
    subgroup=objects(subgroups.get(recipe.get("subgroup") or item.get("subgroup")))
    return subgroup.get("group")=="intermediate-products"

def analyze(document):
    raw=objects(document)
    raw=objects(raw.get("raw")) or raw
    recipes=objects(raw.get("recipe"))
    items=objects(raw.get("item"))
    subgroups=objects(raw.get("item-subgroup"))
    groups=objects(raw.get("item-group"))
    grouped=Counter()
    barrel_candidates=[]
    barrel_name_only=[]
    source_owned_barrels=[]
    spoilable_candidates=[]
    hidden_count=0
    for name,recipe in sorted(recipes.items()):
        if not isinstance(recipe,dict):
            continue
        if recipe.get("hidden") or recipe.get("hide_from_player_crafting"):
            hidden_count+=1
            continue
        source=objects(subgroups.get(recipe.get("subgroup")))
        group=source.get("group")
        if not group:
            group="unspecified"
        grouped[group]+=1
        matches_name=bool(re.fullmatch(r"(?:fill|empty)-.+-barrel",name))
        if matches_name:
            if not barrel_recipe(name,recipe):
                barrel_name_only.append(name)
            elif recipe.get("subgroup") and group!="fluids":
                source_owned_barrels.append(name)
            else:
                barrel_candidates.append(name)
        if spoilable_recipe(recipe,items,subgroups):
            spoilable_candidates.append(name)
    return {
        "total_recipes":len(recipes),
        "visible_recipes":sum(grouped.values()),
        "hidden_recipes":hidden_count,
        "group_distribution":dict(sorted(grouped.items())),
        "barrel_group_available":"fluids" in groups,
        "verified_barrel_candidates":barrel_candidates,
        "barrel_named_but_unverified":barrel_name_only,
        "barrel_recipes_with_custom_groups":source_owned_barrels,
        "optional_spoilable_candidates":spoilable_candidates,
        "notes":[
            "Source-owned custom recipe tabs are never overwritten.",
            "Grouping changes visible recipe.subgroup only, not craftability.",
            "Missing mods and source-crafting capabilities require live checks.",
        ],
    }

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dump-data-raw",type=Path,required=True)
    parser.add_argument("--json",action="store_true")
    args=parser.parse_args()
    with args.dump_data_raw.open(encoding="utf-8") as source:
        report=analyze(json.load(source))
    if args.json:
        print(json.dumps(report,indent=2))
    else:
        print("Recipe navigation audit:",report["total_recipes"],"recipes,",
              report["visible_recipes"],"visible")
        for name in ("verified_barrel_candidates","barrel_named_but_unverified",
                     "barrel_recipes_with_custom_groups","optional_spoilable_candidates"):
            print(name.replace("_"," ").title()+":",len(report[name]))
            for item in report[name][:15]:
                print("  ",item)
        print("Native fluids group available:",report["barrel_group_available"])
        print("Review this with the full modpack; this is not a live crafting test.")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
