-- Razi's laboratory ladder. Native labs retain their original
-- non-system science inputs; the only restricted inputs are our cards.
local M={}
local cards={
 "calidus-tech-card","solaris-tech-card","nyxaris-tech-card",
 "vibrant-tech-card","vespera-tech-card","beetlejuice-tech-card",
 "umbra-tech-card","deep-space-tech-card"
}
M.cards=cards
local rank={}
for i,id in ipairs(cards) do rank[id]=math.ceil((i+1)/2) end
rank["calidus-tech-card"]=1
rank["solaris-tech-card"]=2
rank["nyxaris-tech-card"]=2
rank["vibrant-tech-card"]=3
rank["vespera-tech-card"]=3
rank["beetlejuice-tech-card"]=4
rank["umbra-tech-card"]=4
rank["deep-space-tech-card"]=5
M.rank=rank
M.native={
 ["lab"]=1,["biolab"]=2,["thermodynamics-lab"]=2,
 ["kr-advanced-lab"]=2,["pressure-lab"]=4,
 ["kr-singularity-lab"]=4,["omega-lab"]=5
}
M.steps={
 {id="razi-frontier-lab",tier=2,base="lab",source="kr-advanced-lab",
  prereqs={"space-science-pack"},science={"calidus-tech-card"},
  materials={{"lab",1},{"processing-unit",12},{"low-density-structure",20}},
  count=240,power="120kW",speed=1.5},
 {id="razi-constellation-lab",tier=3,base="lab",
  source="kr-advanced-lab",prereqs={"solaris-discovery","nyxaris-discovery"},
  science={"solaris-tech-card","nyxaris-tech-card"},
  materials={{"razi-frontier-lab",1},{"kr-rare-metals",16},
    {"bioflux",12},{"optical-cable",12}},
  count=360,power="220kW",speed=2},
 {id="razi-astral-lab",tier=4,base="lab",
  source="kr-singularity-lab",prereqs={"vibrant-discovery","vespera-discovery"},
  science={"vibrant-tech-card","vespera-tech-card"},
  materials={{"razi-constellation-lab",1},{"holmium-plate",16},
    {"kr-energy-control-unit",12},{"craptonite-frame",12}},
  count=480,power="350kW",speed=2.5},
 {id="razi-deep-space-lab",tier=5,base="lab",
  source="kr-singularity-lab",
  prereqs={"beetlejuice-discovery","umbra-discovery"},
  science={"beetlejuice-tech-card","umbra-tech-card"},
  materials={{"razi-astral-lab",1},{"rare-earth-powder",18},
    {"supermagnet",12}},
  count=620,power="500kW",speed=3}
}
local function raw(kind,name)
 return data.raw[kind] and data.raw[kind][name]
end
local function item_exists(name)
 return raw("item",name) or raw("tool",name)
end
local function copy(value)
 if table.deepcopy then return table.deepcopy(value) end
 local t={}
 for k,v in pairs(value) do t[k]=type(v)=="table" and copy(v) or v end
 return t
