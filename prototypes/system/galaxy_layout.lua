-- System positions, orbit spacing and the route layout.
-- The local planet/moon relationships need to survive every map pass.
local M = {}

-- Four first/middle systems sit modestly farther from Nauvis; the two outer
-- systems have a wider ring to clear their large optional planet orbits.
-- Deep Space has its own spacious, directional expedition sectors.
-- Factorio's north points toward negative Y.
-- Hot worlds stay closer to their sun, colder worlds farther out.
-- These are visual orbit distances only; gameplay climates remain source-owned.
local anchors = {
  {"space-location","solaris","star",118,0.416667},
  {"space-location","nyxaris","star",118,0.583333},
  {"space-location","vibrant","star",118,0.25},
  {"space-location","vespera","star",118,0.75},
  {"space-location","beetlejuice","star",143,0.083333},
  {"space-location","umbra","star",143,0.916667},
  -- Move the Deep Space parent anchor north: all its source-owned child
  -- worlds, gates and Aegis/Pulsar outposts keep their original parents.
  {"space-location","solar-system-edge","star",268,0},
  -- Four spacious directions: Aegis north, Nexus/Oort/Sol east,
  -- Shattered Planet southeast and the Black Hole west.
  -- These are visual positions only, not route lengths or travel unlocks.
  {"space-location","shattered-planet","solar-system-edge",140,0.33},
  -- Skewer's 1,000 km approach-to-planet hop should LOOK short. Rotate
  -- the actual planet almost due south, rather than 82 chart units east.
  -- Lost Beyond remains a far-flung north-east expedition, with a distinct
  -- lane away from the Nexus / Oort / Sol corridor. Route km are unchanged.
  {"planet","skewer_shattered_planet","shattered-planet",19,0.485},
  {"space-location","skewer_lost_beyond","skewer_shattered_planet",145,0.14},
  {"planet","nexus","solar-system-edge",94,0.18},
  {"space-location","black-hole-approach","solar-system-edge",112,0.70},
  {"space-location","black-hole","black-hole-approach",22,0.72},
  {"space-location","oort-cloud","nexus",90,0.25},
  {"space-location","sol","oort-cloud",106,0.15},
  {"space-location","sye-calidus","star",20,0.5},
  -- Clear west-northwest external gateway, just beyond the orbital rim.
  -- Three interstellar departures fan outward, while the northern arc
  -- from Corrundum to Igrys never intersects the gateway/Vulcanus leg.
  {"space-location","sye-solaris","solaris",44,0.84},
  -- Arrivals begin beyond the western asteroid belt, not inside it.
  {"space-location","sye-vibrant","vibrant",60,0.73},
  {"space-location","sye-beetlejuice","beetlejuice",27,0.5},
  -- Northern arrivals flank the corona instead of threading through it.
  {"space-location","sye-nyxaris","nyxaris",41,0.04},
  {"space-location","sye-vespera","vespera",27,0.25},
  {"space-location","sye-umbra","umbra",54,0.42},
  -- Solaris's compact, asymmetric orbital sweep. Warm inner worlds sit
  -- close to the star; Tellus and the denser industrial worlds are
  -- progressively farther out. Distances are visual, not physical AU.
  -- Clockwise spacing is intentionally nonuniform, keeping names and
  -- source planet icons separate without turning travel into a polygon web.
  {"planet","vulcanus","solaris",17,0.69},
  {"planet","hyarion","solaris",21,0.37},
  {"planet","arig","solaris",24,0.52},
  {"planet","castra","solaris",27,0.61},
  {"planet","tellus","solaris",29,0.26},
  {"planet","corrundum","solaris",33,0.13},
  -- Nyxaris forms an open biological crescent, with the Gleba moons well
  -- away from the gateway and Foliax across the quieter western arc.
  -- These are chart positions only; source production and climate are intact.
  {"planet","gleba","nyxaris",32,0.17},
  {"planet","moshine","nyxaris",22,0.29},
  {"space-location","apia-carnova-orbit","nyxaris",39,0.35},
  {"planet","panglia","nyxaris",40,0.49},
  -- Inner electrical worlds remain inside the belt. Paracelsin and
  -- optional Khemia sit nearer its exterior edge, with a clear road
  -- between them and no extra crossing of the asteroid field.
  {"planet","fulgora","vibrant",24,0.57},
  {"planet","ribbonia","vibrant",26,0.685},
  {"planet","paracelsin","vibrant",48,0.68},
  -- Belt-free Vespera: Muria opens Rubia, then branches to greenhouse
  -- ocean Maraxsis and icy outer Aquilo. All planets are true destinations.
  {"planet","muria","vespera",21,0.43},
  -- Athos's arid stone and diamond industry branches from Muria,
  -- before the outer ocean and cryogenic frontier.
  {"planet","athos","vespera",33,0.565},
  {"planet","aquilo","vespera",57,0.73},
  {"planet","rubia","vespera",42,0.70},
  {"planet","maraxsis","vespera",48,0.85},
  {"planet","cubium","beetlejuice",25.283353,0.355716},
  {"planet","linox-planet_linox","beetlejuice",32.133562,0.244042},
  {"space-location","secretas","beetlejuice",40,0.048826},
  -- Umbra enters from OUTSIDE its 31–39-unit shattered belt, like
  -- Vibrant. The only permitted passage to inner Tenebris/Crucible
  -- is the true Outer Rim -> Inner Rim crossing. Distant Vesta remains
  -- a separate outer branch. Crucible's native landing is unchanged.
  {"planet","tenebris","umbra",24,0.54},
  {"space-location","crucible-orbit","umbra",20,0.63},
  {"space-location","razi-umbra-belt-inner","umbra",31,0.47},
  {"space-location","razi-umbra-belt-outer","umbra",39,0.42},
  {"planet","vesta","umbra",56,0.3},
}

