-- The Convergence: a new ending assembled with existing planet industry.
-- No new planet, laboratory, combat encounter or substitute transport.
local M={}
M.commission="razi-convergence-commission"
M.authorization="razi-convergence-synchronization"
M.ignition="razi-convergence-ignition"
M.shipments={
 {id="stellar",item="razi-convergence-stellar-mandate",count=24,
  icon="calidus-tech-card",ingredients={
   {"calidus-tech-card",2},{"solaris-tech-card",1},
   {"nyxaris-tech-card",1},{"processing-unit",8},
   {"low-density-structure",8}}},
 {id="industry",item="razi-convergence-industrial-mandate",count=30,
  icon="vibrant-tech-card",ingredients={
   {"vibrant-tech-card",2},{"vespera-tech-card",2},
   {"kr-rare-metals",8},{"bioflux",8}},
  supplies={{"holmium-plate",6},{"optical-cable",6},
   {"craptonite-frame",6}}},
 {id="deep-space",item="razi-convergence-deep-space-mandate",count=18,
  unlock=M.authorization,icon="deep-space-tech-card",ingredients={
   {"beetlejuice-tech-card",2},{"umbra-tech-card",2},
   {"deep-space-tech-card",2}},
  supplies={{"promethium-science-pack",4},
   {"kr-singularity-tech-card",2},{"pulsar-science-pack",2},
   {"supermagnet",3}}},
 {id="resonance",item="razi-convergence-resonance-mandate",count=12,
  unlock=M.authorization,icon="deep-space-tech-card",ingredients={
   {"beetlejuice-tech-card",2},{"umbra-tech-card",2},
   {"deep-space-tech-card",2},{"processing-unit",12},
   {"holmium-plate",8}},
  supplies={{"pulsar-science-pack",8},
   {"antimatter-science-pack",4},{"supermagnet",6}}},
 {id="ignition",item="razi-convergence-ignition-mandate",count=1,
  unlock=M.ignition,icon="calidus-tech-card",ingredients={
   {"calidus-tech-card",8},{"solaris-tech-card",8},
   {"nyxaris-tech-card",8},{"vibrant-tech-card",8},
   {"vespera-tech-card",8},{"beetlejuice-tech-card",8},
   {"umbra-tech-card",8},{"deep-space-tech-card",12},
   {"processing-unit",40},{"low-density-structure",40}},
  supplies={{"pulsar-science-pack",12},
   {"promethium-science-pack",12},{"antimatter-science-pack",8},
   {"supermagnet",8}}}
}
-- The final accord is a physical assembly, not a 10-14 input craft.
-- All eight required system cards are still consumed by its three parts.
M.assemblies={
 {id="calidus-frame",item="razi-convergence-calidus-frame",
  icon="calidus-tech-card",ingredients={
   {"calidus-tech-card",8},{"solaris-tech-card",8},
   {"nyxaris-tech-card",8},{"processing-unit",40}}},
 {id="outer-matrix",item="razi-convergence-outer-matrix",
  icon="vibrant-tech-card",ingredients={
   {"vibrant-tech-card",8},{"vespera-tech-card",8},
   {"beetlejuice-tech-card",8},{"umbra-tech-card",8},
   {"low-density-structure",40}}},
 {id="void-lens",item="razi-convergence-void-lens",
  icon="deep-space-tech-card",ingredients={
   {"deep-space-tech-card",12}},
  supplies={{"pulsar-science-pack",12},
   {"promethium-science-pack",12},
   {"antimatter-science-pack",8},{"supermagnet",8}}}
}
M.max_recipe_inputs=6
local artwork={
 stellar="stellar",industry="industry",
 ["deep-space"]="deep-space",resonance="resonance",ignition="ignition"
}
local function raw(kind,id)
 return (data.raw[kind] or {})[id]
end
local function has_item(id)
 return raw("item",id) or raw("tool",id)
end
local function clone(value)
 if table.deepcopy then return table.deepcopy(value) end
 if type(value)~="table" then return value end
 local result={}
 for k,v in pairs(value) do result[k]=clone(v) end
 return result
end
local function ancestors(tech,start,search,seen)
 if start==search then return true end
 local node=tech[start]
 if not node then return false end
 seen=seen or {}
 if seen[start] then return false end
 seen[start]=true
 for _,parent in ipairs(node.prerequisites or {}) do
  if ancestors(tech,parent,search,seen) then return true end
 end
 return false
