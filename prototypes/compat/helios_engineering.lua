-- HELIOS cross-planet stellar engineering. Native SLP satellites and
-- connectors remain source-owned; this module adds guarded research and parts.
local M={}
local dyson=require("prototypes.compat.calidus_dyson")
local function raw(kind,id) return (data.raw[kind] or {})[id] end
local function item(id) return raw("item",id) or raw("tool",id) end
local function choice(id,default)
 local s=settings and settings.startup and settings.startup[id]
 if s then return s.value end
 return default
end
local function copy(v)
 if type(v)~="table" then return v end
 local t={}
 for k,x in pairs(v) do t[k]=copy(x) end
 return t
end
local function art(id)
 local v=item(id)
 if not v then return end
 if v.icons then return {icons=copy(v.icons),icon_size=v.icon_size} end
 if v.icon then return {icon=v.icon,icon_size=v.icon_size or 64} end
end
local function available(id)
 local v=raw("technology",id)
 return v and v.enabled~=false and v.hidden~=true
end
local function unit(count)
 for _,id in ipairs({"planet-discovery-aquilo",
   "planet-discovery-fulgora","planet-discovery-vulcanus"}) do
   local v=raw("technology",id)
   if v and v.unit and type(v.unit.ingredients)=="table"
     and #v.unit.ingredients>0 then
     local u=copy(v.unit)
     u.count=count;u.count_formula=nil;u.time=u.time or 60
     return u
   end
 end
end
M.components={
 {tech="razi-helios-corona-engineering",product="razi-helios-corona-shield",
  art="tungsten-plate",count=1800,gate="planet-discovery-sunorbit",
  parents={"planet-discovery-vulcanus","planet-discovery-fulgora",
    "planet-discovery-aquilo","vibrant-discovery","vespera-discovery"},
  inputs={{"tungsten-plate",18},{"lithium-plate",12},
    {"low-density-structure",36},{"processing-unit",24}}},
 {tech="razi-helios-swarm-engineering",product="razi-helios-stellar-frame",
  art="holmium-plate",count=3200,gate="slp-dyson-sphere",
  parents={"planet-discovery-sunorbit","moon-discovery-cerys"},
  inputs={{"razi-helios-corona-shield",2},{"holmium-plate",30},
    {"carbon-fiber",24},{"tungsten-plate",24},{"processing-unit",40}}},
 {tech="razi-helios-relay-engineering",product="razi-helios-relay-matrix",
  art="superconductor",count=4800,gate="slp-dyson-sphere-grounded",
  parents={"slp-dyson-sphere","planet-discovery-aquilo"},
  inputs={{"razi-helios-stellar-frame",2},{"superconductor",40},
    {"lithium-plate",36},{"holmium-plate",36},{"processing-unit",80}}}
}
local function can_install()
 if not unit(1800) then return false end
 for _,spec in ipairs(M.components) do
   if not art(spec.art) or raw("technology",spec.tech)
     or item(spec.product) or raw("recipe",spec.product) then return false end
   for _,part in ipairs(spec.inputs) do
     if part[1]:sub(1,12)~="razi-helios-"
       and not item(part[1]) then return false end
   end
 end
 return true
end
function M.data_final_fixes()
 if not (mods and mods["slp-dyson-sphere-reworked-fork"])
   or choice("razi-helios-progression","late")=="legacy"
   or choice("razi-helios-construction","satellites")=="off"
   or not available("planet-discovery-sunorbit")
   or not available("slp-dyson-sphere")
   or not available("slp-dyson-sphere-grounded")
   or not can_install() then
   return false
 end
 local pack={}
 for _,spec in ipairs(M.components) do
   local icon=art(spec.art)
   local tech={type="technology",name=spec.tech,
     localised_name={"technology-name."..spec.tech},
     localised_description={"technology-description."..spec.tech},
     icon=icon.icon,icons=icon.icons,icon_size=icon.icon_size,
     prerequisites={},unit=unit(spec.count),essential=true,
     effects={{type="unlock-recipe",recipe=spec.product}},
     order="zz[razi-helios]-"..spec.tech}
   local physical={type="item",name=spec.product,
     localised_name={"item-name."..spec.product},
     localised_description={"item-description."..spec.product},
     icon=icon.icon,icons=icon.icons,icon_size=icon.icon_size,
     subgroup="intermediate-product",stack_size=20,
     order="zz[razi-helios]-"..spec.product}
   local ingredients={}
   for _,pair in ipairs(spec.inputs) do
     ingredients[#ingredients+1]={type="item",name=pair[1],amount=pair[2]}
   end
   local recipe={type="recipe",name=spec.product,enabled=false,
     localised_name={"recipe-name."..spec.product},
     subgroup="intermediate-product",category="crafting",
     energy_required=45,ingredients=ingredients,
     results={{type="item",name=spec.product,amount=1}},
     allow_productivity=false,auto_recycle=false,
     order="zz[razi-helios]-"..spec.product}
   pack[#pack+1]=tech;pack[#pack+1]=physical;pack[#pack+1]=recipe
 end
 data:extend(pack)
 -- Add the Razi supply-chain gates without introducing a technology cycle.
 for _,spec in ipairs(M.components) do
   for _,parent in ipairs(spec.parents) do
     dyson.safe_link(spec.tech,parent)
   end
   dyson.safe_link(spec.gate,spec.tech)
 end
 return true
end
local satellites={
 ["slp-ds-satellite"]="razi-helios-stellar-frame",
 ["slp-ds-planet-satellite"]="razi-helios-relay-matrix"
}
local function outputs(recipe,name)
 if recipe.result==name then return true end
 for _,product in ipairs(recipe.results or {}) do
   if (product.type or "item")=="item"
     and (product.name or product[1])==name then return true end
 end
 return false
end
local function machine_accepts(recipe,required)
 local categories=recipe.categories or {recipe.category or "crafting"}
 for _,kind in ipairs({"assembling-machine","furnace"}) do
   for _,machine in pairs(data.raw[kind] or {}) do
     if type(machine.ingredient_count)=="number"
       and machine.ingredient_count>=required then
       for _,category in ipairs(categories) do
         for _,allowed in ipairs(machine.crafting_categories or {}) do
           if category==allowed then return true end
         end
       end
     end
   end
 end
 return false
end
function M.reinforce_satellites()
 if choice("razi-helios-progression","late")=="legacy"
   or choice("razi-helios-construction","satellites")~="satellites"
   or not (mods and mods["slp-dyson-sphere-reworked-fork"]) then return 0 end
 local changed=0
 for output,component in pairs(satellites) do
   if item(output) and item(component) then
     for _,recipe in pairs(data.raw.recipe or {}) do
       if not recipe.hidden and outputs(recipe,output)
         and type(recipe.ingredients)=="table" then
         local found=false
         for _,ingredient in ipairs(recipe.ingredients) do
           if (ingredient.name or ingredient[1])==component then found=true end
         end
         if not found and machine_accepts(recipe,#recipe.ingredients+1) then
           local ingredients=copy(recipe.ingredients)
           ingredients[#ingredients+1]={type="item",name=component,amount=1}
           recipe.ingredients=ingredients
           changed=changed+1
         end
       end
     end
   end
 end
 if type(log)=="function" then
   log("[Razi Protocol/HELIOS] Native satellite recipes reinforced: "..changed)
 end
 return changed
end
return M
