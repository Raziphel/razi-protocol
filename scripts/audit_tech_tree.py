#!/usr/bin/env python3
"""Advisory Factorio 2.1 technology graph audit for very large planet packs."""
import argparse
import json
from pathlib import Path
import re

def obj(value):
    return value if isinstance(value, dict) else {}

def ingredient_name(value):
    if isinstance(value, dict):
        return value.get("name")
    if isinstance(value, list) and value:
        return value[0]
    return None

def catalogued_planets():
    """Read the one authoritative Lua planet list rather than duplicating IDs."""
    path=Path(__file__).resolve().parents[1] / "prototypes/technology/planetary_unification.lua"
    text=path.read_text(encoding="utf-8")
    match=re.search(r"local worlds=\{(.*?)\}\s*M\.worlds=worlds",text,re.S)
    if not match:
        raise ValueError("Required planet discovery catalog is missing")
    return re.findall(r'"([^"]+)"',match.group(1))

def final_planet_coverage(techs,locations):
    """Which native discoveries are truly ancestors of the Razi finale?"""
    names=catalogued_planets()
    unlockers={}
    for name,technology in techs.items():
        if technology.get("hidden") or technology.get("enabled") is False:
            continue
        for effect in technology.get("effects",[]):
            if effect.get("type")=="unlock-space-location":
                loc=effect.get("space_location")
                unlockers.setdefault(loc,set()).add(name)
    visited=set()
    def walk(name):
        if name in visited or name not in techs:
            return
        visited.add(name)
        for p in techs[name].get("prerequisites",[]):
            walk(p)
    walk("razi-stable-intergalactic-singularity")
    active=[name for name in names if name in locations]
    covered={}
    ungated={}
    scripted=[]
    for loc in active:
        choices=sorted(unlockers.get(loc,()))
        if not choices:
            scripted.append(loc)
        elif any(name in visited for name in choices):
            covered[loc]=[name for name in choices if name in visited]
        else:
            ungated[loc]=choices
    return {
        "catalogued_worlds_present":len(active),
        "on_singularity_path":len(covered),
        "missing_from_finale":ungated,
        "no_native_research_unlock":sorted(scripted)
    }

def analyze(raw):
    raw=obj(raw)
    raw=obj(raw.get("raw")) or raw
    techs=obj(raw.get("technology"))
    labs=obj(raw.get("lab"))
    locations={**obj(raw.get("planet")),**obj(raw.get("space-location"))}
    invalid={}
    for name,t in techs.items():
        if t.get("hidden") or t.get("enabled") is False:
            continue
        missing=sorted(p for p in t.get("prerequisites",[]) if p not in techs)
        if missing: invalid[name]=missing
    visited=set()
    active={}
    cycles=set()
    def dfs(name,path):
        if name in active:
            loop=path[active[name]:]+[name]
            core=loop[:-1]
            rotations=[tuple(core[i:]+core[:i]) for i in range(len(core))]
            cycles.add(min(rotations))
            return
        if name in visited or name not in techs:
            return
        active[name]=len(path)
        for parent in techs[name].get("prerequisites",[]):
            dfs(parent,path+[name])
        active.pop(name)
        visited.add(name)
    for name in sorted(techs):
        dfs(name,[])
    labs_supported=[set(lab.get("inputs",[])) for lab in labs.values()]
    impossible_labs={}
    for name,t in techs.items():
        if t.get("hidden") or t.get("enabled") is False: continue
        unit=obj(t.get("unit"))
        required={ingredient_name(x) for x in unit.get("ingredients",[])}
        required.discard(None)
        if required and not any(required.issubset(s) for s in labs_supported):
            impossible_labs[name]=sorted(required)
    location_unlocks=set()
    for tech in techs.values():
        for effect in tech.get("effects",[]):
            if effect.get("type")=="unlock-space-location":
                location_unlocks.add(effect.get("space_location"))
    unlinked=sorted(n for n,p in locations.items()
                    if not p.get("hidden") and n not in location_unlocks)
    return {
        "planetary_milestone_coverage":final_planet_coverage(techs,locations),
        "technologies":len(techs),
        "prerequisite_cycles":[list(x) for x in sorted(cycles)],
        "missing_prerequisites":invalid,
        "unresearchable_science_combinations":impossible_labs,
        "locations_without_research_unlock":unlinked
    }

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dump-data-raw",type=Path,required=True)
    parser.add_argument("--json",action="store_true")
    args=parser.parse_args()
    with args.dump_data_raw.open(encoding="utf8") as source:
        result=analyze(json.load(source))
    if args.json:
        print(json.dumps(result,indent=2))
    else:
        print("Research technologies:",result["technologies"])
        world=result["planetary_milestone_coverage"]
        print("Razi planet discovery coverage:",
              world["on_singularity_path"],"/",world["catalogued_worlds_present"])
        if world["missing_from_finale"]:
            print("  World discoveries outside finale:",
                  ", ".join(sorted(world["missing_from_finale"])))
        if world["no_native_research_unlock"]:
            print("  Worlds using scripted/nonstandard unlocks:",
                  ", ".join(world["no_native_research_unlock"]))
        for key in ("prerequisite_cycles","missing_prerequisites",
                    "unresearchable_science_combinations",
                    "locations_without_research_unlock"):
            entries=result[key]
            print(key.replace("_"," ").title()+":",len(entries))
            if isinstance(entries,dict):
                for name,detail in sorted(entries.items())[:18]:
                    print("  ",name,":",", ".join(detail))
            else:
                for row in entries[:18]: print("  ",row)
        print("Note: special/scripted unlocks and modded labs need in-game review.")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
