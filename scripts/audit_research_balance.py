#!/usr/bin/env python3
"""Research pacing and paired-system independence audit for post-load data.raw.

An advisory report, not a proof that all source-mod science can be produced.
Run on a complete Factorio 2.1 data dump, without launching GitHub Actions.
"""
import argparse
import json
from collections import Counter
from pathlib import Path

PAIRS = (
    ("solaris-discovery", "nyxaris-discovery"),
    ("vibrant-discovery", "vespera-discovery"),
    ("beetlejuice-discovery", "umbra-discovery"),
)
MILESTONES = (
    ("calidus", ("solaris-discovery", "nyxaris-discovery")),
    ("middle", ("vibrant-discovery", "vespera-discovery")),
    ("outer", ("beetlejuice-discovery", "umbra-discovery")),
    ("surveys", ("space-discovery-asteroid-belt",
                 "razi-vespera-belt-survey", "razi-umbra-belt-survey")),
    ("finale", ("razi-outer-frontier-mastery",
                "razi-singularity-theory", "razi-singularity-test-fire",
                "razi-stable-intergalactic-singularity")),
)
# Native science should never appear on the path to its own planet.
# Keep these IDs exact; unknown optional technologies remain advisory.
WORLD_SCIENCE = (
    ("planet-discovery-apia-carnova", "apicultural-science-pack"),
    ("planet-discovery-muria", "muriatic-science-pack"),
    ("planet-discovery-ribbonia", "ribbonia-alien-science-pack"),
    ("planet-discovery-moshine", "thermodynamic-science-pack"),
    ("planet-discovery-paracelsin", "electrochemical-science-pack"),
    ("planet-discovery-aquilo", "cryogenic-science-pack"),
    ("planet-discovery-rubia", "rubia-biofusion-science-pack"),
    ("planet-discovery-tenebris", "bioluminescent-science-pack"),
    ("planet-discovery-crucible", "planet-crucible-science-pack"),
    ("planet-discovery-vesta", "gas-manipulation-science-pack"),
    ("linox-technology_planet-discovery-linox", "linox-item_linox-science-pack"),
)
INDUSTRY = (
    "razi-network-precision-matrix",
    "razi-network-matrix-cryo-controllers",
    "razi-network-matrix-rubia-logistics",
    "razi-network-matrix-linox-refining",
    "razi-network-panglia-optic-bond",
    "razi-network-bond-paracelsin-coils",
    "razi-network-bond-linox-refining",
    "razi-network-extreme-lattice",
    "razi-network-lattice-vesta-magnets",
    "razi-network-lattice-vesta-foundations",
    "razi-network-lattice-balack-shielding",
    "razi-network-umbra-pressure-frame",
    "razi-network-frame-vesta-foundations",
    "razi-network-frame-aquilo-controllers",
)


SYSTEM_CARDS = (
    "calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card",
    "vibrant-tech-card", "vespera-tech-card",
    "beetlejuice-tech-card", "umbra-tech-card", "deep-space-tech-card",
)


def inspect_card_recipes(raw, issues):
    """Audit actual loaded card inputs without changing source prototypes.

    Card dependency cycles are definite errors. Resource availability and
    the ability to research each recipe unlock still need separate audits.
    """
    recipes=raw.get("recipe") or {}
    if not isinstance(recipes,dict):
        return []
    card_set=set(SYSTEM_CARDS)
    rows=[]
    edges={}
    for card in SYSTEM_CARDS:
        recipe=recipes.get(card)
        if not isinstance(recipe,dict):
            continue
        inputs=[]
        for entry in recipe.get("ingredients") or []:
            if isinstance(entry,dict):
                name,amount=entry.get("name"),entry.get("amount",1)
                if entry.get("type")=="fluid":
                    continue
            elif isinstance(entry,list) and entry:
                name,amount=entry[0],entry[1] if len(entry)>1 else 1
            else:
                continue
            if isinstance(name,str):
                inputs.append((name,amount))
        parents=sorted({name for name,_ in inputs if name in card_set})
        native=sorted({name for name,_ in inputs if name not in card_set})
        edges[card]=parents
        rows.append({
            "card":card,
            "required_cards":parents,
            "other_inputs":native,
            "craft_seconds":recipe.get("energy_required"),
            "input_stacks":len(inputs),
            "total_ingredient_items":sum(
                amount for _,amount in inputs
                if isinstance(amount,(int,float))),
        })
    visited=set()
    stack=[]
    reported=set()

    def check_cycle(card):
        if card in stack:
            cycle=stack[stack.index(card):]
            signature=tuple(sorted(cycle))
            if signature not in reported:
                reported.add(signature)
                issues.append({
                    "severity":"error", "code":"system-card-recipe-cycle",
                    "targets":cycle,
                    "detail":"System-card manufacturing recipes depend on one another in a cycle.",
                })
            return
        if card in visited:
            return
        stack.append(card)
        for parent in edges.get(card,[]):
            if parent in edges:
                check_cycle(parent)
        stack.pop()
        visited.add(card)

    for card in SYSTEM_CARDS:
        if card in edges:
            check_cycle(card)
    return rows


