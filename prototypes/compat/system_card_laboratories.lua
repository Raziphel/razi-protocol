-- Curate Razi system cards in the EXISTING Factorio/K2SO/planet labs.
-- This module deliberately defines no entities, items, recipes or labs.
local Graph=require("__razi_lib__/lib/technology_graph")
local Recipe=require("__razi_lib__/lib/recipe")
local M={}
local cards={
 "calidus-tech-card","solaris-tech-card","nyxaris-tech-card",
 "vibrant-tech-card","vespera-tech-card","beetlejuice-tech-card",
 "umbra-tech-card","deep-space-tech-card"
}
M.cards=cards
M.rank={
 ["calidus-tech-card"]=1,
 ["solaris-tech-card"]=2,["nyxaris-tech-card"]=2,
 ["vibrant-tech-card"]=3,["vespera-tech-card"]=3,
 ["beetlejuice-tech-card"]=4,["umbra-tech-card"]=4,
 ["deep-space-tech-card"]=5
}
-- Each name here belongs to its original mod. Moshine's laboratory
-- gives the middle pair its distinct tier; if absent, elevate K2SO's
-- advanced lab rather than inventing a new machine.
M.native={
 ["lab"]=1,["biolab"]=2,["kr-advanced-lab"]=2,
 ["thermodynamics-lab"]=3,
 ["pressure-lab"]=4,["kr-singularity-lab"]=4,["omega-lab"]=5
}
M.recipe_upgrades={
 {lab="thermodynamics-lab",
  materials={{name="optical-cable",recipe="optical-cable",amount=6}}},
 {lab="kr-singularity-lab",
  materials={{name="holmium-plate",recipe="holmium-plate",amount=10},
   {name="kr-energy-control-unit",recipe="kr-energy-control-unit",amount=6}}},
 {lab="omega-lab",
  materials={{name="rare-earth-powder",recipe="rare-earth-powder",amount=10},
   {name="supermagnet",recipe="supermagnet",amount=6}}}
}
local function raw(type,name)
 return (data.raw[type] or {})[name]
end
local function add(inputs,name,seen)
 if not seen[name] then
  inputs[#inputs+1]=name
  seen[name]=true
 end
end
local function accepts(lab,science)
 if not (lab and lab.inputs) then return false end
 local present={}
 for _,id in ipairs(lab.inputs) do present[id]=true end
 for _,id in ipairs(science) do
  if not present[id] then return false end
 end
 return true
end
local function product(recipe,id)
 return Recipe.produces(recipe,id)
end
local function safe_upgrades()
 local recipes=data.raw.recipe or {}
 local techs=data.raw.technology or {}
 local indexed=Graph.unlock_index(techs)
 for _,rule in ipairs(M.recipe_upgrades) do
  local recipe=recipes[rule.lab]
  -- Only modify native locked crafting recipes, and only if the native
  -- research ALREADY includes all required supplier research. Do not
  -- rewrite a lab to need materials from a future discovery.
  if recipe and recipe.enabled==false and not recipe.hidden
    and recipe.ingredients and not recipe.normal and not recipe.expensive then
   local unlock
   for _,candidate in ipairs(indexed[rule.lab] or {}) do
    if techs[candidate] and techs[candidate].enabled~=false
      and not techs[candidate].hidden then
     unlock=candidate
     break
    end
   end
   local ok=unlock~=nil
   for _,supply in ipairs(rule.materials) do
    local source=recipes[supply.recipe]
    local valid=source and not source.hidden
      and product(source,supply.name)
      and (raw("item",supply.name) or raw("tool",supply.name))
    if not valid then ok=false break end
    if source.enabled==false then
     local proven=false
     for _,source_unlock in ipairs(indexed[supply.recipe] or {}) do
      if Graph.reaches(techs,unlock,source_unlock) then
       proven=true break
      end
     end
     if not proven then ok=false break end
    end
   end
   if ok then
    local existing={}
    for _,ingredient in ipairs(recipe.ingredients) do
     existing[ingredient.name or ingredient[1]]=true
    end
    for _,supply in ipairs(rule.materials) do
     if not existing[supply.name] then
      recipe.ingredients[#recipe.ingredients+1]={
       type="item",name=supply.name,amount=supply.amount}
     end
    end
   end
  end
 end
end
local function assign_labs()
 local labs=data.raw.lab or {}
 if not labs["thermodynamics-lab"] then
  M.native["kr-advanced-lab"]=3
 end
 for name,tier in pairs(M.native) do
  local lab=labs[name]
  if lab and lab.inputs then
   local fresh,seen={},{}
   for _,input in ipairs(lab.inputs) do
    local level=M.rank[input]
    if not level or level<=tier then add(fresh,input,seen) end
   end
   for _,card in ipairs(cards) do
    if M.rank[card]<=tier and raw("tool",card) then
     add(fresh,card,seen)
    end
   end
   lab.inputs=fresh
  end
 end
end
local function restore_science()
 local labs=data.raw.lab or {}
 for _,tech in pairs(data.raw.technology or {}) do
  local unit=tech.unit
  if tech.enabled~=false and not tech.hidden
   and unit and unit.ingredients and #unit.ingredients>0 then
   local all,own,other={}, {}, {}
   local tier=1
   for _,part in ipairs(unit.ingredients) do
    local name=part.name or part[1]
    if name then
     all[#all+1]=name
     if M.rank[name] then
      own[#own+1]=name
      tier=math.max(tier,M.rank[name])
     else
      other[#other+1]=name
     end
    end
   end
   if #own>0 then
    local satisfied=false
    for _,lab in pairs(labs) do
     if accepts(lab,all) then satisfied=true break end
    end
    if not satisfied then
     -- Check complete non-Razi science sets; never add a native pack.
     -- Prefer the correct tier and above before any lower-tier exception.
     local ordered={}
     for level=tier,5 do ordered[#ordered+1]=level end
     for level=tier-1,1,-1 do ordered[#ordered+1]=level end
     local selection
     for _,level in ipairs(ordered) do
      for _,name in ipairs({"thermodynamics-lab","kr-advanced-lab",
        "kr-singularity-lab","pressure-lab","omega-lab",
        "biolab","lab"}) do
       if M.native[name]==level and accepts(labs[name],other) then
        selection=labs[name]
        break
       end
      end
      if selection then break end
     end
     if selection then
      local seen={}
      for _,name in ipairs(selection.inputs) do seen[name]=true end
      for _,name in ipairs(own) do add(selection.inputs,name,seen) end
     else
      if log then log("Razi science: no installed lab accepts all native packs for "..tech.name) end
     end
    end
   end
  end
 end
end
function M.data_final_fixes()
 assign_labs()
 safe_upgrades()
 restore_science()
end
return M
