-- Run from repo root with a Lua 5.2+ interpreter:
-- lua tests/lua/test_asteroid_performance.lua
package.path="./?.lua;./?/init.lua;"..package.path
local function expect(cond,reason) if not cond then error(reason,2) end end
local source=require("prototypes.system.asteroid_performance")
local function copy(value)
  if type(value)~="table" then return value end
  local out={}
  for k,v in pairs(value) do out[k]=copy(v) end
  return out
end
local visual={
  {type="create-particle",particle_name="rock-dust"},
  {type="create-trivial-smoke",smoke_name="smoke"},
  {type="create-asteroid-chunk",asteroid_name="metallic-asteroid-chunk"},
  {type="damage",damage={amount=25,type="physical"}}
}
local empty=source.prune(visual,false,false)
expect(empty==visual,"Disabled options must return original effect tree")
local modified,removed,fragments=source.prune(visual,true,false)
expect(removed==2 and fragments==0 and #modified==2,
 "Only visual effects should be removed")
expect(modified[1].type=="create-asteroid-chunk"
   and modified[2].type=="damage",
 "Visual-only mode cannot erase loot or damage")
expect(visual[1].type=="create-particle" and #visual==4,
 "Source effects must remain unmodified")
local halved,_,count=source.prune(visual,false,true)
expect(count==1 and #halved==4
    and halved[3].probability==.5,
 "Optional fragment mode must halve probability only")
expect(visual[3].probability==nil,
 "Optional fragment mode cannot mutate shared source effect")
local wrapped={type="direct",action_delivery={type="instant",
  target_effects={{type="create-particle",particle_name="dust"},
    {type="damage",damage={amount=9,type="fire"}}}}}
local clean,r=source.prune(wrapped,true,false)
expect(r==1 and clean.action_delivery.target_effects[1].type=="damage",
 "Recursive weapon effect pruning must preserve real damage")
local all_visual={type="direct",action_delivery={type="instant",
  target_effects={type="create-particle",particle_name="dust"}}}
local cleared=source.prune(all_visual,true,false)
expect(cleared==nil,"Cosmetic-only effect wrappers must be removed cleanly")
local group={
  ["big-metallic-asteroid"]={dying_trigger_effect=copy(visual)},
  ["huge-promethium-asteroid"]={dying_trigger_effect={
    {type="create-asteroid-chunk",asteroid_name="promethium-asteroid-chunk"}}},
  ["big-auric-asteroid"]={dying_trigger_effect={
    {type="create-asteroid-chunk",asteroid_name="auric-asteroid-chunk"}}},
  ["razi-quality-asteroid-big-metallic-asteroid"]={
    created_effect={type="direct",action_delivery={type="instant",
      target_effects={type="script",effect_id="razi-quality-asteroid-big-metallic-asteroid"}}}}
}
local chunks={
  ["metallic-asteroid-chunk"]={dying_trigger_effect=copy(visual)},
  ["auric-asteroid-chunk"]={}
}
local projectile={
  ["rocket"]={action=copy(wrapped)}
}
local routes={
  home={from="nauvis",to="muluna",asteroid_spawn_definitions={
    {type="entity",asteroid="big-metallic-asteroid",
      spawn_points={{distance=.2,probability=.11}}},
    {type="asteroid-chunk",asteroid="metallic-asteroid-chunk",
      spawn_points={{distance=.2,probability=.31}}}
  }},
  endgame={from="solar-system-edge",to="nexus",
    asteroid_spawn_definitions={
      {type="entity",asteroid="razi-quality-asteroid-big-metallic-asteroid",
        spawn_points={{distance=.2,probability=.20}}},
      {type="asteroid-chunk",asteroid="metallic-asteroid-chunk",
        spawn_points={{distance=.2,probability=.4}}}
    }}
}
local all={
  asteroid=group,["asteroid-chunk"]=chunks,
  projectile=projectile,["space-connection"]=routes
}
rawset(_G,"data",{raw=all})
rawset(_G,"settings",{startup={}})
local function reload()
  package.loaded["prototypes.system.asteroid_performance"]=nil
  return require("prototypes.system.asteroid_performance")
end
expect(reload().data_final_fixes()==0,"Everything off must do nothing")
expect(group["big-metallic-asteroid"].dying_trigger_effect[1].type
  =="create-particle","Default off may not strip any effects")
settings.startup["razi-performance-asteroid-particles"]={value=true}
local perf=reload()
expect(perf.data_final_fixes()>=1,"Cosmetic asteroid mode must change effects")
expect(group["big-metallic-asteroid"].dying_trigger_effect[1].type
  =="create-asteroid-chunk","Debris mode must not alter gameplay spawns")
expect(group["razi-quality-asteroid-big-metallic-asteroid"].created_effect
  .action_delivery.target_effects.effect_id==
    "razi-quality-asteroid-big-metallic-asteroid",
  "Quality-carrier script effects must never be removed")
expect(perf.data_final_fixes()==0,"Data optimizer pass must be idempotent")
settings.startup["razi-performance-asteroid-particles"].value=false
settings.startup["razi-performance-weapon-particles"]={value=true}
perf=reload()
expect(perf.data_final_fixes()>0,"Weapon particle option should strip visuals")
expect(projectile.rocket.action.action_delivery.target_effects[1].type
  =="damage","Weapon damage effects must remain")
settings.startup["razi-performance-weapon-particles"].value=false
settings.startup["razi-performance-reduced-fragments"]={value=true}
perf=reload()
expect(perf.data_final_fixes()>0,"Native chunk spawns should be trimmed")
expect(group["huge-promethium-asteroid"].dying_trigger_effect[1].probability==.5,
  "Promethium fragments must be halved")
expect(group["big-auric-asteroid"].dying_trigger_effect[1].probability==nil,
  "Never silently alter custom Auric asteroid fragmentation")
settings.startup["razi-performance-reduced-fragments"].value=false
settings.startup["razi-performance-outer-hostile-density"]={value=true}
package.loaded["scripts.galactic_catalog"]={system=function(name)
 if name=="nauvis" or name=="muluna" then return "calidus" end
 return "unassigned"
end}
package.loaded["scripts.razi_asteroid_difficulty"]=nil
perf=reload()
expect(perf.data_final_fixes()>0,"Late hostile density option should apply")
expect(math.abs(routes.endgame.asteroid_spawn_definitions[1]
    .spawn_points[1].probability-.144)<.00001,
  "Level 10 hostile carriers should be reduced by 28%")
expect(routes.endgame.asteroid_spawn_definitions[2]
  .spawn_points[1].probability==.4,
  "Collectible chunks must never be reduced by hostile density option")
expect(routes.home.asteroid_spawn_definitions[1]
  .spawn_points[1].probability==.11,
  "Low-level home routes must remain unchanged")
print("Razi asteroid performance opt-in regression passed")