-- The optional worlds were previously repositioned in data-final-fixes
-- with PlanetsLib:update, after PlanetsLib removed the sprite-only star
-- prototypes. Register these known orbital plans with both native passes.
-- Only installed planets are touched; moon owners remain unchanged.
local optional_orbits={
  {name="igrys",star="solaris",radius=35,turn=0.905},
  {name="foliax",star="nyxaris",radius=38,turn=0.86},
  {name="obsidiax",star="umbra",radius=68,turn=0.25},
  -- Carna and Arcanyx remain on the INNER side; neither can be reached
  -- directly from the exterior gateway without its rock crossing.
  {name="carna",star="umbra",radius=29,turn=0.7},
  {name="ferrum",star="beetlejuice",radius=43,turn=0.68},
  -- Shchierbin moves into the outer-world arc alongside Paracelsin.
  -- Both remain well beyond the 31/39-unit asteroid field.
  {name="shchierbin",star="vibrant",radius=65,turn=0.675},
  {name="alchemy-planet",star="vibrant",radius=52,turn=0.625},
  {name="arcanyx",star="umbra",radius=27,turn=0.3},
  -- Balack is an optional outer-ice spur beside Aquilo.
  {name="bm-balack",star="vespera",radius=63,turn=0.70}
}
for _,world in ipairs(optional_orbits) do
  anchors[#anchors+1]={"planet",world.name,world.star,world.radius,world.turn}
end

-- Share one authoritative coordinate manifest with data-stage rendering.
local deep_space_names={
  ["shattered-planet"]=true,["skewer_shattered_planet"]=true,
  ["skewer_lost_beyond"]=true,nexus=true,["black-hole-approach"]=true,
  ["black-hole"]=true,["oort-cloud"]=true,sol=true
}
M.deep_space_orbits={}
for _,item in ipairs(anchors) do
  if deep_space_names[item[2]] then
    M.deep_space_orbits[#M.deep_space_orbits+1]=item
  end
end

-- Source art is preserved, but not giant synthetic destination orbit circles.
local deep_space_no_rings={
  ["solar-system-edge"]=true,["shattered-planet"]=true,nexus=true,
  ["skewer_shattered_planet"]=true,["skewer_lost_beyond"]=true,
  ["black-hole-approach"]=true,["black-hole"]=true,
  ["oort-cloud"]=true,sol=true,pulsar=true,
  ["near-bellicos-orbit"]=true,
  ["calidus-bellicos-stargate-calidus"]=true,
  ["calidus-bellicos-stargate-bellicos"]=true,
  ["aegis-inner-edge"]=true,["aegis-outer-edge"]=true
}

local stars = {
  solaris=true, nyxaris=true, vibrant=true, vespera=true,
  beetlejuice=true, umbra=true
}

-- Sprite-only star prototypes are removed during PlanetsLib data-final-fixes.
-- PlanetsLib draws the star ART first and then deletes these prototypes.
-- Consequently a PlanetsLib:update call after that point SILENTLY SKIPS the
-- whole galaxy when its code is guarded by exists("space-location", parent).
-- Use native origins after cleanup; never recreate deleted sprite-only stars.
local by_name = {}
for _,item in ipairs(anchors) do by_name[item[2]]=item end

local function exists(kind,name)
  return (data.raw[kind] or {})[name]
end

local function polar(distance,orientation)
  local theta=2*math.pi*orientation
  return distance*math.sin(theta),-distance*math.cos(theta)
end

local virtual_cache={star={x=0,y=0}}
local function anchor_position(name)
  local cached=virtual_cache[name]
  if cached then return cached.x,cached.y end
  local anchor=by_name[name]
  if not anchor then return nil end
  local px,py=anchor_position(anchor[3])
  if not px then return nil end
  local x,y=polar(anchor[4],anchor[5])
  virtual_cache[name]={x=px+x,y=py+y}
  return px+x,py+y
end

-- Shared absolute starmap coordinates for third-party visual layers.
-- This is data-only and valid even after PlanetsLib deletes sprite-only stars.
M.anchor_position=anchor_position

local function resolved(item)
  local kind=item[1]
  local proto=exists(kind,item[2])
  if not proto and item[2]=="alchemy-planet" and kind=="planet" then
    kind="space-location"
    proto=exists(kind,item[2])
  end
  return kind,proto
end

-- The native Rabbasca moon is exceptionally tight around Gleba.
-- Rotate it into the southwest gap without changing its parent or travel.
-- The source's other selectable parent planets are left alone.
local rabbasca_radius,rabbasca_turn=4.2,0.65
local function position_rabbasca()
  local moon=exists("planet","rabbasca")
  local orbit=moon and moon.orbit
  local parent=orbit and orbit.parent
  if not (parent and parent.type=="planet" and parent.name=="gleba") then
    return false
  end
  orbit.distance=rabbasca_radius
  orbit.orientation=rabbasca_turn
  moon.distance=rabbasca_radius
  moon.orientation=rabbasca_turn
  return true
end

local function source_orbit(item)
  local _,existing=resolved(item)
  local old=existing and existing.orbit
  -- Preserve most source orbit art, except stray dotted trails on Carna.
  local parent_type=exists("planet",item[3]) and "planet" or "space-location"
  local orbit={
    parent={type=parent_type,name=item[3]},
    distance=item[4],orientation=item[5]
  }
  if old and old.sprite and item[2]~="carna"
    and not deep_space_no_rings[item[2]] then
    orbit.sprite=old.sprite
  end
  return orbit
end

-- MUST run in data-updates, while PlanetsLib still has sprite_only anchors.
-- This moves their graphical layers when PlanetsLib renders the starmap.
local function clear_source_trails()
  -- Strip only decorative orbit textures, not planet icons, moon parents or
  -- actual travel routes. These tails appear as disconnected red dotted bars.
  for _,name in ipairs({"carna","velora"}) do
    for _,kind in ipairs({"planet","space-location"}) do
      local proto=exists(kind,name)
      if proto and proto.orbit then proto.orbit.sprite=nil end
    end
  end
end

function M.data_updates()
  clear_source_trails()
  for name in pairs(stars) do
    assert(exists("space-location",name),
      "Razi starmap: required sprite-only star missing before PlanetsLib cleanup: "..name)
  end
  local updates={}
  for _,item in ipairs(anchors) do
    local kind,proto=resolved(item)
    if proto and (exists("space-location",item[3]) or exists("planet",item[3])) then
      updates[#updates+1]={
        type=kind,name=item[2],orbit=source_orbit(item)
      }
    end
  end
  if #updates>0 then PlanetsLib:update(updates) end
  -- Set the moon orbit before PlanetsLib bakes its decorative layers.
  position_rabbasca()
  -- Some ports can expose both prototype types under the source ID. Move
  -- both before PlanetsLib bakes starmap art so no duplicate stays at home.
  if exists("planet","alchemy-planet") and exists("space-location","alchemy-planet") then
    local item=by_name["alchemy-planet"]
    local other=exists("space-location","alchemy-planet")
    local orbit={
      parent={type="space-location",name=item[3]},
      distance=item[4],orientation=item[5]
    }
    if other.orbit and other.orbit.sprite then
      orbit.sprite=other.orbit.sprite
    end
    PlanetsLib:update({{
      type="space-location",name="alchemy-planet",orbit=orbit
    }})
    if type(log)=="function" then
      log("[Razi Protocol/Calidus] Repositioned duplicate Khemia space-location BEFORE sprite baking")
    end
  end
  -- Position source-owned Khemia before PlanetsLib bakes its map sprite.
  -- Use the shared orbit plan, not a second hard-coded location.
  local vx,vy=anchor_position("vibrant")
  local khemia=by_name["alchemy-planet"]
  if vx and vy and khemia then
    for _,kind in ipairs({"planet","space-location"}) do
      local body=exists(kind,"alchemy-planet")
      if body then
        local orbit={
          parent={type="space-location",name=khemia[3]},
          distance=khemia[4],orientation=khemia[5]
        }
        if body.orbit and body.orbit.sprite then
          orbit.sprite=body.orbit.sprite
        end
        body.orbit=orbit
        body.origin={x=vx,y=vy}
        body.distance=khemia[4]
        body.orientation=khemia[5]
        if type(log)=="function" then
          log("[Razi Protocol/Calidus] PRE-RENDER forced Khemia to Vibrant: "..kind)
        end
      end
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/starmap] PRE-RENDER-2026-10-11-v3: positioned six sprite-only stars before PlanetsLib cleanup")
    for name in pairs(stars) do
      local proto=exists("space-location",name)
      local x,y=polar(proto.distance or 0,proto.orientation or 0)
      local px,py=anchor_position(name)
      log(string.format("[Razi Protocol/starmap] pre-render %s native=(%.2f,%.2f) expected=(%.2f,%.2f)",
        name,x,y,px,py))
    end
  end
end

local function adjust_layer(name,px,py)
  local graphics=exists("utility-sprites","default")
  local layers=graphics and graphics.starmap_star and graphics.starmap_star.layers
  for _,layer in ipairs(layers or {}) do
    if layer.planetslib_orbit_name==name and layer.planetslib_orbit_shift then
      layer.shift={
        layer.planetslib_orbit_shift[1]+px*32,
        layer.planetslib_orbit_shift[2]+py*32
      }
    end
  end
end

-- Runs AFTER PlanetsLib deletes all sprite_only stars. Update the remaining
-- Factorio-native geometry directly rather than attempting to reparent through
-- missing star prototypes. Preserve source children, e.g. Frozeta's moon orbit.
local function remove_baked_source_trails()
  -- PlanetsLib may have already baked an old orbit.sprite into the shared
  -- star atlas on another mod's stage. These layers are orbit decorations,
  -- not the clickable planet icon or the actual space-connection.
  local ui=exists("utility-sprites","default")
  local layers=ui and ui.starmap_star and ui.starmap_star.layers
  if not layers then return 0 end
  local removed=0
  for index=#layers,1,-1 do
    local layer=layers[index]
    local name=layer and layer.planetslib_orbit_name
    local asset=layer and layer.filename
    -- Aegis art is source-authored: its pulsar and debris sprites need
    -- not include "pulsar" in the filename (0.4.x external graphics pack).
    -- Never strip these baked PlanetsLib layers. Native orbit circles are
    -- hidden separately via draw_orbit=false, without deleting source art.
    local bellicos_art=name=="pulsar"
      or name=="near-bellicos-orbit" or name=="bellicos-near-orbit"
      or name=="near_bellicos_orbit" or name=="aegis-inner-edge"
      or name=="aegis-outer-edge" or name=="point-warden"
      or name=="calidus-bellicos-stargate-bellicos"
      or name=="calidus-bellicos-stargate-calidus"
    if layer and layer.planetslib_orbit_shift
      and (name=="carna" or name=="velora"
        or (deep_space_no_rings[name] and not bellicos_art)) then
      table.remove(layers,index)
      removed=removed+1
    end
  end
  return removed
end

function M.data_final_fixes()
  clear_source_trails()
  local removed_trails=remove_baked_source_trails()
  if removed_trails>0 and type(log)=="function" then
    log("[Razi Protocol/starmap] Removed "..removed_trails..
      " obsolete source and Deep Space decorative orbit layers")
  end
  local relocated={}
  local count=0
  for name in pairs(stars) do
    local x,y=anchor_position(name)
    relocated[name]={x=x,y=y}
  end

  for _,item in ipairs(anchors) do
    local _,location=resolved(item)
    local px,py=anchor_position(item[3])
    local parent_ok=stars[item[3]] or item[3]=="star"
      or exists("space-location",item[3]) or exists("planet",item[3])
    if location and px and py and parent_ok then
      local orbit=source_orbit(item)
      location.orbit=orbit
      location.origin={x=px,y=py}
      location.distance=item[4]
      location.orientation=item[5]
      local dx,dy=polar(item[4],item[5])
      relocated[item[2]]={x=px+dx,y=py+dy}
      adjust_layer(item[2],px,py)
      count=count+1
    end
  end

  -- Reapply the visual moon turn after optional source-mod positioning.
  position_rabbasca()

  -- Any source-owned orbit not explicitly in our layout must travel with its
  -- moved parent. Keep the source's relative native distance/orientation and
  -- custom orbit sprite intact. Multiple passes handle nested moon systems.
  for _=1,8 do
    local changed=false
    for _,kind in ipairs({"planet","space-location"}) do
      for name,location in pairs(data.raw[kind] or {}) do
        if not by_name[name] then
          local parent=location.orbit and location.orbit.parent
          local origin=parent and relocated[parent.name]
          if origin and parent.name~="star" and not relocated[name] then
            local radius=location.distance
            local turn=location.orientation
            if radius==nil then radius=location.orbit.distance end
            if turn==nil then turn=location.orbit.orientation end
            if radius and turn then
              location.origin={x=origin.x,y=origin.y}
              local dx,dy=polar(radius,turn)
              relocated[name]={x=origin.x+dx,y=origin.y+dy}
              adjust_layer(name,origin.x,origin.y)
              changed=true
            end
          end
        end
      end
    end
    if not changed then break end
  end

  -- Factorio draws labels relative to their location, and compact waypoints
  -- can otherwise overlap each other even when the icons are distinct.
  -- Most labels retain source preferences. Gleba and its moons receive
  -- separate directions to avoid overlap at galaxy zoom.
  local label_orientations={
    -- Separate the compact home-system labels without moving source moons.
    ["nauvis"]=0.25,["muluna"]=0.75,
    ["close-sun-orbit"]=0.75,["sun-orbit"]=0.25,
    ["sye-calidus"]=0.25,
    ["apia-carnova-orbit"]=0.75,
    ["apia"]=0.25,["carnova"]=0.75,
    -- Fan Gleba and its two source-owned moon labels in three directions.
    ["gleba"]=0.5,["rabbasca"]=0.75,["velora"]=0.25,
    ["frozeta"]=0.25,
    ["igrys"]=0.25,["foliax"]=0.25,
    ["obsidiax"]=0.25,["carna"]=0.75,
    -- Two source-owned Crucible destinations occupy nearly the same
    -- chart point; split their captions in opposite directions.
    ["crucible-orbit"]=0.75,["crucible"]=0.25,
    ["tenebris"]=0.75,["arcanyx"]=0.0,
    ["aquilo"]=0.75,
    ["ferrum"]=0.75,["alchemy-planet"]=0.25,
    ["athos"]=0.75,["shchierbin"]=0.75,["obsidiax"]=0.75,["abacayba"]=0.25,
    ["arcanyx"]=0.25,["bm-balack"]=0.75,
    ["sye-solaris"]=0.75, ["sye-nyxaris"]=0.75,
    ["sye-vibrant"]=0.75, ["sye-vespera"]=0.25,
    ["asteroid-belt-inner-edge"]=0.75,
    ["asteroid-belt-outer-edge"]=0.25,
    ["sye-beetlejuice"]=0.75, ["sye-umbra"]=0.5,
    ["razi-umbra-belt-inner"]=0.25,
    ["razi-umbra-belt-outer"]=0.25,
    ["solar-system-edge"]=0.75,["nexus"]=0.25,
    ["oort-cloud"]=0.75,["sol"]=0.25,
    -- Opposing labels and a vertical approach keep the two different
    -- Shattered destinations legible at native Factorio chart zoom.
    ["shattered-planet"]=0.75,["skewer_shattered_planet"]=0.25,
    ["skewer_lost_beyond"]=0.25,["black-hole-approach"]=0.25,
    ["black-hole"]=0.75,
    ["calidus-bellicos-stargate-calidus"]=0.75,
    -- The Bellicos locations are staggered in two dimensions. Opposing
    -- captions prevent Warden and the Aegis belt from sharing one baseline.
    ["near-bellicos-orbit"]=0.25,
    ["aegis-inner-edge"]=0.75,
    ["point-warden"]=0.25,
    ["aegis-outer-edge"]=0.25,
    ["calidus-bellicos-stargate-bellicos"]=0.75
  }
  for name,direction in pairs(label_orientations) do
    local marker=exists("space-location",name) or exists("planet",name)
    if marker then marker.label_orientation=direction end
  end

  -- PlanetsLib 2.0 uses native Factorio 2.1 origin-based orbit drawing.
  -- Full is the default native chart, with Balanced/Clean for fewer
  -- rings and Off for none of Razi's native planetary rings. Preserve
  -- source moon orbits and existing handcrafted orbit sprites.
  local orbit_setting=settings and settings.startup
    and settings.startup["razi-starmap-orbit-density"]
  local density=orbit_setting and orbit_setting.value or "full"
  local balanced={
    castra=true,moshine=true,panglia=true,
    fulgora=true,paracelsin=true,muria=true,aquilo=true,
    cubium=true,tenebris=true
  }
  local clean={
    castra=true,panglia=true,fulgora=true,
    aquilo=true,cubium=true,tenebris=true
  }
  for name,planet in pairs(data.raw.planet or {}) do
    local parent=planet.orbit and planet.orbit.parent
    if by_name[name] and parent and parent.type=="space-location"
      and stars[parent.name] and not planet.hidden
      and not (planet.orbit and planet.orbit.sprite) then
      planet.draw_orbit=density=="full"
        or (density=="balanced" and balanced[name]==true)
        or (density=="clean" and clean[name]==true)
    end
  end
  local secretas=exists("space-location","secretas")
  if secretas and relocated.secretas and not (secretas.orbit and secretas.orbit.sprite) then
    secretas.draw_orbit=density=="full" or density=="balanced"
  end

  for _,name in ipairs({
    "solaris","nyxaris","vibrant","vespera","beetlejuice","umbra",
    "solar-system-edge","shattered-planet","nexus",
    "skewer_shattered_planet","skewer_lost_beyond",
    "black-hole-approach","black-hole","oort-cloud","sol",
    "pulsar","near-bellicos-orbit",
    "calidus-bellicos-stargate-calidus","calidus-bellicos-stargate-bellicos",
    "aegis-inner-edge","aegis-outer-edge","sye-calidus",
    "sye-solaris","sye-nyxaris",
    "sye-vibrant","sye-vespera","sye-beetlejuice","sye-umbra"
  }) do
    local location=exists("space-location",name)
    if location then location.draw_orbit=false end
  end
  -- Nexus is a planet, not a space-location: hide its extra ring too.
  for name in pairs(deep_space_no_rings) do
    local planet=exists("planet",name)
    if planet then planet.draw_orbit=false end
  end

  if type(log)=="function" then
    log("[Razi Protocol/starmap] NATIVE-2026-10-11-v4: placed "..count..
      " live anchors after sprite-only cleanup; stars are virtual")
    for _,item in ipairs(anchors) do
      if stars[item[2]] or item[2]=="solar-system-edge" then
        local ex,ey=anchor_position(item[2])
        local loc=exists(item[1],item[2])
        if loc then
          local dx,dy=polar(loc.distance or 0,loc.orientation or 0)
          local origin=loc.origin or {}
          local x=(origin.x or origin[1] or 0)+dx
          local y=(origin.y or origin[2] or 0)+dy
          log(string.format("[Razi Protocol/starmap] %s expected=(%.2f,%.2f) native=(%.2f,%.2f)",
            item[2],ex,ey,x,y))
        else
          log(string.format("[Razi Protocol/starmap] %s virtual-star-art=(%.2f,%.2f), rendered pre-cleanup",
            item[2],ex,ey))
        end
      end
    end
  end
end

-- Repair Khemia after any independent compatibility pass, preserving its
-- world coordinates while restoring a native Vibrant-centered orbit.
-- A source can expose two prototype types; only the primary draws a ring.
function M.confirm_critical_positions()
  for _,name in ipairs({"alchemy-planet"}) do
    local item=by_name[name]
    if item then
      local x,y=anchor_position(item[3])
      if x and y then
        local configured=settings and settings.startup
          and settings.startup["razi-starmap-orbit-density"]
        local density=configured and configured.value or "full"
        local primary=exists("planet",name) and "planet" or "space-location"
        -- Correct both possible prototype types, but draw only one ring.
        for _,kind in ipairs({"planet","space-location"}) do
          local proto=exists(kind,name)
          if proto then
            local old=proto.orbit
            local orbit={
              parent={type="space-location",name=item[3]},
              distance=item[4],orientation=item[5]
            }
            if old and old.sprite then orbit.sprite=old.sprite end
            proto.orbit=orbit
            local dx,dy=polar(item[4],item[5])
            -- Factorio draws native circles about origin. Using Khemia's
            -- absolute galactic polar coordinates would create a false
            -- ring around Calidus even if the planet icon looked correct.
            proto.origin={x=x,y=y}
            proto.distance=item[4]
            proto.orientation=item[5]
            proto.draw_orbit=kind==primary and density=="full"
              and not (old and old.sprite) and not proto.hidden
            if type(log)=="function" then
              local o=proto.origin or {}
              local px,py=polar(proto.distance,proto.orientation)
              px=px+(o.x or o[1] or 0)
              py=py+(o.y or o[2] or 0)
              log(string.format(
                "[Razi Protocol/starmap] FINAL %s (%s) actual %.2f,%.2f target %.2f,%.2f",
                name,kind,px,py,x+dx,y+dy))
            end
          end
        end
        adjust_layer(name,x,y)
      end
    end
  end

  -- Compare the effective *rendered* coordinates instead of asserting on
  -- origin values alone. This catches the regression where Khemia had the
  -- correct parent metadata but was visibly still next to Nauvis.
  local vx,vy=anchor_position("vibrant")
  local count=0
  if vx and vy then
    local item=by_name["alchemy-planet"]
    local dx,dy=polar(item[4],item[5])
    local targetX,targetY=vx+dx,vy+dy
    for _,kind in ipairs({"planet","space-location"}) do
      local body=exists(kind,"alchemy-planet")
      if body then
        count=count+1
        local ox,oy=polar(body.distance or 0,body.orientation or 0)
        local origin=body.origin or {}
        ox=ox+(origin.x or origin[1] or 0)
        oy=oy+(origin.y or origin[2] or 0)
        assert(math.abs(ox-targetX)<.01 and math.abs(oy-targetY)<.01
          and body.origin and math.abs(body.origin.x-vx)<.01
          and math.abs(body.origin.y-vy)<.01,
          "Khemia's origin or coordinates are outside Vibrant: "..kind)
        if type(log)=="function" then
          log(string.format(
            "[Razi Protocol/Vibrant] Khemia %s native %.2f,%.2f target %.2f,%.2f; ring=%s",
            kind,ox,oy,targetX,targetY,tostring(body.draw_orbit)))
        end
      end
    end
  end
  if type(log)=="function" then
    local art=(data.raw["utility-sprites"] or {}).default
    local star=art and art.starmap_star
    local marked=0
    for _,layer in ipairs(star and star.layers or {}) do
      if layer.planetslib_orbit_name=="alchemy-planet" then
        marked=marked+1
        local pos=layer.shift or {}
        log(string.format(
          "[Razi Protocol/Calidus] Khemia orbit-art layer (%s,%s)",
          tostring(pos[1] or pos.x),tostring(pos[2] or pos.y)))
      end
    end
    log("[Razi Protocol/Calidus] Khemia audit: "..count..
      " native prototypes, "..marked.." PlanetsLib orbit-art layers")
  end
  if mods and mods["alchemy-khemia"] and count==0 and type(log)=="function" then
    log("[Razi Protocol/Calidus] WARNING: Khemia mod present but no matching map prototype")
  end
end

return M