def science_ingredients(node):
    unit = node.get("unit") or {}
    if not isinstance(unit, dict):
        return {}
    result = {}
    for entry in unit.get("ingredients") or []:
        if isinstance(entry, dict):
            name, quantity = entry.get("name"), entry.get("amount", 1)
        elif isinstance(entry, list) and entry:
            name, quantity = entry[0], entry[1] if len(entry)>1 else 1
        else:
            continue
        if isinstance(name,str) and isinstance(quantity,(int,float)):
            result[name]=result.get(name,0)+quantity
    return result


def root(raw):
    return raw.get("raw",raw) if isinstance(raw,dict) else {}


def examine(raw):
    raw=root(raw)
    techs=raw.get("technology") or {}
    labs=raw.get("lab") or {}
    if not isinstance(techs,dict):
        techs={}
    lab_inputs={
        name:set(lab.get("inputs") or [])
        for name,lab in labs.items() if isinstance(lab,dict)
    } if isinstance(labs,dict) else {}
    packs=set(raw.get("tool") or {}) | set(raw.get("item") or {})
    tracked=set(INDUSTRY)
    for _,group in MILESTONES: tracked.update(group)
    issues=[]
    reachable_cache={}
    def ancestors(name):
        if name in reachable_cache:
            return reachable_cache[name]
        visited=set()
        def walk(id):
            if id in visited: return
            visited.add(id)
            for parent in (techs.get(id) or {}).get("prerequisites") or []:
                if parent in techs: walk(parent)
        for parent in (techs.get(name) or {}).get("prerequisites") or []:
            if parent in techs: walk(parent)
        reachable_cache[name]=visited
        return visited
    world_science_checks=[]
    native_arrival_errors=[]
    for owner,pack in WORLD_SCIENCE:
        if owner not in techs: continue
        path=sorted(ancestors(owner)|{owner})
        premature=[name for name in path
                   if pack in science_ingredients(techs.get(name) or {})]
        world_science_checks.append({
            "world_discovery":owner,"science_pack":pack,
            "status":"blocked" if premature else "safe",
            "premature_requirements":premature
        })
        if premature:
            violation={"severity":"error","code":"own-world-science-before-arrival",
                "targets":[owner],"packs":[pack],
                "techs":premature,
                "detail":"A planet's own science appears on its discovery path."}
            issues.append(violation)
            native_arrival_errors.append(violation)
    pairs=[]
    for left,right in PAIRS:
        a,b=techs.get(left),techs.get(right)
        if not a or not b:
            pairs.append({"left":left,"right":right,"status":"not-installed"})
            continue
        ab=left in ancestors(right)
        ba=right in ancestors(left)
        a_count=(a.get("unit") or {}).get("count")
        b_count=(b.get("unit") or {}).get("count")
        ratio=None
        if (isinstance(a_count,(int,float)) and a_count>0
            and isinstance(b_count,(int,float)) and b_count>0):
            ratio=round(max(a_count,b_count)/min(a_count,b_count),3)
        pairs.append({"left":left,"right":right,
                      "status":"coupled" if ab or ba else "independent",
                      "counts":[a_count,b_count],"cost_ratio":ratio})
        if ab or ba:
            issues.append({"severity":"error","code":"paired-gates-dependent",
                "targets":[left,right],
                "detail":"One parallel system entrance depends on the other."})
        if ratio is not None and ratio>1.35:
            issues.append({"severity":"advisory","code":"uneven-paired-entry",
                "targets":[left,right],
                "detail":"Paired system gate research-unit prices differ by over 35%."})
    stages={}
    used_packs=Counter()
    missing_packs={}
    lab_gaps={}
    lab_coverage={}
    for label,group in MILESTONES:
        rows=[]
        for name in group:
            node=techs.get(name)
            if not isinstance(node,dict) or node.get("hidden"):
                continue
            science=science_ingredients(node)
            count=(node.get("unit") or {}).get("count")
            cost=sum(science.values())*count if isinstance(count,(int,float)) else None
            rows.append({"name":name,"research_units":count,
                         "science_types":list(science),
                         "total_science_items":cost})
        stages[label]=rows
    for name,node in techs.items():
        if not isinstance(node,dict) or node.get("hidden") or node.get("enabled") is False:
            continue
        if not (name.startswith("razi-") or name in tracked):
            continue
        science=science_ingredients(node)
        for pack in science: used_packs[pack]+=1
        absent=sorted(pack for pack in science if pack not in packs)
        if absent and packs:
            missing_packs[name]=absent
            issues.append({"severity":"error","code":"unknown-science-item",
                "targets":[name],"packs":absent,
                "detail":"Required science item is absent from loaded item/tool prototypes."})
        if science:
            compatible=sorted(
                lab for lab,accepted in lab_inputs.items()
                if set(science).issubset(accepted))
            lab_coverage[name]=compatible
            if lab_inputs and not compatible:
                lab_gaps[name]=sorted(science)
                issues.append({"severity":"error","code":"no-shared-science-lab",
                    "targets":[name],"packs":sorted(science),
                    "detail":"No installed laboratory accepts this complete science set."})
    card_recipes=inspect_card_recipes(raw,issues)
    # Count the direct card demand of each campaign stage, rather than
    # equating a cheap research unit with an expensive late-tier card.
    # This deliberately excludes recursive precursor manufacturing and
    # machine speed: the result is a research order-of-magnitude report.
    stage_card_demand={}
    for stage,rows in stages.items():
        demanded=Counter()
        for row in rows:
            count=row["research_units"]
            if not isinstance(count,(int,float)) or count<=0:
                continue
            for card,amount in science_ingredients(
                    techs.get(row["name"]) or {}).items():
                if card in SYSTEM_CARDS:
                    demanded[card]+=count*amount
        stage_card_demand[stage]={
            "cards":dict(sorted(demanded.items())),
            "direct_card_items":sum(demanded.values())
        }
    research_prices=[]
    science_reuse=Counter()
    for name in INDUSTRY:
        node=techs.get(name)
        if (not isinstance(node,dict) or node.get("hidden")
            or node.get("enabled") is False): continue
        count=(node.get("unit") or {}).get("count")
        if isinstance(count,(int,float)) and count>0:
            required=science_ingredients(node)
            research_prices.append({"name":name,"units":count,
                                    "science_types":list(required)})
            for _,pack in WORLD_SCIENCE:
                if pack in required: science_reuse[pack]+=1
    # Only flag extreme spikes within the Razi factory-upgrade family;
    # not across source mods with radically different research economies.
    counts=sorted(x["units"] for x in research_prices)
    if counts:
        # For a small optional-mod pack, use the lower median so an
        # isolated huge price does not become its own baseline.
        typical=counts[(len(counts)-1)//2]
        for row in research_prices:
            if row["units"]>max(2000,typical*2.7):
                issues.append({"severity":"advisory","code":"factory-price-spike",
                    "targets":[row["name"]],"units":row["units"],
                    "median":typical,
                    "detail":"Razi industrial research is unusually expensive."})
    return {"paired_entries":pairs,"stages":stages,
            "system_card_manufacturing":card_recipes,
            "stage_card_demand":stage_card_demand,
            "science_lab_coverage":lab_coverage,
            "world_science_arrival_checks":world_science_checks,
            "native_arrival_errors":native_arrival_errors,
            "planetary_science_reuse":dict(sorted(science_reuse.items())),
            "industry_research_prices":research_prices,
            "science_usage":dict(sorted(used_packs.items())),
            "missing_science_prototypes":missing_packs,
            "unresearchable_lab_combinations":lab_gaps,
            "issues":issues,
            "errors":[issue for issue in issues if issue["severity"]=="error"],
            "advisories":[issue for issue in issues if issue["severity"]=="advisory"],
            "limitations":[
                "Native science prototype and lab acceptance do not prove a producible recipe.",
                "Travel, transport, crafting surfaces and scripted unlockers need in-game validation.",
                "Research price outliers are suggestions, not automatic source-mod rewrites."
            ]}


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dump",type=Path,help="Factorio post-load data.raw JSON")
    parser.add_argument("--json",action="store_true")
    parser.add_argument("--strict",action="store_true",
                        help="Exit with failure if definite paired-gate or science errors appear")
    args=parser.parse_args(argv)
    with args.dump.open(encoding="utf-8") as stream:
        raw=json.load(stream)
    if not isinstance(root(raw).get("technology"),dict):
        parser.error("Expected a post-load technology prototype table")
    report=examine(raw)
    if args.json:
        print(json.dumps(report,indent=2))
    else:
        for pair in report["paired_entries"]:
            print(pair["left"],"/",pair["right"],":",pair["status"])
        for stage,rows in report["stages"].items():
            print(stage+":",", ".join(
                x["name"]+"="+str(x["research_units"]) for x in rows)
                or "not installed")
        for stage,estimate in report["stage_card_demand"].items():
            if estimate["direct_card_items"]:
                print(stage+" direct card demand:",
                      ", ".join(f"{name}={count:g}" for name,count in
                                estimate["cards"].items()))
        if report["planetary_science_reuse"]:
            print("Reused planetary sciences:",
                  ", ".join(f"{k} ({v} techs)" for k,v in
                            report["planetary_science_reuse"].items()))
        for issue in report["issues"]:
            print(issue["severity"].upper()+":",issue["code"],
                  ", ".join(issue["targets"]))
        print("This is a source analysis, not a full manufacturing or route simulation.")
    return 1 if args.strict and report["errors"] else 0


if __name__=="__main__":
    raise SystemExit(main())
