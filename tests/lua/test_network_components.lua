---@diagnostic disable: missing-fields, need-check-nil, assign-type-mismatch, undefined-field, param-type-mismatch, inject-field
-- Shared factory component registration and menu wiring.
-- Uses source-like mock prototypes, no Factorio runtime required.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,message) if not v then error(message,2) end end
local function copy(a)
  if type(a)~="table" then return a end
  local b={}
  for k,v in pairs(a) do b[copy(k)]=copy(v) end
  return b
end
rawset(table,"deepcopy",copy)
local supplier_names={
 "optical-cable","zinc-plate","holmium-plate","kr-rare-metals",
 "craptonite-frame","chitosan","rare-earth-powder","carbon-fiber",
 "panglia_panglite_glass","supermagnet"
}
local source_recipe={
 ["optical-cable"]="optical-cable",
 ["zinc-plate"]="zinc-plate",
 ["holmium-plate"]="holmium-plate",
 ["kr-rare-metals"]="kr-casting-rare-metals",
 ["craptonite-frame"]="craptonite-casting",
 ["chitosan"]="chitosan",
 ["rare-earth-powder"]="linox-recipe_rare-earth-refining",
 ["carbon-fiber"]="carbon-fiber",
 ["panglia_panglite_glass"]="panglia_panglite_glass",
 ["supermagnet"]="supermagnet"
}
local worlds={
 "planet-discovery-vulcanus","planet-discovery-moshine",
 "planet-discovery-fulgora","planet-discovery-paracelsin",
 "planet-discovery-rubia","planet-discovery-tenebris",
 "linox-technology_planet-discovery-linox","planet-discovery-gleba",
 "panglia_planet_discovery_panglia","planet-discovery-crucible",
 "planet-discovery-vesta","planet-discovery-aquilo"
}
local function setup(options)
  options=options or {}
  -- Factorio 2.1: the base science packs are "item" prototypes, the system
  -- tech cards and the Crucible pack are "tool" prototypes.
  local raw={technology={},recipe={},item={
   ["chemical-science-pack"]={},["production-science-pack"]={},
   ["utility-science-pack"]={}
  },tool={
   ["solaris-tech-card"]={},["nyxaris-tech-card"]={},
   ["vibrant-tech-card"]={},["vespera-tech-card"]={},
   ["beetlejuice-tech-card"]={},["umbra-tech-card"]={},
   ["planet-crucible-science-pack"]={
     icon="__base__/graphics/icons/iron-plate.png",icon_size=64}
  },lab={standard={inputs={"chemical-science-pack",
      "production-science-pack","utility-science-pack",
      "solaris-tech-card","nyxaris-tech-card",
      "vibrant-tech-card","vespera-tech-card",
      "beetlejuice-tech-card","umbra-tech-card"}}},
   ["assembling-machine"]={factory={crafting_categories={"crafting"}}}}
  for _,name in ipairs(supplier_names) do
    raw.item[name]={icon="__base__/graphics/icons/iron-plate.png",icon_size=64}
    raw.recipe[source_recipe[name]]={
      name=source_recipe[name],type="recipe",enabled=true,
      ingredients={{type="item",name="iron-plate",amount=1}},
      results={{type="item",name=name,amount=2}}
    }
  end
  raw.recipe["planet-crucible-science-pack"]={
    name="planet-crucible-science-pack",type="recipe",enabled=true,
    ingredients={{type="item",name="iron-plate",amount=1}},
    results={{type="item",name="planet-crucible-science-pack",amount=1}}
  }
  raw.item["iron-plate"]={icon="__base__/graphics/icons/iron-plate.png",
   icon_size=64}
  for _,world in ipairs(worlds) do raw.technology[world]={
    prerequisites={},icon="__base__/graphics/technology/automation.png",
    icon_size=256} end
  if options.lock_optics then
    raw.recipe["optical-cable"].enabled=false
    raw.technology["native-optics"]={prerequisites={},
      effects={{type="unlock-recipe",recipe="optical-cable"}}}
  end
  if options.hide_optics then raw.item["optical-cable"].hidden=true end
  if options.remove_linox then raw.recipe["linox-recipe_rare-earth-refining"]=nil end
  if options.no_lab then raw.lab={} end
  local data={raw=raw}
  function data:extend(prototypes)
    for _,v in ipairs(prototypes) do
      self.raw[v.type]=self.raw[v.type] or {}
      check(not self.raw[v.type][v.name],"Duplicate shared industry prototype")
      self.raw[v.type][v.name]=v
    end
  end
  rawset(_G,"data",data)
  local mods={
    ["Krastorio2-spaced-out"]="2.0.17",Moshine="1.0",
    Paracelsin="1.0",rubia="1.0",["tenebris-prime"]="1.0",linox="1.0",
    ["panglia_planet"]="1.0",["skewer_planet_vesta"]="1.0",
    ["planet-crucible"]="1.0"
  }
  if options.missing_mod then mods.linox=nil end
  if options.no_panglia then mods.panglia_planet=nil end
  if options.no_crucible then mods["planet-crucible"]=nil end
  rawset(_G,"mods",mods)
  if options.off or options.deep then
    rawset(_G,"settings",{startup={
      ["razi-planetary-interdependence"]={
        value=options.off and "off" or "deep"}
    }})
  else rawset(_G,"settings",nil) end
  local calls={k2=0,modded=0,deep=0}
  package.loaded["prototypes.compat.planet_production_exchanges"]={
    register_k2so_balanced=function(rules)
      calls.k2=calls.k2+#rules
    end,
    register_additional=function(rules)
      if rules[1] and rules[1].deep_only then
        calls.deep=calls.deep+#rules
      else calls.modded=calls.modded+#rules end
    end
  }
  package.loaded["prototypes.compat.network_components"]=nil
  return raw,require("prototypes.compat.network_components"),calls
