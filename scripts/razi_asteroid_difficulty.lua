-- Razi quality-asteroid threat ladder. Pure Lua: available to data and control.
-- Rank is a ten-stage *hazard* scale, NOT ten new Factorio quality prototypes.
-- Level 10 is legendary for every eligible hostile asteroid.
local M={}
local members=require("scripts.galactic_catalog")
-- System floors only. Specific planets grow substantially *within* each
-- chapter; one flat system tier left late worlds stuck around level 5.
local base={calidus=1,solaris=2,nyxaris=2,vibrant=4,vespera=5,
  beetlejuice=7,umbra=8,["deep-space"]=10,unassigned=4}
-- All first-party campaign destinations, plus compatible optional
-- sources and the last-stage Aegis/Bellicos annex. Unknown optional
-- endpoints are inferred from their actual FINAL connection neighbours.
local exceptional={
  ["nauvis"]=1,["muluna"]=1,["sye-calidus"]=1,
  ["sye-solaris"]=2,["sye-nyxaris"]=2,
  ["vulcanus"]=2,["castra"]=3,["arig"]=3,["hyarion"]=3,
  ["tellus"]=4,["corrundum"]=4,["igrys"]=4,["igrys-orbit"]=4,
  ["gleba"]=2,["rabbasca"]=3,["moshine"]=3,
  ["apia"]=3,["carnova"]=3,["apia-carnova-orbit"]=3,
  ["panglia"]=4,["pelagos"]=4,["foliax"]=4,["velora"]=4,
  ["lemures"]=4,["prosephina"]=4,
  ["dea-dia-system-edge"]=4,["razi-dea-dia-slip-stream"]=4,
  ["sye-vibrant"]=4,["fulgora"]=4,["cerys"]=5,
  ["ribbonia"]=5,["paracelsin"]=5,["alchemy-planet"]=6,
  ["shchierbin"]=6,["asteroid-belt-inner-edge"]=5,
  ["asteroid-belt-outer-edge"]=6,
  ["sye-vespera"]=5,["muria"]=5,["rubia"]=6,
  ["maraxsis"]=7,["aquilo"]=7,["nulla"]=7,
  ["bm-balack"]=7,["athos"]=7,
  ["sye-beetlejuice"]=7,["cubium"]=7,
  ["linox-planet_linox"]=8,["secretas"]=8,
  ["frozeta"]=8,["ferrum"]=8,["planet-ferrum"]=8,
  ["sye-umbra"]=8,["tenebris"]=8,["carna"]=8,
  ["arcanyx"]=9,["crucible"]=9,["crucible-orbit"]=9,
  ["vesta"]=9,["obsidiax"]=9,["abacayba"]=9,
  ["razi-umbra-belt-inner"]=8,["razi-umbra-belt-outer"]=9,
  ["solar-system-edge"]=10,["razi-deep-space-edge"]=10,
  ["shattered-planet"]=10,["nexus"]=10,
  ["black-hole-approach"]=10,["black-hole"]=10,
  ["oort-cloud"]=10,["sol"]=10,
  -- Shared first-frontier Aegis ramps from 8 at its entry to 10 by
  -- the late Bellicos interior. Legacy Calidus gate IDs never imply safety.
  ["calidus-bellicos-stargate-calidus"]=8,
  ["calidus-bellicos-stargate-bellicos"]=10,
  ["pulsar"]=9,["aegis-inner-edge"]=8,
  ["aegis-outer-edge"]=9,["point-warden"]=9,
  ["near-bellicos-orbit"]=9,["bellicos-near-orbit"]=9,
  ["near_bellicos_orbit"]=9,
  -- Source-owned fractured routes branching from Shattered Planet.
  ["skewer_shattered_planet"]=10,
  ["skewer_lost_beyond"]=10,
  -- SLP uses source-owned orbits rather than Razi's Calidus hub.
  -- Both need a real late-game quality tier even when connected to Nauvis.
  ["sun-orbit"]=9,["close-sun-orbit"]=10,
  ["slp-solar-orbit-outer"]=9,["slp-solar-orbit-inner"]=10
}
M.explicit_levels=exceptional
-- The upstream mod may rename its orbital prototypes across versions.
-- Resolve their actual IDs once from their technology unlocks rather than
-- running a technology scan for every passing quality asteroid.
local stellar={outer={},inner={}}
for _,name in ipairs({"sun-orbit","slp-solar-orbit-outer"}) do
  stellar.outer[name]=true
end
for _,name in ipairs({"close-sun-orbit","slp-solar-orbit-inner"}) do
  stellar.inner[name]=true
end
function M.register_stellar_locations(outer,inner)
 if type(outer)=="string" then stellar.outer[outer]=true end
 if type(inner)=="string" then stellar.inner[inner]=true end
