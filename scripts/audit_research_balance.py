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
# Razi-priced mandatory pre-middle discoveries. Nyxaris also needs
# Panglia's independent native data-cell path, so these totals are
# comparable card demand, NOT comparable end-to-end completion times.
FRONTIER_BRANCHES = {
    "solaris": ("planet-discovery-vulcanus", "planet-discovery-castra",
                "planet-discovery-arig", "planet-discovery-hyarion",
                "planet-discovery-tellus", "planet-discovery-corrundum"),
    "nyxaris": ("planet-discovery-gleba", "planet-discovery-moshine",
                "planet-discovery-apia-carnova"),
}
MILESTONES = (
    ("calidus", ("solaris-discovery", "nyxaris-discovery")),
    ("middle", ("vibrant-discovery", "vespera-discovery")),
    ("outer", ("beetlejuice-discovery", "umbra-discovery")),
    ("surveys", ("space-discovery-asteroid-belt",
                 "razi-umbra-belt-survey")),
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


# Optional data-stage redistribution of existing native/source technology.
# This is an audit of the installed result, not an instruction to move every
# research, and not an error when the user disables the startup option.
DISTRIBUTED_TECH = {
    "construction-robotics": ("agricultural-science-pack",),
    "nuclear-power": ("metallurgic-science-pack",
                      "agricultural-science-pack"),
    "logistic-robotics": ("metallurgic-science-pack",
                         "agricultural-science-pack"),
    "personal-roboport-equipment": ("agricultural-science-pack",),
    "logistic-system": ("electromagnetic-science-pack",),
    "nuclear-fuel-reprocessing": ("nuclear-science-pack",),
    "interplanetary-trade-logistics": ("metallurgic-science-pack",
                                      "agricultural-science-pack"),
    "aai-signal-transmission": ("electromagnetic-science-pack",),
}


def distributed_research_status(techs, labs):
    rows = []
    for name, expected in sorted(DISTRIBUTED_TECH.items()):
        node=techs.get(name)
        if not isinstance(node,dict):
            continue
        found=set(science_ingredients(node))
        packs=sorted(found.intersection(expected))
        complete=all(pack in found for pack in expected)
        coverage=sorted(name for name,inputs in labs.items()
                        if found.issubset(inputs)) if found else []
        rows.append({"technology":name, "expected_regional_science":list(expected),
                     "present_regional_science":packs,
                     "status":"distributed" if complete else
                              "native-or-guarded-skip",
                     "compatible_labs":coverage,
                     "requires_full_pack_verification":not complete})
    return rows


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



# Seven optional freight-supported science-card recipes. Source industry
# remains available even when the imported materials are absent.
MULTIPLEX_CARDS = (
    "solaris", "nyxaris", "vibrant", "vespera",
    "beetlejuice", "umbra", "deep-space",
)


def inspect_multiplex_recipes(raw, issues):
    recipes=raw.get("recipe") or {}
    if not isinstance(recipes,dict):
        return []
    rows=[]
    def amounts(recipe, key):
        out={}
        for part in recipe.get(key) or []:
            if isinstance(part,dict):
                name,value=part.get("name"),part.get("amount")
                kind=part.get("type","item")
            elif isinstance(part,list) and len(part)>1:
                name,value,kind=part[0],part[1],"item"
            else:
                continue
            if kind!="fluid" and isinstance(name,str) and isinstance(value,(int,float)):
                out[name]=out.get(name,0)+value
        return out
    for system in MULTIPLEX_CARDS:
        card=system+"-tech-card"
        name="razi-"+system+"-multiplex-cards"
        alternative=recipes.get(name)
        if not isinstance(alternative,dict):
            continue
        base=recipes.get(card)
        if not isinstance(base,dict):
            issues.append({"severity":"error","code":"multiplex-source-missing",
                "targets":[name], "detail":"Freight card recipe has no original synthesis."})
            continue
        base_inputs=amounts(base,"ingredients")
        alt_inputs=amounts(alternative,"ingredients")
        output=amounts(alternative,"results").get(card,0)
        base_output=amounts(base,"results").get(card,0)
        batch=4
        expected=base_output*batch
        imported={ingredient:amount-base_inputs.get(ingredient,0)*batch
                  for ingredient,amount in alt_inputs.items()
                  if amount>base_inputs.get(ingredient,0)*batch}
        baseline_time=base.get("energy_required",0.5)
        alt_time=alternative.get("energy_required",0.5)
        time_ratio=(alt_time/(baseline_time*batch)
                    if isinstance(baseline_time,(int,float)) and baseline_time>0
                    and isinstance(alt_time,(int,float)) else None)
        bonus=(output/expected-1 if expected>0 else None)
        throughput=(output*baseline_time/(base_output*alt_time)-1
                    if base_output>0 and isinstance(alt_time,(int,float))
                    and alt_time>0 and isinstance(baseline_time,(int,float))
                    else None)
        reasons=[]
        if base_output!=1 or output!=5 or bonus is None or bonus>0.25+1e-6:
            reasons.append("Expected exactly five cards from four ordinary batches")
        if not base_inputs or any(
                alt_inputs.get(ingredient,0)<amount*batch
                for ingredient,amount in base_inputs.items()):
            reasons.append("Alternative omits original card manufacturing ingredients")
        if not imported:
            reasons.append("Missing additional imported materials")
        if time_ratio is None or time_ratio<1.15-1e-6:
            reasons.append("Freight recipe must charge 15 percent extra crafting time")
        machines=raw.get("assembling-machine") or {}
        if isinstance(machines,dict) and machines:
            slots=len(alt_inputs)
            compatible=any(
                isinstance(machine,dict) and not machine.get("fixed_recipe")
                and "crafting" in (machine.get("crafting_categories") or [])
                and (machine.get("ingredient_count") is None
                     or machine.get("ingredient_count")>=slots)
                for machine in machines.values())
            if not compatible:
                reasons.append("No existing crafting machine supports all inputs")
        if (alternative.get("allow_productivity") is not False
                or alternative.get("auto_recycle") is not False
                or alternative.get("allow_decomposition") is not False):
            reasons.append("Freight bonus must disable productivity and recycling")
        if reasons:
            issues.append({"severity":"error","code":"multiplex-economy-invalid",
                "targets":[name],"detail":"; ".join(reasons)})
        rows.append({"recipe":name,"card":card,"source_batches":batch,
            "output":output,"gross_bonus_fraction":bonus,
            "machine_throughput_change":throughput,
            "time_multiplier":time_ratio,
            "additional_materials":dict(sorted(imported.items())),
            "status":"review" if reasons else "within-budget",
            "caveat":"Actual item value and cargo shipping still require playtesting."})
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
    branch_card_demand={}
    for system,names in FRONTIER_BRANCHES.items():
        materials=Counter()
        for name in names:
            node=techs.get(name) or {}
            if not isinstance(node,dict) or node.get("enabled") is False:
                continue
            count=(node.get("unit") or {}).get("count")
            if not isinstance(count,(int,float)) or count<=0:
                continue
            for pack,amount in science_ingredients(node).items():
                if pack in SYSTEM_CARDS:
                    materials[pack]+=count*amount
        branch_card_demand[system]={
            "cards":dict(sorted(materials.items())),
            "direct_card_items":sum(materials.values()),
            "researches_checked":sum(name in techs for name in names),
        }
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
    multiplex=inspect_multiplex_recipes(raw,issues)
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
    distributed=distributed_research_status(techs,lab_inputs)
    return {"paired_entries":pairs,"stages":stages,
            "system_card_manufacturing":card_recipes,
            "multiplex_card_economy":multiplex,
            "stage_card_demand":stage_card_demand,
            "first_frontier_card_demand":branch_card_demand,
            "science_lab_coverage":lab_coverage,
            "distributed_technology":distributed,
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
        for name,estimate in report["first_frontier_card_demand"].items():
            if estimate["researches_checked"]:
                print(name+" mandatory branch direct card demand:",
                      estimate["direct_card_items"],
                      "(excludes native Panglia progression)")
        for stage,estimate in report["stage_card_demand"].items():
            if estimate["direct_card_items"]:
                print(stage+" direct card demand:",
                      ", ".join(f"{name}={count:g}" for name,count in
                                estimate["cards"].items()))
        for tech in report["distributed_technology"]:
            print("Distributed tech:",tech["technology"],tech["status"],
                  ", ".join(tech["present_regional_science"]) or
                  "source or compatibility skip")
        for entry in report["multiplex_card_economy"]:
            print(entry["recipe"],entry["status"],"bonus",
                  str(entry["gross_bonus_fraction"]))
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