end
local raw,module,calls=setup({lock_optics=true})
module.data_final_fixes()
local matrix="razi-network-precision-matrix"
local lattice="razi-network-extreme-lattice"
local bond="razi-network-panglia-optic-bond"
local frame="razi-network-umbra-pressure-frame"
for _,name in ipairs({matrix,lattice,bond}) do
  local item,recipe,tech=raw.item[name],raw.recipe[name],raw.technology[name]
  check(item and recipe and tech,"Expected guarded cross-system components")
  check(recipe.enabled==false and recipe.auto_recycle==false,
    "Component cannot be automatically recycled or auto-unlocked")
  check(recipe.categories and recipe.categories[1]=="crafting"
      and recipe.category==nil and recipe.additional_categories==nil,
    "Component recipe must use Factorio 2.1's unified categories field")
  check(recipe.allow_productivity==false,"Intermediate is productivity-safe")
  check(recipe.results[1].amount==(name==bond and 8 or 2),
    "Initial and return-cargo components must keep their balanced batch size")
  check(#tech.unit.ingredients==2,"No five-pack research soup")
  check(item.icons and #item.icons>=2,
    "Portable component should have a distinctive layered source icon")
end
local function has(tech,id)
  for _,p in ipairs(tech.prerequisites or {}) do
    if p==id then return true end
  end
  return false
end
check(has(raw.technology[matrix],"native-optics"),
  "Missing real source technology for optical cable")
check(has(raw.technology[lattice],matrix),
  "Outer lattice must unlock after the earlier matrix technology")
local matrix_inputs=raw.recipe[matrix].ingredients
check(#matrix_inputs==4,"Precision part no longer has four distinct exports")
check(#raw.recipe[lattice].ingredients==5,
  "Extreme part no longer uses earlier framework + four exports")
check(#raw.recipe[bond].ingredients==3
  and raw.technology[bond].unit.count==360
  and raw.recipe[bond].energy_required==10
  and has(raw.technology[bond],"panglia_planet_discovery_panglia"),
  "Panglia optical export is not tied to its native glass factory")
check(not raw.item[frame] and not raw.recipe[frame]
  and not raw.technology[frame],
  "Balanced has no consumer for the Pressure Frame, so it must not exist")
for _,part in ipairs({matrix,lattice,bond}) do
  for _,entry in ipairs(raw.technology[part].unit.ingredients) do
    check(not entry[1]:find("tech%-card"),
      "Network component must not charge earlier-system tech cards")
  end
end
module.register_premium()
check(calls.k2==1 and calls.modded==3 and calls.deep==0,
  "Premium recipes were not partitioned into source-owned factories")
for _,group in ipairs({
  module.premium.k2,module.premium.modded,module.premium.return_modded,
  module.premium.pressure_modded
}) do
  for _,rule in ipairs(group) do
    check(rule.batch==4 and rule.bonus==1 and rule.max_bonus_fraction==0.25,
      "Premium manufacturing reward exceeds 25% of its native batch")
    check(rule.additional[1].amount==1 and rule.require_supplier_provenance,
      "Premium recipe must consume a guarded imported part")
  end
end
for i,rule in ipairs(module.premium.return_modded) do
  check(rule.target_bonus_fraction==0.20 and rule.time_multiplier==1.10
    and rule.count==(i==1 and 520 or 650),
    "Panglia bonds must fund useful, affordable downstream recipes")
end
check(module.premium.pressure_modded[1].target_bonus_fraction==0.20
  and module.premium.pressure_modded[1].time_multiplier==1.12
  and module.premium.pressure_modded[1].count==960
  and module.premium.pressure_modded[1].deep_only,
  "Bulk Vesta foundations must earn a native-output-scaled bonus in Deep only")
-- The components sit together in the research menu and are essential.
check(raw.technology[matrix].essential and raw.technology[bond].essential
  and raw.technology[lattice].essential,
  "The network components must be marked essential")
check(raw.technology[matrix].order=="f[razi-industry]-a[precision]"
  and raw.technology[bond].order=="f[razi-industry]-b[panglia]"
  and raw.technology[lattice].order=="f[razi-industry]-c[lattice]",
  "The network components must be ordered by family")
module.data_final_fixes()
check(#raw.recipe[lattice].ingredients==5,
  "Repeated registration should preserve production identities")
for _,case in ipairs({
 {hide_optics=true},{remove_linox=true},{no_lab=true},
 {missing_mod=true},{off=true}
}) do
  local raw_case,mock,actions=setup(case)
  mock.data_final_fixes()
  if case.remove_linox or case.missing_mod then
    check(raw_case.item[matrix] and not raw_case.item[lattice],
      "Missing Linox should suppress the lattice, not the earlier matrix")
  else
    check(not raw_case.item[matrix] and not raw_case.item[lattice],
      "Missing/off source unexpectedly produced manufacturing component")
  end
  mock.register_premium()
  if case.remove_linox or case.missing_mod then
    check(actions.k2==1,"Early matrix should remain usable without Linox recipe")
  else
    check(actions.k2==0 and actions.modded==0 and actions.deep==0,
      "Skipped network must not publish premium recipes")
  end
end
-- Pressure Frame is a four-import industrial component that only Deep
-- consumes, so only Deep creates it.
local deep_raw,deep_network,deep_calls=setup({deep=true})
deep_network.data_final_fixes()
check(deep_raw.item[frame] and deep_raw.recipe[frame]
  and deep_raw.technology[frame],"Deep return-cargo component missing")
check(has(deep_raw.technology[frame],bond)
  and has(deep_raw.technology[frame],"planet-discovery-crucible")
  and has(deep_raw.technology[frame],"planet-discovery-vesta"),
  "Pressure framework must wait for Panglia, Crucible and Vesta")
check(#deep_raw.recipe[frame].ingredients==4
  and deep_raw.recipe[frame].results[1].amount==8
  and deep_raw.recipe[frame].energy_required==20
  and deep_raw.technology[frame].unit.count==980
  and deep_raw.recipe[frame].allow_productivity==false,
  "Deep framework must consume all source exports without productivity")
deep_network.register_premium()
check(deep_calls.k2==1 and deep_calls.modded==3 and deep_calls.deep==1,
  "Deep framework must feed one Vesta sink")
check(deep_raw.technology[frame].essential
  and deep_raw.technology[frame].order=="f[razi-industry]-d[pressure]",
  "The Pressure Frame must be essential and ordered")
deep_network.data_final_fixes()
check(deep_raw.recipe[frame].ingredients[2].name=="holmium-plate",
  "Deep Pressure Frame must ship real metal rather than consume science")

local missing_panglia,panglia_network=setup({no_panglia=true,deep=true})
panglia_network.data_final_fixes()
check(not missing_panglia.item[bond] and not missing_panglia.item[frame],
  "An absent source planet must not fabricate an export chain")
local missing_crucible,crucible_network=setup({no_crucible=true,deep=true})
crucible_network.data_final_fixes()
check(missing_crucible.item[bond] and not missing_crucible.item[frame],
  "Removing Crucible must only suppress its dependent framework")

-- Research links: exchanges that return Panglia cargo follow Panglia's own
-- optics research; Deep also asks the networks to cooperate. A link is never
-- added when it would close a cycle.
local function tech_node(prerequisites)
  return {prerequisites=prerequisites or {},
    icon="__base__/graphics/technology/automation.png",icon_size=256}
end
local function linked(options)
  local state,network=setup(options)
  network.data_final_fixes()
  state.technology["panglia_advanced_optics_nanotech"]=tech_node()
  for _,name in ipairs({"razi-network-bond-paracelsin-coils",
    "razi-network-bond-linox-refining","razi-network-lattice-vesta-magnets",
    "razi-network-frame-vesta-foundations"}) do
    state.technology[name]=tech_node({bond})
  end
  network.register_premium()
  return state
end
local balanced=linked()
check(has(balanced.technology["razi-network-bond-paracelsin-coils"],
    "panglia_advanced_optics_nanotech")
  and has(balanced.technology["razi-network-bond-linox-refining"],
    "panglia_advanced_optics_nanotech"),
  "Panglia return exchanges must follow Panglia's optics research")
check(#balanced.technology["razi-network-lattice-vesta-magnets"].prerequisites==1,
  "Balanced must not link the Deep-only cooperation edges")
local deepest=linked({deep=true})
check(has(deepest.technology[frame],lattice)
  and has(deepest.technology["razi-network-frame-vesta-foundations"],
    "razi-network-lattice-vesta-magnets"),
  "Deep must link the Pressure Frame to the lattice network")
-- A parent that already depends on the target would close a cycle.
local cyclic,cyclic_network=setup()
cyclic_network.data_final_fixes()
cyclic.technology["panglia_advanced_optics_nanotech"]=tech_node(
  {"razi-network-bond-paracelsin-coils"})
cyclic.technology["razi-network-bond-paracelsin-coils"]=tech_node({bond})
cyclic_network.register_premium()
check(not has(cyclic.technology["razi-network-bond-paracelsin-coils"],
  "panglia_advanced_optics_nanotech"),"A research link must never create a cycle")
rawset(_G,"settings",nil)

-- Wiring in data-final-fixes: the components exist before the exchanges that
-- consume them, and the return-cargo exchanges run after the research passes.
local handle=assert(io.open("data-final-fixes.lua","r"))
local source=handle:read("*a")
handle:close()
local function position(call)
  return assert(source:find(call,1,true),"Not wired in data-final-fixes: "..call)
end
local parts=position('require("prototypes.compat.network_components").data_final_fixes()')
check(parts<position('require("prototypes.compat.planet_production_exchanges").data_final_fixes()')
  and parts<position('require("prototypes.compat.modded_planet_exchanges").data_final_fixes()'),
  "Components must be created before their exchange recipes")
local visibility=position('require("prototypes.technology.tech_tree_visibility").data_final_fixes()')
check(position('require("prototypes.compat.first_frontier_industry").data_final_fixes()')>visibility
  and position('require("prototypes.compat.network_components").register_premium()')>visibility,
  "Return-cargo exchanges must run after the research passes")
print("Shared factory parts, guarded return cargo and premium sinks passed")