end
local function add_unique(inputs,name)
 for _,v in ipairs(inputs) do if v==name then return end end
 inputs[#inputs+1]=name
end
local function available(step)
 if not (raw("lab",step.base) and raw("item",step.base)) then return false end
 if raw("lab",step.id) or item_exists(step.id)
  or raw("technology",step.id) or raw("recipe",step.id) then return false end
 for _,name in ipairs(step.prereqs) do
  if not raw("technology",name) then return false end
 end
 for _,name in ipairs(step.science) do
  if not raw("tool",name) then return false end
 end
 for _,material in ipairs(step.materials) do
  if not item_exists(material[1]) then return false end
 end
 return true
end
local function create(step)
 local native=raw("lab",step.base)
 local source=raw("lab",step.source) or native
 local entity=copy(native)
 entity.name=step.id
 entity.localised_name={"entity-name."..step.id}
 entity.minable=copy(native.minable or {mining_time=.2})
 entity.minable.result=step.id
 entity.next_upgrade=nil
 entity.fast_replaceable_group=nil
 entity.researching_speed=step.speed
 entity.energy_usage=step.power
 -- Native science support comes from the source upgrade if installed.
 -- Special labs and their original science packs remain untouched.
 -- Upstream integrations sometimes append the same pack twice; Factorio
 -- rejects duplicated lab input names when assigning prototype IDs.
 entity.inputs={}
 for _,name in ipairs(source.inputs or native.inputs or {}) do
  add_unique(entity.inputs,name)
 end
 for _,card in ipairs(cards) do
  if rank[card]<=step.tier and item_exists(card) then
   add_unique(entity.inputs,card)
  end
 end
 for i=#entity.inputs,1,-1 do
  if rank[entity.inputs[i]] and rank[entity.inputs[i]]>step.tier then
   table.remove(entity.inputs,i)
  end
 end
 local lab_item=copy(raw("item",step.base))
 lab_item.name=step.id
 lab_item.place_result=step.id
 lab_item.localised_name={"item-name."..step.id}
 lab_item.order="e[razi-laboratory]-"..step.tier
 local base_icon=lab_item.icon or "__base__/graphics/icons/lab.png"
 local icon_size=lab_item.icon_size or 64
 local card=raw("tool",cards[step.tier==5 and 8 or step.tier*2-1])
 lab_item.icon=nil
 lab_item.icon_size=nil
 lab_item.icons={{icon=base_icon,icon_size=icon_size},
   {icon=card and card.icon or "__base__/graphics/icons/lab.png",
    icon_size=card and (card.icon_size or 256) or 64,
    scale=card and .15 or .32,shift={8,8}}}
 -- Reuse the original lab graphics in-world, but keep a distinct tier
 -- icon in inventory, the tech tree and machine detail views.
 entity.icons=copy(lab_item.icons)
 entity.icon=nil
 entity.icon_size=nil
 local inputs={}
 for _,part in ipairs(step.materials) do
  inputs[#inputs+1]={type="item",name=part[1],amount=part[2]}
 end
 local science={}
 for _,name in ipairs(step.science) do science[#science+1]={name,1} end
 local recipe={type="recipe",name=step.id,enabled=false,
  categories={"crafting"},energy_required=20,
  localised_name={"recipe-name."..step.id},
  ingredients=inputs,results={{type="item",name=step.id,amount=1}},
  icons=copy(lab_item.icons),subgroup=lab_item.subgroup,
  order=lab_item.order,allow_productivity=false}
 local technology={type="technology",name=step.id,
  localised_name={"technology-name."..step.id},
  localised_description={"technology-description."..step.id},
  icons=copy(lab_item.icons),
  prerequisites=copy(step.prereqs),unit={count=step.count,time=45,
   ingredients=science},effects={{type="unlock-recipe",recipe=step.id}},
  order="a[razi-laboratories]-"..step.tier}
 data:extend({entity,lab_item,recipe,technology})
 return true
end
local function set_native_tiers()
 for id,tier in pairs(M.native) do
  local lab=raw("lab",id)
  if lab and lab.inputs then
   local keep,seen={},{}
   for _,input in ipairs(lab.inputs) do
    if not seen[input] and (not rank[input] or rank[input]<=tier) then
     keep[#keep+1]=input
     seen[input]=true
    end
   end
   -- A late mod may have omitted Razi's lower cards entirely.
   -- Adding only cards within the tier is always safe.
   for _,card in ipairs(cards) do
    if rank[card]<=tier and item_exists(card) and not seen[card] then
     keep[#keep+1]=card;seen[card]=true
    end
   end
   lab.inputs=keep
  end
 end
end
local function accepts(lab,ingredients)
 if not (lab and lab.inputs) then return false end
 local lookup={}
 for _,s in ipairs(lab.inputs) do lookup[s]=true end
 for _,s in ipairs(ingredients) do if not lookup[s] then return false end end
 return true
end
local function restore_research_coverage()
 local labs=data.raw.lab or {}
 for _,technology in pairs(data.raw.technology or {}) do
  local unit=technology.unit
  if unit and unit.ingredients and technology.enabled~=false
    and not technology.hidden then
   local needed,science_cards={},{}
   local maximum=1
   for _,ingredient in ipairs(unit.ingredients) do
    local name=ingredient.name or ingredient[1]
    if name then
     needed[#needed+1]=name
     if rank[name] then
      science_cards[#science_cards+1]=name
      maximum=math.max(maximum,rank[name])
     end
    end
   end
   if #science_cards>0 then
    local found=false
    for _,lab in pairs(labs) do
     if accepts(lab,needed) then found=true break end
    end
    if not found then
     -- A targeted escape hatch: preserve all native packs on the lab.
     -- Never make ordinary labs universal. Only install the missing
     -- Razi cards into a lab ALREADY supporting every other pack.
     local noncards={}
     for _,name in ipairs(needed) do
      if not rank[name] then noncards[#noncards+1]=name end
     end
     local by_tier={
      [1]={"lab"},
      [2]={"razi-frontier-lab","kr-advanced-lab",
           "biolab","thermodynamics-lab"},
      [3]={"razi-constellation-lab"},
      [4]={"razi-astral-lab","kr-singularity-lab","pressure-lab"},
      [5]={"razi-deep-space-lab","omega-lab"}
     }
     -- Prefer the EARLIEST laboratory with the correct science tier.
     -- A late-game Omega lab cannot be the sole theoretical solution
     -- for a research needed to enter Vibrant.
     local order={}
     for tier=maximum,5 do order[#order+1]=tier end
     for tier=maximum-1,1,-1 do order[#order+1]=tier end
     for _,tier in ipairs(order) do
      for _,lab_name in ipairs(by_tier[tier] or {}) do
       local lab=labs[lab_name]
       if accepts(lab,noncards) then
        for _,card in ipairs(science_cards) do
         add_unique(lab.inputs,card)
        end
        found=true
        break
       end
      end
      if found then break end
     end
    end
   end
  end
 end
end
function M.data_final_fixes()
 for _,step in ipairs(M.steps) do
  if available(step) then create(step) end
 end
 set_native_tiers()
 restore_research_coverage()
end
return M
