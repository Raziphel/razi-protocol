-- The route passes of the Bellicos expedition: retiring the far-side gate, merging parallel
-- corridors and building the one readable spine. bellicos.lua adds them to its public table.
local places = require("prototypes.world.systems.bellicos_places")
local entry_gate = places.entry_gate
local retired_gate = places.retired_gate
local root_parent = places.root_parent
local endpoint_type = places.endpoint_type
local near_orbit = places.near_orbit
local parent_polar = places.parent_polar
local find_wardens = places.find_wardens
local native_point = places.native_point

local passes = {}

-- Delete the obsolete far-side marker only AFTER source mods have read it.
-- Research itself survives for native progression; only effects that unlock
-- a nonexistent location are removed. Repeat safely after late research passes.
function passes.retire_far_gate()
  if not (mods and mods["bellicos-and-aegis"]) then return 0 end
  local removed=0
  local routes=data.raw["space-connection"] or {}
  for name,route in pairs(routes) do
    if route.from==retired_gate or route.to==retired_gate then
      routes[name]=nil
      removed=removed+1
    end
  end
  for _,technology in pairs(data.raw.technology or {}) do
    if type(technology.effects)=="table" then
      for i=#technology.effects,1,-1 do
        local effect=technology.effects[i]
        if effect.type=="unlock-space-location"
          and effect.space_location==retired_gate then
          table.remove(technology.effects,i)
        end
      end
    end
  end
  -- Upstream versions may parent another native waypoint to the old gate.
  -- Keep that waypoint at its already-rendered absolute position, then
  -- reparent its metadata to the surviving Aegis inner system.
  local parent=near_orbit() or root_parent
  for _,kind in ipairs({"planet","space-location"}) do
    for name,body in pairs(data.raw[kind] or {}) do
      local orbit=body.orbit
      if name~=retired_gate and type(orbit)=="table"
        and type(orbit.parent)=="table"
        and orbit.parent.name==retired_gate then
        local px,py=native_point(name)
        local cx,cy=native_point(parent)
        if type(px)=="number" and type(py)=="number"
          and type(cx)=="number" and type(cy)=="number" then
          orbit.distance,orbit.orientation=
            parent_polar(px,py,{x=cx,y=cy})
        end
        orbit.parent={type=endpoint_type(parent) or "space-location",name=parent}
        body.draw_orbit=false
      end
    end
    local bucket=data.raw[kind]
    if bucket and bucket[retired_gate] then
      bucket[retired_gate]=nil
      removed=removed+1
    end
  end
  local ui=(data.raw["utility-sprites"] or {}).default
  local layers=ui and ui.starmap_star and ui.starmap_star.layers
  if type(layers)=="table" then
    for i=#layers,1,-1 do
      if (layers[i] --[[@as table]]).planetslib_orbit_name==retired_gate then
        table.remove(layers,i)
      end
    end
  end
  return removed
end