end
local stellar_scanned=false
local function scan_native_technologies()
 if stellar_scanned then return end
 local technology=(data and data.raw and data.raw.technology)
   or (prototypes and prototypes.technology)
 if not technology then return end
 stellar_scanned=true
 local source={
   {"planet-discovery-sunorbit","outer"},
   {"slp-solar-system-sun2","inner"}
 }
 for _,entry in ipairs(source) do
   local tech=technology[entry[1]]
   for _,effect in ipairs(tech and tech.effects or {}) do
     if effect.type=="unlock-space-location"
       and type(effect.space_location)=="string" then
       stellar[entry[2]][effect.space_location]=true
     end
   end
 end
end
function M.stellar_location_tier(name)
 if type(name)~="string" then return nil end
 scan_native_technologies()
 if stellar.inner[name] then return "inner" end
 if stellar.outer[name] then return "outer" end
end
function M.stellar_route_tier(route)
 if not route then return nil end
 local from=M.stellar_location_tier(route.from)
 local to=M.stellar_location_tier(route.to)
 if from=="inner" or to=="inner" then return "inner" end
 if from=="outer" or to=="outer" then return "outer" end
end
local inferred={}
-- This data-stage pass handles optional source worlds whose IDs weren't
-- known while designing the fixed campaign. The graph is connected to the
-- *final retained routes*, never to speculative legacy shortcuts.
function M.prepare_routes(routes)
  inferred={}
  scan_native_technologies()
  local edges={}
  for _,r in pairs(routes or {}) do
    -- Data prototypes use string IDs, but runtime LuaSpaceConnectionPrototype
    -- exposes LuaSpaceLocationPrototype objects. Support both identically.
    if r then
      local a=type(r.from)=="string" and r.from
        or (r.from and r.from.name)
      local b=type(r.to)=="string" and r.to
        or (r.to and r.to.name)
      if type(a)=="string" and type(b)=="string"
        and a~=b and not r.hidden then
        edges[#edges+1]={a,b}
      end
    end
  end
  -- A late unknown moon should inherit the stage of its nearest surviving
  -- hub. Only unknowns are inferred, so early planets never drift upward.
  local levels={}
  for name,level in pairs(exceptional) do levels[name]=level end
  for name in pairs(stellar.outer) do levels[name]=9 end
  for name in pairs(stellar.inner) do levels[name]=10 end
  table.sort(edges,function(a,b)
    if a[1]==b[1] then return a[2]<b[2] end
    return a[1]<b[1]
  end)
  -- Synchronous propagation is deterministic even when Factorio changes
  -- prototype iteration order. Unknown late-side branches inherit the
  -- strongest connected hub and never pull down explicit campaign worlds.
  for _=1,12 do
    local next_levels={}
    for name,level in pairs(levels) do next_levels[name]=level end
    local modified=false
    for _,edge in ipairs(edges) do
      local a,b=edge[1],edge[2]
      if levels[a] and not exceptional[b] then
        local stage=math.max(next_levels[b] or 0,levels[a])
        if stage~=(next_levels[b] or 0) then
          next_levels[b]=stage
          modified=true
        end
      end
      if levels[b] and not exceptional[a] then
        local stage=math.max(next_levels[a] or 0,levels[b])
        if stage~=(next_levels[a] or 0) then
          next_levels[a]=stage
          modified=true
        end
      end
    end
    levels=next_levels
    if not modified then break end
  end
  for name,level in pairs(levels) do
    if not exceptional[name] and members.system(name)=="unassigned" then
      inferred[name]=level
    end
  end
  return inferred
end

local distributions={
  {1,0,0,0,0},
  {.77,.20,.03,0,0},
  {.59,.27,.12,.02,0},
  {.43,.30,.19,.07,.01},
  {.30,.27,.23,.15,.05},
  {.19,.22,.26,.22,.11},
  {.10,.15,.22,.29,.24},
  {.04,.08,.15,.27,.46},
  {.01,.02,.06,.17,.74},
  {0,0,0,0,1}
}
M.quality_names={"normal","uncommon","rare","epic","legendary"}
M.distributions=distributions
-- Every difficulty level has one exact, shared starmap color:
-- cool blue -> cyan -> teal -> green -> lime -> gold -> orange -> red.
-- Higher saturation is intentional: route ribbons overlap faint grey
-- native connections and must survive the zoomed-out starmap. Tooltip
-- HEX values correspond precisely to the Factorio RGB tints below.
M.route_colors={
  {r=0.29,g=0.58,b=0.96}, -- 1 blue
  {r=0.17,g=0.68,b=1.00}, -- 2 sky blue
  {r=0.12,g=0.80,b=0.85}, -- 3 teal
  {r=0.17,g=0.88,b=0.55}, -- 4 emerald
  {r=0.33,g=0.91,b=0.34}, -- 5 green
  {r=0.64,g=0.90,b=0.26}, -- 6 lime
  {r=0.96,g=0.84,b=0.23}, -- 7 golden yellow
  {r=1.00,g=0.60,b=0.23}, -- 8 orange
  {r=0.99,g=0.37,b=0.28}, -- 9 vermilion
  {r=0.94,g=0.21,b=0.29} -- 10 crimson
}
M.route_color_hex={
  "#4A94F5","#2BADFF","#1FCCD9","#2BE08C","#54E857",
  "#A3E642","#F5D63B","#FF993B","#FC5E47","#F0364A"
}
function M.color_level(level)
  return math.max(1,math.min(10,math.floor((type(level)=="number" and level or 1)+.5)))
end
function M.route_color(level)
  return M.route_colors[M.color_level(level)]
end
function M.route_color_richtext(level)
  return M.route_color_hex[M.color_level(level)]
end

local function clamp(x,low,high) return math.max(low,math.min(high,x)) end
local function value(n,fallback)
  return type(n)=="number" and n==n and n or fallback
end
function M.location_level(name)
  if type(name)~="string" then return 1 end
  local solar=M.stellar_location_tier(name)
  if solar=="inner" then return 10 end
  if solar=="outer" then return 9 end
  local fixed=exceptional[name] or inferred[name]
  if fixed then return fixed end
  -- Source variants retain difficult Aegis interior levels without being
  -- mislabeled as deep-space routes simply because of their old names.
  local n=name:lower()
  if n:find("warden",1,true) then return 9 end
  if n:find("bellicos",1,true) or n:find("aegis",1,true)
    or n:find("pulsar",1,true) then return 9 end
  if n:find("skewer_",1,true)
    or n:find("black-hole",1,true) then return 10 end
  return base[members.system(name)] or 4
end
function M.is_belt(a,b)
  local names={["asteroid-belt-inner-edge"]="vibrant",
    ["asteroid-belt-outer-edge"]="vibrant",
    ["razi-umbra-belt-inner"]="umbra",
    ["razi-umbra-belt-outer"]="umbra"}
  return names[a]~=nil and names[a]==names[b]
end
function M.route_level(route,progress,setting)
  if type(route)~="table" then return 1 end
  local tier=M.stellar_route_tier(route)
  if tier then
    -- Corona hazards do not stop being deadly near a safe departure
    -- planet. Symmetric progression means travel in either direction is
    -- dangerous. Peak grade matches the actual high-tier asteroid pool.
    local t=clamp(value(progress,.5),0,1)
    local midpoint=4*t*(1-t)
    local initial=tier=="inner" and 9.25 or 8.20
    return clamp(initial+.65*midpoint,1,10)
  end
  local a=M.location_level(route.from)
  local b=M.location_level(route.to)
  local t=clamp(value(progress,.5),0,1)
  -- A gentle mid-journey escalation; the endpoint quality follows actual
  -- travel direction and progress rather than an arbitrary random planet.
  local km=value(route.length,0)
  local mid=km>=25000 and .75 or (km>=15000 and .35 or 0)
  if km>=150000 then mid=1.0 end
  local crossing=M.is_belt(route.from,route.to)
  if crossing then
    mid=math.max(mid,
      (route.from=="razi-umbra-belt-inner"
        or route.from=="razi-umbra-belt-outer") and 1.15 or .95)
  end
  local stage=a+(b-a)*t+mid*4*t*(1-t)
  -- Short home-system links remain approachable by default.
  if a==1 and b==1 then stage=1 end
  if setting=="challenging" and stage>1 then stage=stage+.75 end
  if setting=="relentless" and stage>1 then stage=stage+1.5 end
  return clamp(stage,1,10)
end
function M.route_range(route,setting)
  local lo=math.floor(M.route_level(route,0,setting)+.5)
  local hi=lo
  for _,t in ipairs({.125,.25,.375,.5,.625,.75,.875,1}) do
    local stage=math.floor(M.route_level(route,t,setting)+.5)
    lo=math.min(lo,stage)
    hi=math.max(hi,stage)
  end
  return lo,hi
end
function M.roll(level,random)
  local tier=clamp(value(level,1),1,10)
  local from=math.floor(tier)
  local toward=math.min(from+1,10)
  local blend=tier-from
  local first,second=distributions[from],distributions[toward]
  local dice=clamp(value(random,.5),0,1)
  local cumulative=0
  for i=1,5 do
    cumulative=cumulative+first[i]*(1-blend)+second[i]*blend
    if dice<cumulative or i==5 then return M.quality_names[i] end
  end
  return "normal"
end
return M
