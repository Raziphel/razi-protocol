-- Cross-mod native difficulty; bounded static factory/defense modifiers.
local M={}
local preset=require("scripts.razi_difficulty_presets")
local factors={
 throughput={boosted=1.15,normal=1,constrained=.92,strained=.82},
 fortifications={reinforced=1.25,normal=1,fragile=.90,brittle=.78}
}
M.factors=factors
local originals=setmetatable({},{__mode="k"})
function M.apply(raw,resolver)
 local a=factors.throughput[
   resolver.effective("razi-factory-throughput","normal")] or 1
 local b=factors.fortifications[
   resolver.effective("razi-fortification-durability","normal")] or 1
 local count={factories=0,defenses=0}
 for _,type_name in ipairs({"assembling-machine","furnace"}) do
  for _,proto in pairs((raw and raw[type_name]) or {}) do
   local original=originals[proto]
   if not original then
     original={crafting_speed=proto.crafting_speed}
     originals[proto]=original
   end
   if a~=1 and type(original.crafting_speed)=="number"
      and original.crafting_speed>0 then
     local value=math.max(.001,original.crafting_speed*a)
     if proto.crafting_speed~=value then
       proto.crafting_speed=value
       count.factories=count.factories+1
     end
   end
  end
 end
 for _,type_name in ipairs({"wall","gate"}) do
  for _,proto in pairs((raw and raw[type_name]) or {}) do
   local original=originals[proto]
   if not original then original={max_health=proto.max_health}
     originals[proto]=original end
   if b~=1 and type(original.max_health)=="number"
      and original.max_health>0 then
     local value=math.max(1,math.floor(original.max_health*b+.5))
     if proto.max_health~=value then
       proto.max_health=value
       count.defenses=count.defenses+1
     end
   end
  end
 end
 return count
end
function M.data_final_fixes()
 return M.apply(data.raw,preset)
end
return M
