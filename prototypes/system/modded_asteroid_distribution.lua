-- Distribute verified source-mod asteroid families onto Razi's *final*
-- approved travel network. No new prototypes, recipes, mining mechanics,
-- quality tiers, or transport edges are created here.
--
-- Imersite Asteroids: faint Fulgora, Vibrant belt, Aquilo-bound extraction.
-- Secretas: auric debris and progressively larger hostile golden asteroids
-- close to Secretas/Frozeta, not early Calidus or random distant planets.
--
-- Source-owned spawn curves always win, and modded entries are untouched.
local M={}
local levels=require("scripts.razi_asteroid_difficulty")
local vanilla={metallic=true,carbonic=true,oxide=true,promethium=true}
local done=setmetatable({},{__mode="k"})
local installed={}
local function has_chunk(name)
  return (data.raw["asteroid-chunk"] or {})[name]~=nil
end
local function has_enemy(name)
  return (data.raw.asteroid or {})[name]~=nil
end
local function choose_chunk(names)
  for _,name in ipairs(names) do
    if has_chunk(name) then return name end
  end
end
local function has_definition(definitions,name)
  for _,def in ipairs(definitions or {}) do
    if def.asteroid==name then return true end
  end
  return false
end
local function chunk_curve(rate)
  return {
    {distance=.08,probability=rate*.18,speed=.035},
    {distance=.30,probability=rate*.65,speed=.035},
    {distance=.50,probability=rate,speed=.035},
    {distance=.70,probability=rate*.65,speed=.035},
    {distance=.92,probability=rate*.18,speed=.035}
  }
end
-- A belt has a symmetric center field. Secretas is different: the
-- original author places its golden/auric rocks primarily near the gas
-- giant. Use the route's actual from/to direction to retain that geography.
local function auric_curve(rate,route,kind)
  local toward=route.to=="secretas"
  local near_moon=(route.from=="frozeta" or route.to=="frozeta")
  local positions={.05,.20,.38,.57,.76,.94}
  local weights={1.00,.94,.72,.37,.14,.06}
  local result={}
  for index,position in ipairs(positions) do
    local weight=weights[toward and (7-index) or index] or 1.0
    if near_moon then weight=math.max(weight,.52) end
    result[#result+1]={
      distance=position,probability=rate*weight,
      speed=kind=="asteroid-chunk" and .035 or .018
    }
  end
  return result
end
M.auric_curve=auric_curve
local function route_pair(route,a,b)
  return route.from==a and route.to==b
    or route.from==b and route.to==a
end
local function has_endpoint(route,name)
  return route.from==name or route.to==name
end
-- Modded resource asteroid geography follows the actual SOURCE intent.
-- No giant low-level imersite veins on the Nauvis starter routes.
local function imersite_rate(route)
  if route_pair(route,"asteroid-belt-inner-edge",
      "asteroid-belt-outer-edge") then return .013 end
  if has_endpoint(route,"asteroid-belt-inner-edge")
    or has_endpoint(route,"asteroid-belt-outer-edge") then return .0055 end
  -- Direct Fulgora->Aquilo links must not be downgraded to "trace"
  -- simply because they touch Fulgora; this is pre-Aquilo progression.
  if has_endpoint(route,"aquilo") then return .008 end
  if has_endpoint(route,"fulgora") then return .0010 end
  if has_endpoint(route,"razi-umbra-belt-inner")
    or has_endpoint(route,"razi-umbra-belt-outer") then return .0025 end
  if has_endpoint(route,"paracelsin") or has_endpoint(route,"ribbonia")
    or has_endpoint(route,"sye-vibrant") then return .0030 end
  return nil
end
-- Rare Auric field near Secretas; only the uppermost route to Solar
-- System Edge can add huge auric asteroids on top of the source roster.
local function auric_rates(route)
  if not has_endpoint(route,"secretas") then return nil end
  if has_endpoint(route,"solar-system-edge") then
    return {chunk=.0035,small=.0018,medium=.0028,
      big=.0022,huge=.00045}
  end
  if has_endpoint(route,"frozeta") then
    return {chunk=.008,small=.0018,medium=.0030,big=.0013}
  end
  if has_endpoint(route,"cubium")
    or has_endpoint(route,"linox-planet_linox") then
    return {chunk=.005,small=.0015,medium=.0021,big=.0008}
  end
  -- Protected additional source-owned links inherit only a very small
  -- aura, without creating a new legendary endgame bypass.
  local stage=math.max(levels.location_level(route.from),
    levels.location_level(route.to))
  if stage>=7 then return {chunk=.002,small=.0007,medium=.0009} end
end
M.imersite_rate=imersite_rate
M.auric_rates=auric_rates
local function add_route_entry(definitions,name,kind,rate,route,source)
  if not name or rate<=0 or has_definition(definitions,name) then
    return false
  end
  definitions[#definitions+1]={
    type=kind,asteroid=name,
    spawn_points=source=="auric"
      and auric_curve(rate,route,kind) or chunk_curve(rate)
  }
  return true
