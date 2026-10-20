-- Project HELIOS II: physical megaprojects and energy-hungry grid anchors.
-- These are separate Razi-owned prototypes. SLP satellite and MW state stays
-- authoritative; no unverified calls into its private runtime state.
local M={}
local dyson=require("prototypes.compat.calidus_dyson")
local difficulty=require("scripts.razi_difficulty_presets")
local function raw(kind,id) return (data.raw[kind] or {})[id] end
local function enabled(name)
 local t=raw("technology",name)
 return t and t.enabled~=false and t.hidden~=true
end
local function setting(name,default)
 return difficulty.effective(name,default)
end
local function clone(value)
 if table.deepcopy then return table.deepcopy(value) end
 if type(value)~="table" then return value end
 local result={}
 for k,v in pairs(value) do result[k]=clone(v) end
 return result
end
local function item(id) return raw("item",id) or raw("tool",id) end
local function icon(id)
 local source=item(id)
 if not source then return end
 if source.icons then return {icons=clone(source.icons),
   icon_size=source.icon_size} end
 if source.icon then return {icon=source.icon,
   icon_size=source.icon_size or 64} end
end
local function item_recipe(id,source_icon,inputs,seconds,place_result)
 local art=icon(source_icon)
 local product={type="item",name=id,icon=art.icon,
   icons=art.icons,icon_size=art.icon_size,
   subgroup="intermediate-product",stack_size=10,
   order="zzz[helios]-"..id,
   localised_name={"item-name."..id},
   localised_description={"item-description."..id},
   place_result=place_result}
 local ingredients={}
 for _,input in ipairs(inputs) do
   ingredients[#ingredients+1]={type="item",name=input[1],amount=input[2]}
 end
 return product,{type="recipe",name=id,
   localised_name={"recipe-name."..id},
   enabled=false,categories={"advanced-crafting"},
   energy_required=seconds,ingredients=ingredients,
   results={{type="item",name=id,amount=1}},
   subgroup="intermediate-product",
   allow_productivity=false,auto_recycle=false}
end
function M.data_final_fixes()
 if not (mods and mods["slp-dyson-sphere-reworked-fork"])
   or setting("razi-helios-progression","late")=="legacy"
   or setting("razi-helios-construction","satellites")=="off"
   or setting("razi-helios-commissioning","expedition")=="off" then
   return false
 end
 if not (enabled("razi-helios-swarm-engineering")
   and enabled("razi-helios-relay-engineering")
   and enabled("slp-dyson-sphere-grounded")) then return false end
 for _,id in ipairs({"razi-helios-corona-shield",
   "razi-helios-stellar-frame","razi-helios-relay-matrix",
   "holmium-plate","superconductor","processing-unit",
   "low-density-structure","radar"}) do
   if not item(id) then return false end
 end
 if not raw("radar","radar") or not icon("holmium-plate")
   or not icon("radar") then return false end
 for _,id in ipairs({"razi-helios-orbital-lattice",
   "razi-helios-grid-anchor"}) do
   if item(id) or raw("recipe",id) then return false end
 end
 if raw("radar","razi-helios-grid-anchor")
   or raw("technology","razi-helios-grid-commission") then return false end
 -- A real grid anchor has a 15 MW demand: the grid has an operating cost
 -- even after its satellites and source repeaters have been commissioned.
 local radar=clone(raw("radar","radar"))
 radar.name="razi-helios-grid-anchor"
 radar.icon="__base__/graphics/icons/radar.png"
 radar.icon_size=64
 radar.icons=nil
 radar.minable={mining_time=2,result="razi-helios-grid-anchor"}
 radar.energy_usage="15MW"
 radar.max_distance_of_sector_revealed=0
 radar.max_distance_of_nearby_sector_revealed=0
 if radar.energy_source and radar.energy_source.type=="electric" then
   radar.energy_source.buffer_capacity="150MJ"
 end
 radar.localised_name={"entity-name.razi-helios-grid-anchor"}
 radar.localised_description={"entity-description.razi-helios-grid-anchor"}
 local lattice,lattice_recipe=item_recipe("razi-helios-orbital-lattice",
   "holmium-plate",{
    {"razi-helios-stellar-frame",4},{"razi-helios-corona-shield",4},
    {"holmium-plate",30},{"superconductor",15},
    {"low-density-structure",60}},100)
 local anchor,anchor_recipe=item_recipe("razi-helios-grid-anchor",
   "radar",{
    {"razi-helios-relay-matrix",3},{"razi-helios-stellar-frame",2},
    {"processing-unit",75},{"low-density-structure",60},
    {"radar",3}},120,"razi-helios-grid-anchor")
 anchor.subgroup="defensive-structure"
 anchor_recipe.subgroup="defensive-structure"
 local tech={
   type="technology",name="razi-helios-grid-commission",
   localised_name={"technology-name.razi-helios-grid-commission"},
   localised_description={"technology-description.razi-helios-grid-commission"},
   icon="__base__/graphics/technology/radar.png",icon_size=256,
   prerequisites={},
   unit=clone(raw("technology","razi-helios-relay-engineering").unit),
   effects={
     {type="unlock-recipe",recipe=lattice.name},
     {type="unlock-recipe",recipe=anchor.name}
   },essential=true,order="zz[razi-helios]-grid-commission"
 }
 tech.unit.count=6200
 tech.unit.count_formula=nil
 data:extend({radar,lattice,lattice_recipe,anchor,anchor_recipe,tech})
 dyson.safe_link(tech.name,"razi-helios-relay-engineering")
 dyson.safe_link(tech.name,"slp-dyson-sphere-grounded")
 -- Reward post-commission research without changing the source connector
 -- entity or infinite-energy rules. Existing research graph is cycle-safe.
 dyson.safe_link("ds-energy-loader-mk3",tech.name)
 return true
end
return M
