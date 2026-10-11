---@diagnostic disable: missing-fields, need-check-nil, undefined-field
package.path="./?.lua;./?/init.lua;"..package.path

local function check(ok,message)
  if not ok then error(message,2) end
end

local ring="__AsteroidBelt__/graphics/sprite/asteroid-belt.png"

local function run(with_outer,with_mod)
  local inner={
    name="asteroid-belt-inner-edge",
    starmap_icon="__AsteroidBelt__/graphics/icon/inner-belt-edge-starmap.png",
    asteroid_spawn_definitions={{asteroid="metallic-asteroid-chunk",probability=.08}}
  }
  local outer={
    name="asteroid-belt-outer-edge",
    starmap_icon="__AsteroidBelt__/graphics/icon/outer-belt-edge-starmap.png",
    asteroid_spawn_definitions={{asteroid="large-metallic-asteroid",probability=.08}}
  }
  local locations={
    star={name="star"},
    [inner.name]=inner
  }
  if with_outer then locations[outer.name]=outer end
  local stars={
    {filename="__core__/graphics/icons/starmap-star.png"},
    {filename=ring},
    {filename="__another-mod__/graphics/starmap/background.png"}
  }
  local original_native={
    name="asteroid-belt-inner-edge-asteroid-belt-outer-edge",
    from=inner.name,to=outer.name,length=5000,
    asteroid_spawn_definitions={{asteroid="source-asteroid",probability=.13}}
  }
  local raw={
    ["space-location"]=locations,planet={},
    ["space-connection"]={[original_native.name]=original_native},
    ["utility-sprites"]={default={starmap_star={layers=stars}}}
  }
  rawset(_G,"data",{raw=raw})
  rawset(_G,"mods",with_mod and {AsteroidBelt="1.2.11"} or {})
  rawset(_G,"PlanetsLib",{update=function(_,entries)
    for _,entry in ipairs(entries) do
      local proto=raw[entry.type] and raw[entry.type][entry.name]
      check(proto,"Reparented an absent source prototype")
      check(raw[entry.orbit.parent.type][entry.orbit.parent.name],
        "Invalid source belt parent")
      proto.orbit=entry.orbit
    end
  end})

  package.loaded["prototypes.system.asteroid_belt_integration"]=nil
  local integration=require("prototypes.system.asteroid_belt_integration")
  integration.data_final_fixes()
  return integration,raw,inner,outer,original_native,stars
end

local module,raw,inner,outer,native,layers=run(true,true)
check(inner.orbit.distance>45 and outer.orbit.distance>50,
  "AsteroidBelt was not placed at the mid/outer boundary")
check(inner.orbit.parent.name=="star" and outer.orbit.parent.name=="star",
  "Native belt locations must remain space-location descendants of star")
check(inner.orbit.orientation>.85 and outer.orbit.orientation>.85,
  "The source crossing must point south through the campaign")
check(inner.draw_orbit==false and outer.draw_orbit==false,
  "Old origin-centered asteroid belt rings still appear")
check(#layers==3 and layers[2].filename==ring and layers[2].scale==0.85
  and layers[3].filename=="__another-mod__/graphics/starmap/background.png",
  "The original source asteroid graphic must remain, scaled modestly")
check(raw["space-connection"][native.name]==native
  and native.asteroid_spawn_definitions[1].asteroid=="source-asteroid",
  "Razi deleted or rewrote the source belt's asteroid hazards")
check(inner.starmap_icon:find("__AsteroidBelt__",1,true)
  and outer.starmap_icon:find("__AsteroidBelt__",1,true),
  "Source mod belt artwork was replaced")
module.data_final_fixes()
check(#layers==3 and layers[2].scale==0.28,
  "Source asteroid sprite should never be removed or duplicated")

local _,partial,missing_inner=run(false,true)
check(missing_inner.orbit and not partial["space-location"]["asteroid-belt-outer-edge"],
  "A missing optional source endpoint caused the loading error")
local _,disabled,no_mod_inner=run(true,false)
check(not no_mod_inner.orbit,
  "Missing required mod must not silently rewrite other prototypes")

local f=assert(io.open("info.json","r"))
local info=f:read("*a")
f:close()
check(info:find('"AsteroidBelt >= 1.2.11"',1,true),
  "The original Asteroid Belt must be a Factorio 2.1 required dependency")
print("Required AsteroidBelt source artwork, native hazards and placement passed")
