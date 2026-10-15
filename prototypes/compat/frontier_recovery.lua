-- Frontier Recovery Charter, a joint Razi milestone using the ORIGINAL
-- robotic and particulate science of our two required planets.
-- Never change Athos/Nulla arrival costs or invent replacement products.
local Graph=require("__razi_lib__/lib/technology_graph")
local Recipe=require("__razi_lib__/lib/recipe")
local M={}
local function raw(kind,name) return (data.raw[kind] or {})[name] end
local function unlock(recipe)
  return Graph.first_unlock(data.raw.technology or {},recipe,true)
end
M.unlock=unlock
local function discovery(world)
  local options={}
  for name,tech in pairs(data.raw.technology or {}) do
    for _,effect in ipairs(tech.effects or {}) do
      if effect.type=="unlock-space-location" and effect.space_location==world
        and tech.enabled~=false and not tech.hidden then
        options[#options+1]=name break
      end
    end
  end
  table.sort(options)
  return options[1]
end
local function source_science(pack)
  if not raw("tool",pack) then return end
  local candidates={}
  for name,recipe in pairs(data.raw.recipe or {}) do
    if not recipe.hidden then
      local produces=Recipe.produces(recipe,pack)
      if produces then candidates[#candidates+1]=name end
    end
  end
  table.sort(candidates)
  for _,recipe in ipairs(candidates) do
    local tech=unlock(recipe)
    if tech then return tech,recipe end
  end
end
M.source_science=source_science
local function late_lab()
  for _,name in ipairs({"omega-lab","kr-singularity-lab","pressure-lab"}) do
    local lab=raw("lab",name)
    if lab and lab.inputs then return lab end
  end
end
function M.data_final_fixes()
  if not (mods and mods.nulla and mods.PlanetAthos) then return false end
  local nulla=discovery("nulla")
  local athos=discovery("athos")
  local robots=raw("technology","robotic-science-pack")
    and "robotic-science-pack" or unlock("robotic-science-pack")
  local particulate=source_science("particulate-science-pack")
  local lab=late_lab()
  local mastery=raw("technology","razi-outer-frontier-mastery")
  if not (nulla and athos and robots and particulate and lab and mastery
      and raw("tool","robotic-science-pack")) then
    if log then log("[Razi/recovery] Unable to build joint science charter: "..
      "Nulla="..tostring(nulla).." Athos="..tostring(athos)..
      " Particulate="..tostring(particulate).." Lab="..tostring(lab~=nil)) end
    return false
  end
  local id="razi-frontier-recovery-charter"
  local original=raw("technology",nulla)
  local node=raw("technology",id)
  if not node then
    node={
      type="technology",name=id,essential=true,
      localised_name={"technology-name."..id},
      localised_description={"technology-description."..id},
      order="z[razi]-recovery",
      prerequisites={nulla,athos,robots,particulate},
      effects={{type="worker-robot-speed",modifier=0.1}},
      unit={count=900,time=60,ingredients={
        {"robotic-science-pack",1},
        {"particulate-science-pack",1},
        {"cryogenic-science-pack",1}
      }}
    }
    if original.icons then node.icons=table.deepcopy(original.icons)
    else node.icon=original.icon;node.icon_size=original.icon_size end
    data:extend({node})
  end
  local active={}
  for _,entry in ipairs(lab.inputs) do active[entry]=true end
  for _,ingredient in ipairs(node.unit.ingredients) do
    local pack=ingredient[1] or ingredient.name
    if not active[pack] then
      lab.inputs[#lab.inputs+1]=pack
      active[pack]=true
    end
  end
  -- Append to the pre-existing outer research: no bootstrap demand is added
  -- to either world's discovery, rocket silo or original science production.
  Graph.add_prerequisite(data.raw.technology or {},
    "razi-outer-frontier-mastery",id)
  return true
end
return M
