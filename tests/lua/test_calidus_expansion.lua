package.path="./?.lua;./?/init.lua;"..package.path
local function ok(value,message) if not value then error(message,2) end end
package.loaded["prototypes.system.asteroid_profiles"]={
  belt_edge_resources=function(v)
    ok(v==0.55,"Salvage intensity changed")
    return {{type="asteroid-chunk",asteroid="metallic-asteroid-chunk",probability=.06*v}}
  end
}
rawset(_G,"data",{raw={
  ["space-location"]={},
  technology={
    ["space-science-pack"]={effects={{type="unlock-recipe",recipe="dummy"}}},
    ["planet-discovery-muluna"]={effects={}}
  }
}})
rawset(_G,"PlanetsLib",{extend=function(_,all)
  for _,proto in ipairs(all) do data.raw[proto.type][proto.name]=proto end
end})
local mod=require("prototypes.system.calidus_expansion")
mod.data()
local drift=data.raw["space-location"][mod.name]
ok(drift and drift.draw_orbit==false,"Missing orbital salvage prototype")
ok(drift.icon_size==64 and drift.starmap_icon_size==64,"Invalid icon sizes")
ok(drift.asteroid_spawn_definitions[1].probability<.04,"Overpowered stop")
mod.data()
local count=0
for _ in pairs(data.raw["space-location"]) do count=count+1 end
ok(count==1,"Repeated extension duplicated destination")
ok(mod.data_final_fixes(),"Space science unlock missing")
ok(#data.raw.technology["space-science-pack"].effects==2,"Missing tech effect")
ok(mod.data_final_fixes() and
  #data.raw.technology["space-science-pack"].effects==2,"Effect duplicated")
ok(#data.raw.technology["planet-discovery-muluna"].effects==0,
  "Optional fallback should not alter Muluna when main tech exists")
data.raw.technology["space-science-pack"]=nil
ok(mod.data_final_fixes(),"Muluna fallback missing")
ok(data.raw.technology["planet-discovery-muluna"].effects[1].space_location==mod.name,
  "Wrong fallback location")
data.raw.technology["planet-discovery-muluna"]=nil
ok(not mod.data_final_fixes(),"Missing source research should fail closed")
print("Calidus home-system fixtures passed")
