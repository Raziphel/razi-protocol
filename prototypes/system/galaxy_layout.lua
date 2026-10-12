-- System positions, orbit spacing and the route layout.
-- The local planet/moon relationships need to survive every map pass.
local M = {}

-- Star positions follow the three expedition tiers.
-- Factorio's north points toward negative Y.
-- Hot worlds stay closer to their sun, colder worlds farther out.
-- These are visual orbit distances only; gameplay climates remain source-owned.
local anchors = {
  {"space-location","solaris","star",104,0.416667},
  {"space-location","nyxaris","star",104,0.583333},
  {"space-location","vibrant","star",104,0.25},
  {"space-location","vespera","star",104,0.75},
  {"space-location","beetlejuice","star",104,0.083333},
  {"space-location","umbra","star",104,0.916667},
  {"space-location","solar-system-edge","star",190,0},
  {"space-location","sye-calidus","star",20,0.5},
  -- A compact station-sized salvage destination opposite the departure hub.
  {"space-location","razi-calidus-drift","star",33,0.865},
  {"space-location","sye-solaris","solaris",27,0.75},
  {"space-location","sye-vibrant","vibrant",28.017851,0.653265},
  {"space-location","sye-beetlejuice","beetlejuice",27,0.5},
  {"space-location","sye-nyxaris","nyxaris",27,0},
  {"space-location","sye-vespera","vespera",26,0.25},
  {"space-location","sye-umbra","umbra",27,0.5},
  {"planet","vulcanus","solaris",18,0.690759},
  {"planet","castra","solaris",38.550528,0.554718},
  {"planet","arig","solaris",27,0.48},
  -- Separate Hyarion and Vulcanus orbit rings while retaining their climate tiers.
  {"planet","hyarion","solaris",22,0.389024},
  {"planet","tellus","solaris",33.571265,0.249329},
  {"planet","corrundum","solaris",24.630737,0.076626},
  {"planet","gleba","nyxaris",32,0.091528},
  {"planet","moshine","nyxaris",22,0.245823},
  -- Apia/Carnova no longer shares an almost identical ring with Gleba.
  {"space-location","apia-carnova-orbit","nyxaris",39,0.316108},
  -- Dedicated orbital lane: visually distinct from Apia and Moshine.
  {"planet","panglia","nyxaris",44,0.44},
  {"planet","fulgora","vibrant",22,0.558152},
  {"planet","ribbonia","vibrant",27,0.397307},
  {"planet","paracelsin","vibrant",49,0.238},
  {"planet","muria","vespera",20,0.394284},
  {"planet","aquilo","vespera",40,0.497561},
  {"space-location","razi-vespera-belt-inner","vespera",28.834477,0.594031},
  {"space-location","razi-vespera-belt-outer","vespera",28.890877,0.654938},
  {"planet","rubia","vespera",31,0.739398},
  {"planet","maraxsis","vespera",44,0.857126},
  {"planet","cubium","beetlejuice",25.283353,0.355716},
  {"planet","linox-planet_linox","beetlejuice",32.133562,0.244042},
  {"space-location","secretas","beetlejuice",40,0.048826},
  {"planet","tenebris","umbra",25.283353,0.644284},
  {"space-location","crucible-orbit","umbra",19,0.753257},
  {"space-location","razi-umbra-belt-inner","umbra",30.694865,0.832453},
  {"space-location","razi-umbra-belt-outer","umbra",29.792826,0.895144},
  {"planet","vesta","umbra",29.600886,0.004323},
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

local function source_orbit(item)
  local existing=exists(item[1],item[2])
  local old=existing and existing.orbit
  -- Preserve source-owned dashed/custom orbit artwork.
  local orbit={
    parent={type="space-location",name=item[3]},
    distance=item[4],orientation=item[5]
  }
  if old and old.sprite then orbit.sprite=old.sprite end
  return orbit
end

-- MUST run in data-updates, while PlanetsLib still has sprite_only anchors.
-- This moves their graphical layers when PlanetsLib renders the starmap.
function M.data_updates()
  for name in pairs(stars) do
    assert(exists("space-location",name),
      "Razi starmap: required sprite-only star missing before PlanetsLib cleanup: "..name)
  end
  local updates={}
  for _,item in ipairs(anchors) do
    if exists(item[1],item[2]) and exists("space-location",item[3]) then
      updates[#updates+1]={
        type=item[1],name=item[2],orbit=source_orbit(item)
      }
    end
  end
  if #updates>0 then PlanetsLib:update(updates) end
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
function M.data_final_fixes()
  local relocated={}
  local count=0
  for name in pairs(stars) do
    local x,y=anchor_position(name)
    relocated[name]={x=x,y=y}
  end

  for _,item in ipairs(anchors) do
    local location=exists(item[1],item[2])
    local px,py=anchor_position(item[3])
    if location and px and py then
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
  -- Only Razi-owned hubs and rims get fixed orientations. Native planet,
  -- moon and optional third-party label preferences remain source-owned.
  local label_orientations={
    ["razi-calidus-drift"]=0.75,
    ["sye-solaris"]=0.75, ["sye-nyxaris"]=0.75,
    ["sye-vibrant"]=0.75, ["sye-vespera"]=0.25,
    ["sye-beetlejuice"]=0.75, ["sye-umbra"]=0.25,
    ["razi-vespera-belt-inner"]=0.25,
    ["razi-vespera-belt-outer"]=0.75,
    ["razi-umbra-belt-inner"]=0.75,
    ["razi-umbra-belt-outer"]=0.25
  }
  for name,direction in pairs(label_orientations) do
    local marker=exists("space-location",name)
    if marker then marker.label_orientation=direction end
  end

  -- Native orbits on actual planets are drawn automatically by Factorio.
  -- Do not suppress every circle or replace third-party moon artwork.
  for _,planet in pairs(data.raw.planet or {}) do
    local parent=planet.orbit and planet.orbit.parent
    if parent and parent.type=="space-location" and stars[parent.name]
      and not (planet.orbit and planet.orbit.sprite) then
      planet.draw_orbit=true
    end
  end
  local secretas=exists("space-location","secretas")
  if secretas and relocated.secretas and not (secretas.orbit and secretas.orbit.sprite) then
    secretas.draw_orbit=true
  end

  for _,name in ipairs({
    "solaris","nyxaris","vibrant","vespera","beetlejuice","umbra",
    "solar-system-edge","sye-calidus","sye-solaris","sye-nyxaris",
    "sye-vibrant","sye-vespera","sye-beetlejuice","sye-umbra"
  }) do
    local location=exists("space-location",name)
    if location then location.draw_orbit=false end
  end

  if type(log)=="function" then
    log("[Razi Protocol/starmap] NATIVE-2026-10-11-v3: placed "..count..
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

return M