end
local function append(tech,source)
 if not tech or not source then return end
 tech.prerequisites=tech.prerequisites or {}
 for _,parent in ipairs(tech.prerequisites) do
  if parent==source then return end
 end
 tech.prerequisites[#tech.prerequisites+1]=source
end
local function producer_index()
 local known={}
 for id,recipe in pairs(data.raw.recipe or {}) do
  if not recipe.hidden then
   local products=recipe.results or {}
   if recipe.result then products={{name=recipe.result}} end
   for _,result in ipairs(products) do
    if result.type~="fluid" and (result.name or result[1]) then
     known[result.name or result[1]]=true
    end
   end
  end
 end
 return known
end
-- Cap every final-act recipe to what at least one installed native
-- crafting machine can genuinely accept, without creating a lab/machine.
local function native_crafting_slots()
 local max_slots=0
 for _,kind in ipairs({"assembling-machine","furnace"}) do
  for _,machine in pairs(data.raw[kind] or {}) do
   for _,category in pairs(machine.crafting_categories or {}) do
    if category=="crafting" then
     max_slots=math.max(max_slots,machine.ingredient_count or 65535)
     break
    end
   end
  end
 end
 return math.min(M.max_recipe_inputs,max_slots)
end
local function recipe_ingredients(rule,products,limit)
 local selected={}
 for _,part in ipairs(rule.ingredients or {}) do
  selected[#selected+1]={type="item",name=part[1],amount=part[2]}
 end
 for _,part in ipairs(rule.supplies or {}) do
  if #selected>=limit then break end
  if has_item(part[1]) and products[part[1]] then
   selected[#selected+1]={type="item",name=part[1],amount=part[2]}
  end
 end
 return selected
end
local function native_icon(name)
 local source=raw("tool",name)
 return source.icons and {icons=clone(source.icons)}
    or {icon=source.icon,icon_size=source.icon_size or 256}
end
local function mandate_icon(id)
 return {icon="__razi-protocol__/graphics/icons/convergence/razi-convergence-"..
  artwork[id]..".png",icon_size=64}
end
local function unit(candidates,fallback)
 local lab_inputs={}
 for _,lab in pairs(data.raw.lab or {}) do
  local set={}
  for _,name in ipairs(lab.inputs or {}) do set[name]=true end
  lab_inputs[#lab_inputs+1]=set
 end
 local chosen={}
 for _,card in ipairs(candidates) do
  if raw("tool",card) then chosen[#chosen+1]=card end
 end
 if #chosen==0 then return nil end
 local function supported(list)
  for _,inputs in ipairs(lab_inputs) do
   local all=true
   for _,id in ipairs(list) do
    if not inputs[id] then all=false break end
   end
   if all then return true end
  end
  return false
 end
 -- Only use additional packs when a SINGLE native lab accepts them.
 if not supported(chosen) then
  -- Optional Nexus normally provides Omega Lab. Without it, use only
  -- the outer-pair science research but retain the physical Deep Space
  -- card in the last cargo recipe. No invented lab is necessary.
  if fallback then return unit(fallback) end
  return nil
 end
 local ingredients={}
 for _,id in ipairs(chosen) do ingredients[#ingredients+1]={id,1} end
 return {count=1200,time=60,ingredients=ingredients}
end
local function optional_parent(tech,goal,candidate)
 return tech[candidate] and tech[candidate].enabled~=false
  and not tech[candidate].hidden
  and not ancestors(tech,candidate,goal)
end
local function make_technology(id,icon,prereqs,packs,count)
 return {type="technology",name=id,
  localised_name={"technology-name."..id},
  localised_description={"technology-description."..id},
  icon=icon.icon,icon_size=icon.icon_size or 256,
  icons=icon.icons and clone(icon.icons) or nil,
  prerequisites=prereqs,
  effects={},unit={count=count,time=60,ingredients=packs.ingredients},
  order="zz[razi-convergence]-"..id,
  essential=true}
end
function M.data_final_fixes()
 local tech=data.raw.technology or {}
 -- Research the true transceiver and reach the Edge first.
 if not tech["stellar-discovery-solar-system-edge"]
  or not tech["razi-intergalactic-transceiver-signal"]
  or tech[M.commission] or tech[M.authorization]
  or tech[M.ignition] then return end
 local products=producer_index()
 local slots=native_crafting_slots()
 if slots<5 then
  if log then log("Razi Convergence: no native crafting machine accepts five ingredients") end
  return
 end
 for _,rule in ipairs(M.shipments) do
  if not raw("tool",rule.icon) or not raw("recipe",rule.icon)
    or has_item(rule.item) or raw("recipe",rule.item) then return end
  for _,part in ipairs(rule.ingredients) do
   if not (has_item(part[1]) and products[part[1]]) then
    -- Never make a half-registered victory where one shipment cannot
    -- be made. Give a readable startup log, not an engine crash.
    if log then log("Razi Convergence: missing native producer "..part[1]) end
    return
   end
  end
 end
 local commission_science=unit({"beetlejuice-tech-card",
  "umbra-tech-card"})
 local final_science=unit({"beetlejuice-tech-card",
  "umbra-tech-card","deep-space-tech-card"},
  {"beetlejuice-tech-card","umbra-tech-card"})
 if not (commission_science and final_science) then
  if log then log("Razi Convergence: no native lab supports required system cards") end
  return
 end
 local edge="stellar-discovery-solar-system-edge"
 local base={edge}
 -- The source Dyson Sphere and Aegis expedition are meaningful parts of
 -- the finale when already installed and not downstream of Convergence.
 for _,id in ipairs({"slp-dyson-sphere","discovery-aegis-outer"}) do
  if optional_parent(tech,M.commission,id) then base[#base+1]=id end
 end
 -- Aegis discovery is optional: some valid 2.1 modpacks omit its world.
 local base_icon=raw("tool","beetlejuice-tech-card")
 local final_icon=raw("tool","deep-space-tech-card")
 local begin=make_technology(M.commission,base_icon,base,
  commission_science,2400)
 local ending=make_technology(M.authorization,final_icon,{M.commission},
  final_science,4200)
 for _,id in ipairs({"promethium-science-pack",
   "razi-network-extreme-lattice"}) do
  if optional_parent(tech,M.authorization,id) then
   append(ending,id)
  end
 end
 -- Dyson distribution joins the last engineering commission when
 -- installed, preserving source recipes and research ownership.
 local ignition=make_technology(M.ignition,final_icon,
  {M.authorization},final_science,5000)
 for _,id in ipairs({"slp-dyson-sphere-grounded",
   "ds-energy-loader-mk2"}) do
  if optional_parent(tech,M.ignition,id) then
   append(ignition,id)
  end
 end
 -- A coherent visual identity for the actual three research milestones.
 for _,entry in ipairs({{begin,"stellar"},{ending,"deep-space"},
   {ignition,"ignition"}}) do
  local icon=mandate_icon(entry[2])
  entry[1].icon=icon.icon
  entry[1].icon_size=icon.icon_size
  entry[1].icons=nil
 end
 local unlock_tech={
  [M.commission]=begin,[M.authorization]=ending,[M.ignition]=ignition
 }
 local new={begin,ending,ignition}
 for _,subgroup in ipairs({
  {type="item-subgroup",name="razi-convergence-parts",
   group="intermediate-products",order="zzz-a[convergence-parts]"},
  {type="item-subgroup",name="razi-convergence-mandates",
   group="intermediate-products",order="zzz-b[convergence-mandates]"}
 }) do
  if not raw("item-subgroup",subgroup.name) then
   new[#new+1]=subgroup
  end
 end
 local function add_item_recipe(rule,icon,subgroup,ingredients,energy)
  local item={type="item",name=rule.item,
   stack_size=100,weight=1000,
   subgroup=subgroup,
   order="zz[razi-convergence]-"..rule.id,
   localised_name={"item-name."..rule.item},
   localised_description={"item-description."..rule.item}}
  for k,v in pairs(icon) do item[k]=clone(v) end
  local recipe={type="recipe",name=rule.item,
   localised_name={"recipe-name."..rule.item},
   localised_description={"recipe-description."..rule.item},
   enabled=false,categories={"crafting"},energy_required=energy,
   ingredients=ingredients,
   results={{type="item",name=rule.item,amount=1}},
   allow_productivity=false,auto_recycle=false,
   allow_decomposition=false,
   subgroup=subgroup,
   order="zz[razi-convergence]-"..rule.id}
  for k,v in pairs(icon) do recipe[k]=clone(v) end
  new[#new+1]=item
  new[#new+1]=recipe
 end
 -- The three buildable assemblies only become available with Ignition
 -- research; their separate recipes each need at most five inputs.
 for _,rule in ipairs(M.assemblies) do
  if has_item(rule.item) or raw("recipe",rule.item) then return end
  add_item_recipe(rule,native_icon(rule.icon),"razi-convergence-parts",
   recipe_ingredients(rule,products,slots),18)
  ignition.effects[#ignition.effects+1]={type="unlock-recipe",
   recipe=rule.item}
 end
 for _,rule in ipairs(M.shipments) do
  local ingredients
  if rule.id=="ignition" then
   ingredients={}
   for _,part in ipairs(M.assemblies) do
    ingredients[#ingredients+1]={type="item",name=part.item,amount=1}
   end
  else
   ingredients=recipe_ingredients(rule,products,slots)
  end
  add_item_recipe(rule,mandate_icon(rule.id),"razi-convergence-mandates",
   ingredients,rule.id=="ignition" and 60 or 45)
  local unlock=unlock_tech[rule.unlock or M.commission]
  unlock.effects[#unlock.effects+1]={type="unlock-recipe",
    recipe=rule.item}
 end
 data:extend(new)
end
return M
