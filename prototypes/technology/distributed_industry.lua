-- Native and modded technologies earned from real planetary industries.
-- This operates on the final loaded prototype graph, never on players,
-- inventories, recipes or technology IDs. Old researched tech stays researched.
local M={}
local function active(node)
  return node and node.enabled~=false and node.hidden~=true
end
local function reaches(techs,source,target,seen)
  if source==target then return true end
  local node=techs[source]
  if not node then return false end
  seen=seen or {}
  if seen[source] then return false end
  seen[source]=true
  for _,parent in ipairs(node.prerequisites or {}) do
    if reaches(techs,parent,target,seen) then return true end
  end
  return false
end
M.reaches=reaches

-- This is a deliberate selection, not an all-technologies scan. It never
-- gates rockets, robot frames, labs, the first two discoveries, or science
-- producers behind technologies which those very systems need to bootstrap.
M.core={
  {tech="construction-robotics",stage="gleba",
    parents={"planet-discovery-gleba","agricultural-science-pack"},
    packs={"agricultural-science-pack"}},
  {tech="nuclear-power",stage="first-pair",
    parents={"planet-discovery-vulcanus","planet-discovery-gleba",
      "metallurgic-science-pack","agricultural-science-pack"},
    packs={"metallurgic-science-pack","agricultural-science-pack"}},
  {tech="logistic-robotics",stage="first-pair",
    parents={"planet-discovery-vulcanus","planet-discovery-gleba",
      "metallurgic-science-pack","agricultural-science-pack"},
    packs={"metallurgic-science-pack","agricultural-science-pack"}},
  {tech="personal-roboport-equipment",stage="gleba",
    parents={"construction-robotics","agricultural-science-pack"},
    packs={"agricultural-science-pack"}},
  {tech="logistic-system",stage="fulgora",
    parents={"planet-discovery-fulgora","electromagnetic-science-pack"},
    packs={"electromagnetic-science-pack"}},
  -- Cerys has its own optional nuclear science in the curated pack.
  -- Fuel reprocessing is a late efficiency reward, never needed to
  -- operate reactors or make the first nuclear fuel cells.
  {tech="nuclear-fuel-reprocessing",stage="cerys",
    parents={"moon-discovery-cerys","nuclear-science-pack"},
    packs={"nuclear-science-pack"}}
}
M.optional={
  {tech="interplanetary-trade-logistics",mod="planet-express",
    stage="first-pair",parents={"planet-discovery-vulcanus",
      "planet-discovery-gleba","metallurgic-science-pack",
      "agricultural-science-pack"},
    packs={"metallurgic-science-pack","agricultural-science-pack"}},
  {tech="aai-signal-transmission",mod="aai-signal-transmission",
    stage="fulgora",parents={"planet-discovery-fulgora",
      "electromagnetic-science-pack"},packs={"electromagnetic-science-pack"}}
}
local function ingredient_name(part)
  return type(part)=="table" and (part.name or part[1]) or nil
end
local function recipe_outputs(recipe,item)
  local variants={recipe,recipe.normal,recipe.expensive}
  for _,variant in ipairs(variants) do
    if type(variant)=="table" then
      if variant.result==item then return true end
      for _,part in ipairs(variant.results or {}) do
        if ingredient_name(part)==item
          and part.type~="fluid" then return true end
      end
    end
  end
  return false
end
local function is_produced(raw,item)
  if (raw.recipe or {})[item] then
    local recipe=raw.recipe[item]
    if not recipe.hidden and recipe_outputs(recipe,item) then
      return true
    end
  end
  for _,recipe in pairs(raw.recipe or {}) do
    if not recipe.hidden and recipe_outputs(recipe,item) then return true end
  end
  return false
end
-- Lab tier is important too. An omega lab that exists only at the
-- end of the campaign must never be counted as the sole way to research
-- an early technology. All names are source-owned, no new labs are made.
M.early_labs={
  lab=true,biolab=true,["kr-advanced-lab"]=true,
  ["thermodynamics-lab"]=true
}
function M.has_lab(raw,needed)
  for id,lab in pairs(raw.lab or {}) do
    if M.early_labs[id] then
      local inputs={}
      for _,name in ipairs(lab.inputs or {}) do inputs[name]=true end
      local accepts=true
      for name in pairs(needed) do
        if not inputs[name] then accepts=false;break end
      end
      if accepts then return true end
    end
  end
  return false
end

function M.apply(raw,rule)
  local techs=raw.technology or {}
  local target=techs[rule.tech]
  if not active(target) or not target.unit or target.research_trigger
    or type(target.unit.ingredients)~="table"
    or #target.unit.ingredients==0 then return false,"non-science-target" end
  local needed={}
  for _,part in ipairs(target.unit.ingredients) do
    local name=ingredient_name(part)
    if name then needed[name]=true end
  end
  -- No fake resource pack or route: required science has to be a genuine
  -- installed item with a production recipe and its own source research.
  for _,name in ipairs(rule.packs) do
    if not active(techs[name])
      or not ((raw.tool or {})[name] or (raw.item or {})[name])
      or not is_produced(raw,name) then return false,"missing-native-science" end
    needed[name]=true
  end
  for _,parent in ipairs(rule.parents) do
    if not active(techs[parent]) or reaches(techs,parent,rule.tech) then
      return false,"prerequisite-unavailable-or-cycle"
    end
  end
  if not M.has_lab(raw,needed) then return false,"no-early-compatible-lab" end
  local existing={}
  for _,parent in ipairs(target.prerequisites or {}) do existing[parent]=true end
  target.prerequisites=target.prerequisites or {}
  for _,parent in ipairs(rule.parents) do
    if not existing[parent] then
      target.prerequisites[#target.prerequisites+1]=parent
      existing[parent]=true
    end
  end
  for _,name in ipairs(rule.packs) do
    local seen=false
    for _,part in ipairs(target.unit.ingredients) do
      if ingredient_name(part)==name then seen=true;break end
    end
    if not seen then
      target.unit.ingredients[#target.unit.ingredients+1]={name,1}
    end
  end
  return true,"applied"
end

function M.data_final_fixes()
  local option=settings and settings.startup
    and settings.startup["razi-distributed-technology"]
  if option and option.value==false then return end
  local raw=data.raw
  local count=0
  local function run(rule)
    local ok,why=M.apply(raw,rule)
    if ok then count=count+1 end
    if type(log)=="function" then
      log("[Razi Protocol/industry-distribution] "..rule.tech.." "..why)
    end
  end
  for _,rule in ipairs(M.core) do run(rule) end
  if mods then
    for _,rule in ipairs(M.optional) do
      if mods[rule.mod] then
        -- AAI forks may rename the source technology, but must still
        -- unlock a real signal transmitter before Razi can relocate it.
        if rule.mod=="aai-signal-transmission" then
          local aai=require("prototypes.compat.aai_signal_partnerships")
          local name=aai.source_technology(raw.technology or {})
          if name then
            local resolved={}
            for k,v in pairs(rule) do resolved[k]=v end
            resolved.tech=name
            run(resolved)
          end
        else run(rule) end
      end
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/industry-distribution] "..count..
      " guarded planetary research placements applied")
  end
end
return M
