-- Single, curated manufacturing portfolio for Balanced and Deep.
-- Native source recipes and technologies are NEVER removed. Retired Razi
-- optional alternatives are not registered on new loads; a save can lose
-- those Razi-only alternate unlocks without losing native production.
local M={}
local retained={
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-electrobiological-components"]=true,
  ["razi-cryo-energy-control"]=true,
  ["razi-gleba-tenebris-biopolymer"]=true,
  ["razi-network-bond-linox-refining"]=true,
  ["razi-modded-vesta-rare-earth-supermagnets"]=true,
  ["razi-first-frontier-relay-components"]=true,
  ["razi-modded-paracelsin-optical-coils"]=true,
  ["razi-modded-moshine-zinc-silicon"]=true,
  ["razi-network-matrix-cryo-controllers"]=true,
  ["razi-network-lattice-vesta-magnets"]=true,
  ["razi-network-bond-paracelsin-coils"]=true,
  ["razi-frontier-castra-composite-rounds"]=true,
  ["razi-network-frame-vesta-foundations"]=true,
  ["razi-network-frame-aquilo-controllers"]=true
}
-- A freight partnership needs to do something distinct, not merely ask
-- for one more colored research card. These are gameplay profiles, not
-- cosmetic labels. No prototype owned by another mod is modified.
--
-- catalytic: the shipped reagent substitutes part of a named *native* input.
-- accelerated: imported hardware improves machine output per second.
-- bulk: material-heavy industrial yield, without a speed shortcut.
local profiles={
  ["razi-bio-rare-metal-casting"]={
    kind="catalytic",conserve="kr-molten-rare-metals",type="fluid",fraction=0.12},
  ["razi-electrobiological-components"]={kind="accelerated"},
  ["razi-cryo-energy-control"]={
    kind="catalytic",conserve="kr-electronic-components",fraction=0.12},
  ["razi-gleba-tenebris-biopolymer"]={kind="bulk"},
  ["razi-network-bond-linox-refining"]={kind="accelerated"},
  ["razi-modded-vesta-rare-earth-supermagnets"]={
    kind="catalytic",conserve="holmium-plate",fraction=0.12},
  ["razi-first-frontier-relay-components"]={kind="accelerated"},
  ["razi-modded-paracelsin-optical-coils"]={
    kind="catalytic",conserve="zinc-rivets",fraction=0.12},
  ["razi-modded-moshine-zinc-silicon"]={
    kind="catalytic",conserve="silicon",fraction=0.12},
  ["razi-network-matrix-cryo-controllers"]={kind="accelerated"},
  ["razi-network-lattice-vesta-magnets"]={kind="bulk"},
  ["razi-network-bond-paracelsin-coils"]={kind="accelerated"},
  ["razi-frontier-castra-composite-rounds"]={kind="accelerated"},
  ["razi-network-frame-vesta-foundations"]={kind="bulk"},
  ["razi-network-frame-aquilo-controllers"]={kind="bulk"}
}
M.profiles=profiles
function M.profile(name) return profiles[name] end

-- Only consume fewer *native* inputs, never the imported cargo itself.
-- Saving rounds down to whole recipe units and never exceeds 12% of the
-- full native batch. Changed mods that remove the ingredient skip this
-- particular optional exchange, preserving all native manufacturing.
function M.conserve(ingredients,profile)
  if not profile or not profile.conserve then return true,0 end
  local expected_type=profile.type or "item"
  for _,ingredient in ipairs(ingredients) do
    if ingredient.name==profile.conserve
      and (ingredient.type or "item")==expected_type then
      if type(ingredient.amount)~="number"
        or ingredient.amount<=0 then return false,0 end
      local saved=math.floor(ingredient.amount*profile.fraction)
      if saved>0 and ingredient.amount-saved>=1 then
        ingredient.amount=ingredient.amount-saved
      end
      return true,saved
    end
  end
  return false,0
end

-- A fast factory still pays for ALL its imported goods. Limit final bonus
-- output per native crafting second to +17%, so the imported specialist
-- equipment cannot become an unchecked free-power multiplier.
function M.time_multiplier(profile,native_amount,batch,bonus,original)
  if not profile or profile.kind~="accelerated" then return original end
  local amount=native_amount*batch
  local minimum=(amount+bonus)/(amount*1.17)
  return math.max(1.06,minimum)
end

M.retained=retained
function M.keep(name) return retained[name]==true end

-- A late supplier can be science-gated without explicitly depending on a
-- system-discovery technology. For example, Moshine optical cable can need
-- Fulgora electromagnetic science. Price the OPTIONAL exchange appropriately
-- without demanding that science pack or an earlier-star card AGAIN.
local science_floors={
  ["metallurgic-science-pack"]=500,
  ["agricultural-science-pack"]=500,
  ["electromagnetic-science-pack"]=950,
  ["cryogenic-science-pack"]=950,
  ["nuclear-science-pack"]=950,
  ["kr-electromagnetic-research-data"]=950,
  ["kr-cryogenic-research-data"]=950,
  ["planet-crucible-science-pack"]=1450,
  ["promethium-science-pack"]=1950
}
function M.science_floor(technology)
  local minimum=0
  local unit=technology and technology.unit
  for _,ingredient in ipairs(unit and unit.ingredients or {}) do
    local name=ingredient.name or ingredient[1]
    minimum=math.max(minimum,science_floors[name] or 0)
  end
  return minimum
end

-- Generic, lab-compatible research is an administrative unlock, never a
-- demand for technology cards from earlier stars. Actual planet and source
-- recipe research prerequisites provide the tier gate; imported ingredients
-- provide the freight challenge.
function M.science(rule)
  local original=rule.science or {}
  local first=original[1]
  if first=="calidus-tech-card" then
    return {"automation-science-pack","logistic-science-pack"}
  end
  if first=="solaris-tech-card" or first=="nyxaris-tech-card" then
    return {"chemical-science-pack","production-science-pack"}
  end
  return {"production-science-pack","utility-science-pack"}
end
return M