end
local function integrate_route(route,imersite)
  if not route or route.hidden or not route.from or not route.to then
    return 0
  end
  if done[route] then return 0 end
  done[route]=true
  local source=route.asteroid_spawn_definitions or {}
  local extra={}
  local count=0
  -- Check BOTH original and queued entries; never duplicate definitions.
  local function add(name,kind,rate,family)
    if has_definition(source,name) then return end
    if add_route_entry(extra,name,kind,rate,route,family) then
      count=count+1
    end
  end
  if imersite then
    local rate=imersite_rate(route)
    if rate then add(imersite,"asteroid-chunk",rate) end
  end
  if installed.auric then
    local rates=auric_rates(route)
    if rates then
      add("auric-asteroid-chunk","asteroid-chunk",rates.chunk,"auric")
      local stage=math.max(levels.location_level(route.from),
        levels.location_level(route.to))
      for _,size in ipairs({"small","medium","big","huge"}) do
        local rate=rates[size]
        if rate and (size=="small" or
            (size=="medium" and stage>=7) or
            (size=="big" and stage>=8) or
            (size=="huge" and stage>=10)) then
          local name=size.."-auric-asteroid"
          if has_enemy(name) then add(name,"entity",rate,"auric") end
        end
      end
    end
  end
  if count>0 then
    -- Never modify a source-owned list, even if multiple routes share it.
    local result={}
    for key,def in pairs(source) do result[key]=def end
    for _,entry in ipairs(extra) do result[#result+1]=entry end
    route.asteroid_spawn_definitions=result
  end
  return count
end
-- Stationary platform collection uses probability (NOT route spawn_points).
local function add_orbit_chunk(name,chunk,rate)
  local loc=(data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
  if not loc or not chunk then return 0 end
  local old=loc.asteroid_spawn_definitions or {}
  if has_definition(old,chunk) then return 0 end
  local result={}
  for key,def in pairs(old) do result[key]=def end
  result[#result+1]={type="asteroid-chunk",asteroid=chunk,
    probability=rate,speed=.035,angle_when_stopped=.5}
  loc.asteroid_spawn_definitions=result
  return 1
end
local function classify_unknowns()
  local result={}
  for _,category in ipairs({"asteroid","asteroid-chunk"}) do
    for name,proto in pairs(data.raw[category] or {}) do
      local family=name:match("^(.+)%-asteroid%-chunk$")
        or name:match("^small%-([%w_]+)%-asteroid$")
        or name:match("^medium%-([%w_]+)%-asteroid$")
        or name:match("^big%-([%w_]+)%-asteroid$")
        or name:match("^huge%-([%w_]+)%-asteroid$")
      if family and not vanilla[family]
        and not name:find("^razi%-quality%-asteroid%-") and
        not proto.parameter then
        result[family]=result[family] or {chunks={},hostile={}}
        local kind=category=="asteroid-chunk" and "chunks" or "hostile"
        result[family][kind][#result[family][kind]+1]=name
      end
    end
  end
  return result
end
M.classify_unknowns=classify_unknowns
function M.data_final_fixes()
  local imersite=choose_chunk({
    "imersite-asteroid-chunk","imersium-asteroid-chunk"
  })
  installed.auric=has_chunk("auric-asteroid-chunk")
  -- Even in installations lacking these two mods, audit any other
  -- custom prototypes for future opt-in compatibility work.
  -- Read finalized route geometry and membership, not the original
  -- source-mod starmap (Razi has deliberately removed its shortcuts).
  local number,changed=0,0
  local route_changes={}
  local routes=data.raw["space-connection"] or {}
  local names={}
  for name in pairs(routes) do names[#names+1]=name end
  table.sort(names)
  for _,name in ipairs(names) do
    local count=integrate_route(routes[name],imersite)
    if count>0 then
      number=number+1
      changed=changed+count
      route_changes[#route_changes+1]=name..":"..count
    end
  end
  if imersite then
    changed=changed+add_orbit_chunk("fulgora",imersite,.0010)
    changed=changed+add_orbit_chunk("asteroid-belt-inner-edge",
      imersite,.0025)
    changed=changed+add_orbit_chunk("asteroid-belt-outer-edge",
      imersite,.004)
  end
  -- Source Secretas/Frozeta already author their own orbit distributions,
  -- so Razi does not inject more stationary auric rocks there.
  local detected=classify_unknowns()
  if type(log)=="function" then
    local families={}
    for family in pairs(detected) do families[#families+1]=family end
    table.sort(families)
    log(("[Razi Protocol/custom-asteroids] Discovered families: %s. "..
      "Added %d missing entries to %d preserved routes; "..
      "no external asteroid recipes altered."):format(
        table.concat(families,", "),changed,number))
    -- Diagnostic detail is restricted to modified routes, in stable
    -- lexical order; useful when players report a barren asteroid belt.
    log("[Razi Protocol/custom-asteroids] Modified routes: "..
      (#route_changes>0 and table.concat(route_changes,", ") or "none"))
  end
  return changed
end
return M
