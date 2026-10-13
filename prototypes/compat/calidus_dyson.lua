-- Calidus Dyson megaproject: adopt SLP's original 2.1 planets, science,
-- satellites, connectors and energy repeaters. No duplicate controller, no
-- access to private third-party storage, and no scripted power generation.
-- The K2 rebalance owns its Plasma tech-card conversion.
local M={}
local stages={
 {id="planet-discovery-sunorbit",parents={
   "planet-discovery-vulcanus","planet-discovery-fulgora"}},
 {id="slp-solar-system-sun2",parents={
   "planet-discovery-gleba","moon-discovery-cerys"}},
 {id="slp-dyson-sphere",parents={
   "cerys-advanced-structure-repair","moshine-tech-data-processor-building"}},
 {id="slp-dyson-sphere-grounded",parents={
   "planet-discovery-aquilo"}},
 {id="ds-energy-loader-mk2",parents={
   "maraxsis-project-seadragon"}},
 {id="ds-energy-loader-mk3",parents={
   "razi-outer-frontier-mastery"}}
}
M.stages=stages

local function tech(id) return (data.raw.technology or {})[id] end
local function active(id)
 local t=tech(id)
 return t and t.hidden~=true and t.enabled~=false
end
local function depends(start,ancestor,seen)
 if start==ancestor then return true end
 local t=tech(start)
 if not t then return false end
 seen=seen or {}
 if seen[start] then return false end
 seen[start]=true
 for _,parent in ipairs(t.prerequisites or {}) do
   if depends(parent,ancestor,seen) then return true end
 end
 return false
end
function M.safe_link(target,prerequisite)
 if target==prerequisite or not active(target) or not active(prerequisite)
   or depends(prerequisite,target) then return false end
 if depends(target,prerequisite) then return true end
 local t=tech(target)
 t.prerequisites=t.prerequisites or {}
 t.prerequisites[#t.prerequisites+1]=prerequisite
 return true
end

-- A star location is owned by the source technology's unlock effect, not
-- a guessed prototype name. Returning nil simply preserves source geometry.
function M.destination(technology_name)
 local t=tech(technology_name)
 for _,effect in ipairs(t and t.effects or {}) do
   if effect.type=="unlock-space-location" and effect.space_location then
     local id=effect.space_location
     local location=(data.raw.planet or {})[id]
       or (data.raw["space-location"] or {})[id]
     if location then return id,location end
   end
 end
end
local function calidus_orbit(location,radius,angle)
 local old=location.orbit or {}
 local orbit={
   parent={type="space-location",name="star"},
   distance=radius,orientation=angle
 }
 if old.sprite then orbit.sprite=old.sprite end
 location.orbit=orbit
 location.origin={x=0,y=0}
 location.distance=radius
 location.orientation=angle
 -- Source icon, surface rules, hazards and planet-specific map settings
 -- are never altered. The outer/inner locations look close to Calidus.
end

function M.data_final_fixes()
 if not (mods and mods["slp-dyson-sphere-reworked-fork"]) then return end
 local gate_setting=settings and settings.startup
   and settings.startup["razi-dyson-milestone-weave"]
 if not gate_setting or gate_setting.value~=false then
   for _,stage in ipairs(stages) do
     if active(stage.id) then tech(stage.id).essential=true end
     for _,parent in ipairs(stage.parents) do
       M.safe_link(stage.id,parent)
     end
   end
   -- Make the existing stellar infrastructure a real final engineering
   -- research milestone, without demanding satellite counts via guessed
   -- internal SLP APIs. The native launch/repeater tasks stay source-owned.
   M.safe_link("razi-singularity-test-fire","slp-dyson-sphere-grounded")
 end
 local visual_setting=settings and settings.startup
   and settings.startup["razi-dyson-calidus-layout"]
 if visual_setting and visual_setting.value==false then return end
 local _,outer=M.destination("planet-discovery-sunorbit")
 local _,inner=M.destination("slp-solar-system-sun2")
 if outer then calidus_orbit(outer,10,0.38) end
 if inner and inner~=outer then calidus_orbit(inner,5,0.68) end
end

-- Connect the outer solar location to our Calidus hub using the actual
-- source prototype ID. Run AFTER native route reconciliation; the native
-- sun-to-inner-sun route and its plasma asteroid hazards are preserved.
function M.connect_calidus()
 if not (mods and mods["slp-dyson-sphere-reworked-fork"]) then return end
 local id=M.destination("planet-discovery-sunorbit")
 local hub=(data.raw["space-location"] or {})["sye-calidus"]
 if not id or not hub then return end
 local routes=data.raw["space-connection"] or {}
 local first,second="sye-calidus",id
 -- An existing Nauvis/Muluna solar-orbit route already reaches this station.
 -- Do not add another hub spoke across the compact central orbit artwork.
 local nearby={nauvis=true,muluna=true}
 for _,r in pairs(routes) do
   if (r.from==id and nearby[r.to])
     or (r.to==id and nearby[r.from]) then return end
 end
 for _,r in pairs(routes) do
   if (r.from==first and r.to==second)
     or (r.from==second and r.to==first) then return end
 end
 local route={
   type="space-connection",
   name="razi-calidus-stellar-orbit",
   from=first,to=second,length=10500,shape="arc",
   asteroid_spawn_definitions={}
 }
 local icons=require("prototypes.system.route_icons")
 icons.assign(route,"starter")
 data:extend({route})
end
return M
