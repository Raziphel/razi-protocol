-- Razi quality-asteroid threat ladder. Pure Lua: available to data and control.
-- Rank is a ten-stage *hazard* scale, NOT ten new Factorio quality prototypes.
-- Level 10 is legendary for every eligible hostile asteroid.
local M={}
local members=require("scripts.galactic_catalog")
local base={calidus=1,solaris=3,nyxaris=3,vibrant=5,vespera=5,
  beetlejuice=7,umbra=8,["deep-space"]=10,unassigned=2}
local exceptional={
  ["nauvis"]=1,["muluna"]=1,["shattered-planet"]=10,
  ["solar-system-edge"]=10,["nexus"]=10,["oort-cloud"]=10,
  ["black-hole"]=10,["black-hole-approach"]=10,
  ["asteroid-belt-inner-edge"]=5,["asteroid-belt-outer-edge"]=6,
  ["razi-umbra-belt-inner"]=8,["razi-umbra-belt-outer"]=9
}
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
local function clamp(x,low,high) return math.max(low,math.min(high,x)) end
local function value(n,fallback)
  return type(n)=="number" and n==n and n or fallback
end
function M.location_level(name)
  if type(name)~="string" then return 1 end
  return exceptional[name] or base[members.system(name)] or 2
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
  for _,t in ipairs({.25,.5,.75,1}) do
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