-- Normalise source-version aliases before comparing connections. Aegis can
-- expose multiple prototype IDs for the same on-screen waypoint, so comparing
-- only the literal from/to strings leaves two nearly parallel lines on the map.
local function aegis_node_identity(name, near, wardens)
  if type(name)~="string" or not endpoint_type(name) then return nil end
  if name==entry_gate then return "gate" end
  if name==retired_gate then return "retired" end
  local compact=name:lower():gsub("[^%w]","")
  if compact=="aegisinneredge" then return "inner" end
  if compact=="aegisouteredge" then return "outer" end
  if name==near or compact=="nearbellicosorbit"
    or compact=="bellicosnearorbit" or compact=="bellicosorbit" then
    return "near"
  end
  for _,warden in ipairs(wardens) do
    if name==warden then return "warden:"..warden end
  end

  -- Coordinate aliases are accepted ONLY for Aegis-named waypoints. Never
  -- collapse unrelated planets just because the layout places them nearby.
  if not (compact:find("aegis",1,true)
    or compact:find("bellicos",1,true)
    or compact:find("warden",1,true)) then return nil end
  local x,y=native_point(name)
  if type(x)~="number" or type(y)~="number" then return nil end
  local targets={
    {"inner","aegis-inner-edge"},
    {"outer","aegis-outer-edge"},
    {"near",near},
    {"gate",entry_gate}
  }
  for _,warden in ipairs(wardens) do
    targets[#targets+1]={"warden:"..warden,warden}
  end
  for _,target in ipairs(targets) do
    if target[2] then
      local tx,ty=native_point(target[2])
      if type(tx)=="number" and type(ty)=="number"
        and (x-tx)^2+(y-ty)^2<1 then
        return target[1]
      end
    end
  end
end

local function same_canonical_endpoints(route, identity, near)
  local expected={
    gate=entry_gate,
    inner="aegis-inner-edge",
    outer="aegis-outer-edge",
    near=near
  }
  local function exact(name,key)
    local id=expected[key]
    if not id and key:sub(1,7)=="warden:" then
      id=key:sub(8)
    end
    return id and name==id
  end
  return (exact(route.from,identity[1]) and exact(route.to,identity[2]))
      or (exact(route.from,identity[2]) and exact(route.to,identity[1]))
end

-- Late compatibility passes may register a second route under a different
-- ID after the main Aegis spine was curated. Keep one connection per unordered
-- pair, preferring native names, and merge only exclusive custom asteroid
-- materials before dropping the duplicate. Does not create or reroute travel.
function passes.dedupe_internal_routes()
  if not (mods and mods["bellicos-and-aegis"]) then return 0 end
  local routes=data.raw["space-connection"] or {}
  local near=near_orbit()
  local wardens=find_wardens()
  local groups={}
  for name,route in pairs(routes) do
    if type(route)=="table" then
      local a=aegis_node_identity(route.from,near,wardens)
      local b=aegis_node_identity(route.to,near,wardens)
      if a and b and a~=b then
        local identity={a,b}
        if a>b then identity={b,a} end
        local key=identity[1].."|"..identity[2]
        local group=groups[key] or {}
        group[#group+1]={name=name,route=route,
          canonical=same_canonical_endpoints(route,identity,near)}
        groups[key]=group
      end
    end
  end

  local preserved=require("prototypes.world.asteroids.asteroid_profiles")
  local removed=0
  for _,group in pairs(groups) do
    table.sort(group,function(a,b)
      -- Exact, playable source waypoints win over coordinate aliases;
      -- retain source IDs before Razi-generated alternatives for saves.
      if a.canonical~=b.canonical then return a.canonical end
      local an=a.name:sub(1,5)=="razi-"
      local bn=b.name:sub(1,5)=="razi-"
      if an~=bn then return not an end
      return a.name<b.name
    end)
    local keeper=group[1]
    for i=2,#group do
      local duplicate=group[i]
      preserved.preserve_custom(keeper.route,duplicate.route)
      routes[duplicate.name]=nil
      removed=removed+1
    end
  end

  -- Report the exact corridor from the screenshot at load time, including
  -- the final prototype ID. A doubled route now becomes a detectable warning
  -- rather than silently surviving several cleanup passes.
  local near_pair=groups["inner|near"]
  if type(log)=="function" then
    if removed>0 then
      log(("[Razi Protocol/Aegis] Removed %d parallel/aliased corridors"):format(removed))
    end
    if near_pair then
      log(("[Razi Protocol/Aegis] Near orbit -> Inner edge: %d original route(s), keeping %s"):format(
        #near_pair,near_pair[1].name))
    else
      log("[Razi Protocol/Aegis] WARNING: no Near orbit -> Inner edge corridor found")
    end
  end
  return removed
end

-- Run after final route ownership and asteroid-family integration. Keep the
-- author's native species/curves; harden vanilla asteroid mid-route encounters.
-- Protect one readable route spine. The former fallback algorithm appended
-- more lines atop the source's multiple direct chords and bypassed the ring.
-- Preserve native IDs and custom asteroid drops on the surviving connections.
function passes.fortify_routes()
  if not (mods and mods["bellicos-and-aegis"]) then return 0 end
  local routes=data.raw["space-connection"] or {}
  local asteroid=require("prototypes.world.asteroids.asteroid_profiles")
  local icons=require("prototypes.world.routes.route_icons")
  local wardens=find_wardens()
  table.sort(wardens,function(a,b)
    if a=="aegis-warden" then return true end
    if b=="aegis-warden" then return false end
    return a<b
  end)
  local near=near_orbit()
  local points={
    [entry_gate]=true,[retired_gate]=true,
    ["aegis-inner-edge"]=true,["aegis-outer-edge"]=true,
    ["near-bellicos-orbit"]=true,["bellicos-near-orbit"]=true,
    ["near_bellicos_orbit"]=true
  }
  for _,name in ipairs(wardens) do points[name]=true end
  local function key(a,b)
    if a>b then a,b=b,a end
    return a.."|"..b
  end
  ---@type table<string,{a:string,b:string,km:number,profile:string}>
  local specs={}
  local order={}
  local function connect(a,b,km,profile)
    if not (endpoint_type(a) and endpoint_type(b)) then return end
    local k=key(a,b)
    if not specs[k] then
      specs[k]={a=a,b=b,km=km,profile=profile}
      order[#order+1]=k
    end
  end
  -- The incoming Aegis gate first approaches the OUTER rim, crosses inward,
  -- then follows the Warden and Bellicos stargate. No long diagonal jumps.
  connect(entry_gate,"aegis-outer-edge",56000,"aegis_approach")
  connect("aegis-outer-edge","aegis-inner-edge",45000,"aegis_depths")
  if near then connect(near,"aegis-inner-edge",12000,"aegis_depths") end
  -- Point Warden is the meaningful final destination. When the source
  -- renames the Warden, use its real prototype instead of a dummy terminus.
  if #wardens>0 then
    connect("aegis-inner-edge",wardens[1],38000,"aegis_depths")
    -- Variant/extra Wardens remain side discoveries, not shortcut chords.
    for i=2,#wardens do
      connect("aegis-inner-edge",wardens[i],33000,"aegis_depths")
    end
  end
  -- Choose a native route first for each pair so saved platform schedules
  -- remain valid whenever possible. Repeated runs must be idempotent.
  local names={}
  for name in pairs(routes) do names[#names+1]=name end
  table.sort(names,function(a,b)
    local an,bn=a:sub(1,5)=="razi-",b:sub(1,5)=="razi-"
    if an~=bn then return not an end
    return a<b
  end)
  local kept,discarded={},{}
  for _,name in ipairs(names) do
    local route=routes[name]
    if route and type(route.from)=="string" and type(route.to)=="string" then
      local k=key(route.from,route.to)
      -- Remove even source links from the old stargate into an unknown
      -- system; those would become dangling when its prototype is deleted.
      if route.from==retired_gate or route.to==retired_gate then
        discarded[#discarded+1]={name=name,route=route}
      elseif points[route.from] and points[route.to] then
        if specs[k] and not kept[k] then
          kept[k]=route
        else
          discarded[#discarded+1]={name=name,route=route}
        end
      end
    end
  end
  local added=0
  for _,k in ipairs(order) do
    local spec=specs[k]
    local route=kept[k]
    local fresh=false
    if not route then
      local name="razi-aegis-"..spec.a.."-"..spec.b
      if not routes[name] then
        fresh=true
        route=icons.assign({
          type="space-connection",name=name,from=spec.a,to=spec.b,
          length=spec.km,shape="line",
          asteroid_spawn_definitions=asteroid.create(spec.profile)
        },spec.profile)
        data:extend({route})
        added=added+1
      end
    end
    if route then
      kept[k]=route
      route.length=math.max(route.length or 0,spec.km)
      route.shape="line"
      route.origin=nil
      -- Native exotic spawns survive; only ordinary hostile asteroids are
      -- raised to a genuinely dangerous encounter level.
      -- A route created above already carries the profile; applying it
      -- again would square its density and size weights.
      if not fresh then asteroid.apply(route,spec.profile) end
      asteroid.apply_field(route,spec.profile=="aegis_approach" and 1.5 or 1.6)
    end
  end
  -- Transfer only custom/source asteroid species from removed chords into
  -- the closest surviving part of that native expedition.
  for _,old in ipairs(discarded) do
    local candidate
    for _,k in ipairs(order) do
      local spec=specs[k]
      if spec.a==old.route.from or spec.b==old.route.from
        or spec.a==old.route.to or spec.b==old.route.to then
        candidate=kept[k]
        if candidate then break end
      end
    end
    -- Even if a source release connects its obsolete gateway to a
    -- location we do not recognise, preserve its exclusive asteroid drops
    -- on the dangerous surviving inner expedition instead of discarding them.
    if not candidate and (old.route.from==retired_gate
      or old.route.to==retired_gate) then
      if #wardens>0 then
        candidate=kept[key("aegis-inner-edge",wardens[1])]
      end
      candidate=candidate
        or kept[key("aegis-outer-edge","aegis-inner-edge")]
        or kept[key(entry_gate,"aegis-outer-edge")]
    end
    if candidate then asteroid.preserve_custom(candidate,old.route) end
    routes[old.name]=nil
  end
  local retired=passes.retire_far_gate()
  if type(log)=="function" then
    log(("[Razi Protocol/Aegis] Expedition spine: %d new links, %d obsolete chords, %d retired gateway prototypes/routes"):format(
      added,#discarded,retired))
  end
  return added,#discarded
end


return passes
