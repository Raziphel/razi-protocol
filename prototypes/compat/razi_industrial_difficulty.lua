-- Cross-mod industrial difficulty: no source settings or recipe rewrites.
-- Only existing entity properties are scaled, after mod prototype creation.
local M={}
local resolver=require("scripts.razi_difficulty_presets")
M.factors={
 throughput={boosted=1.15,normal=1,constrained=.92,strained=.82},
 fortifications={reinforced=1.25,normal=1,fragile=.90,brittle=.78}
}
local originals=setmetatable({},{__mode="k"})
-- Preserve absent fields for labs: researching_speed defaults to 1.
local function scale(proto,field,factor,default,integer)
 local record=originals[proto]
 if not record then record={};originals[proto]=record end
 local captured=record[field]
 if not captured then
   local saved=proto[field]
   if saved~=nil and (type(saved)~="number" or saved<=0) then return false end
   local base=saved or default
   if type(base)~="number" or base<=0 then return false end
   captured={saved=saved,base=base}
   record[field]=captured
 end
 local desired
 if factor==1 then
   desired=captured.saved
 else
   desired=math.max(integer and 1 or .001,
     integer and math.floor(captured.base*factor+.5)
       or captured.base*factor)
 end
 if proto[field]==desired then return false end
 proto[field]=desired
 return true
end
function M.apply(raw,difficulty)
 raw=raw or {}
 difficulty=difficulty or resolver
 local a=M.factors.throughput[
   difficulty.effective("razi-factory-throughput","normal")] or 1
 local b=M.factors.fortifications[
   difficulty.effective("razi-fortification-durability","normal")] or 1
 local changed={factories=0,mining_drills=0,laboratories=0,defenses=0,turrets=0}
 for _,kind in ipairs({"assembling-machine","furnace"}) do
   for _,proto in pairs(raw[kind] or {}) do
     if scale(proto,"crafting_speed",a,nil,false) then
       changed.factories=changed.factories+1
     end
   end
 end
 for _,proto in pairs(raw["mining-drill"] or {}) do
   if scale(proto,"mining_speed",a,nil,false) then
     changed.mining_drills=changed.mining_drills+1
   end
 end
 for _,proto in pairs(raw.lab or {}) do
   if scale(proto,"researching_speed",a,1,false) then
     changed.laboratories=changed.laboratories+1
   end
 end
 for _,kind in ipairs({"wall","gate"}) do
   for _,proto in pairs(raw[kind] or {}) do
     if scale(proto,"max_health",b,nil,true) then
       changed.defenses=changed.defenses+1
     end
   end
 end
 -- Generic turret prototypes include enemy worms; never scale them.
 -- Skip unbuildable scripted turret variants to preserve their balance.
 for _,kind in ipairs({
   "ammo-turret","electric-turret","fluid-turret","artillery-turret"
 }) do
   for _,proto in pairs(raw[kind] or {}) do
     if (type(proto.minable)=="table" or proto.placeable_by~=nil)
       and scale(proto,"max_health",b,nil,true) then
       changed.turrets=changed.turrets+1
       changed.defenses=changed.defenses+1
     end
   end
 end
 return changed
end
function M.data_final_fixes()
 return M.apply(data.raw,resolver)
end
return M
