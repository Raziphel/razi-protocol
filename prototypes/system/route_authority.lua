-- Final space-connection ownership, after all planet and compatibility
-- packages have registered their routes. The normal seven-system chart uses
-- only Razi's approved pairs, not every source mod's built-in shortcuts.
-- Critical native sub-networks remain reachable instead of being erased.
local M={}
local reconcile=require("prototypes.system.route_reconcile")
local profiles=require("prototypes.system.asteroid_profiles")
local icons=require("prototypes.system.route_icons")
local member=reconcile.membership
local pair=reconcile.pair_key
local allowed=reconcile.allowed_pairs

-- Side routes assigned by Razi's optional/community integrations. We supply
-- the specified hub even if a source mod added a competing connection first.
-- The special worlds do NOT become prerequisites for required discoveries.
local side_routes={
  {"foliax","sye-nyxaris",24000,"biological_deep"},
  {"obsidiax","vesta",21000,"outer_void"},
  {"carna","crucible-orbit",20500,"outer_void"},
  {"rabbasca","gleba",13000,"biological"},
  {"ferrum","sye-beetlejuice",22500,"outer_industry"},
  {"alchemy-planet","ribbonia",18000,"chemistry"},
  {"arcanyx","tenebris",25000,"outer_void"},
  {"bm-balack","aquilo",30000,"cryogenic_deep"},
  {"velora","gleba",14000,"biological"},
  -- Preserve remaining source-owned side-world connections.
  -- Athos now belongs to Vespera. Its single dry-world spur leaves Muria,
  -- with no Vulcanus/Nauvis shortcut or duplicate connection.
  {"athos","muria",24000,"cryogenic"},
  -- Preserve Eneas's native Nauvis moon, Unit-05 and launch gantry.
  {"eneas","nauvis",9000,"starter"},
  -- Shchierbin is deliberately OUTSIDE Vibrant's asteroid band.
  {"shchierbin","paracelsin",18000,"chemistry_deep"},
  -- Two independent first-frontier approaches to the same native Aegis gate.
  -- The source Bellicos interior remains native; there is no Deep Space bypass.
  {"sye-solaris","calidus-bellicos-stargate-calidus",112000,"aegis_approach"},
  {"sye-nyxaris","calidus-bellicos-stargate-calidus",118000,"aegis_approach"},
  -- Both optional Umbra worlds have one interior connection. A
  -- Carna-to-Slip-Stream line would bypass the real belt passage.
}
-- Source-owned Vesta satellite. Only installed Abacayba gets a route.
local abacayba=require("prototypes.system.abacayba_integration")
local moon_id=abacayba.planet_name()
if moon_id and (data.raw.planet or {}).vesta then
  member[moon_id]="umbra"
  side_routes[#side_routes+1]={moon_id,"vesta",10000,"outer_void"}
end
-- Source-authored orbital links, not speculative Razi shortcuts.
local native_pairs={
  {"nauvis","muluna"},
  {"asteroid-belt-inner-edge","asteroid-belt-outer-edge"},
  {"crucible-orbit","crucible"},
  {"fulgora","cerys"},
  {"gleba","rabbasca"},
  {"gleba","terrapalus"},
  -- Keep all source-owned Aegis internal connections untouched.
  {"gleba","velora"}
}
local function exists(name)
  return (data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
end
local function ordered_names(routes)
  local names={}
  for name in pairs(routes) do names[#names+1]=name end
  table.sort(names)
  return names
end
local function is_stellar(id)
  for _,tech in ipairs({"planet-discovery-sunorbit",
    "slp-solar-system-sun2"}) do
    for _,effect in ipairs(
      ((data.raw.technology or {})[tech] or {}).effects or {}) do
      if effect.type=="unlock-space-location" and effect.space_location==id then
        return true
      end
    end
  end
  return false
end
-- The Dyson sun-orbit stations must be reached through Calidus, not by a
-- source-mod shortcut into Vulcanus. Resolve dynamic source IDs through the
-- actual discovery effects, with the two known IDs as safe fallbacks.
local function unwanted_solaris_sun_route(a,b)
  local other
  if a=="vulcanus" then other=b
  elseif b=="vulcanus" then other=a
  else return false end
  return other=="close-sun-orbit" or other=="sun-orbit"
    or is_stellar(other)
end
local function native_parent_link(a,b)
  local child=exists(a)
  local parent=child and child.orbit and child.orbit.parent
  if parent and parent.name==b and parent.type=="planet" then return true end
  child=exists(b)
  parent=child and child.orbit and child.orbit.parent
  return parent and parent.name==a and parent.type=="planet" or false
end
local function approved_pairs()
  local result={}
  for key in pairs(allowed) do result[key]=true end
  for _,row in ipairs(side_routes) do
    if exists(row[1]) and exists(row[2]) then
      result[pair(row[1],row[2])]=true
    end
  end
  for _,row in ipairs(native_pairs) do
    if exists(row[1]) and exists(row[2]) then
      result[pair(row[1],row[2])]=true
    end
  end
  return result
end
M.approved_pairs=approved_pairs

local function is_critical_native(a,b)
  if native_parent_link(a,b) then return true end
  if is_stellar(a) and (is_stellar(b)
      or member[b]=="calidus") then return true end
  if is_stellar(b) and member[a]=="calidus" then return true end
  return false
end
-- Where a source location has *no Razi-owned route*, preserve one original
-- connection to the curated network. This is intentional compatibility for
-- third-party stargates, boss dimensions and world additions unknown to the
-- current pack. The remaining source-only subsystem stays untouched.
local function preference(route,outsider)
  local other=route.from==outsider and route.to or route.from
  local loc=exists(outsider)
  local p=loc and loc.orbit and loc.orbit.parent
  local parent=(p and p.name==other) and 0 or 1
  local km=type(route.length)=="number" and route.length or 1000000
  local group=member[other]
  local near=(group=="calidus" or group=="deep-space") and 2 or 0
  return parent,near,km
end
local function better(name,route,incumbent,outsider)
  if not incumbent then return true end
  local a,b,c=preference(route,outsider)
  local x,y,z=preference(incumbent.route,outsider)
  if a~=x then return a<x end
  if b~=y then return b<y end
  if c~=z then return c<z end
  return name<incumbent.name
end
local function preferred_name(a,b)
  -- Source names usually survive: platform schedules do not needlessly
  -- change just because the rest of the native map was simplified.
  local nativeA=a:sub(1,5)~="razi-"
  local nativeB=b:sub(1,5)~="razi-"
  if nativeA~=nativeB then return nativeA end
  return a<b
end
local function dedupe(routes,check)
  local seen,removed={},0
  for _,name in ipairs(ordered_names(routes)) do
    local route=routes[name]
    if route and type(route.from)=="string"
      and type(route.to)=="string" then
      local key=pair(route.from,route.to)
      if check[key] then
        local keep=seen[key]
        if not keep then seen[key]=name
        else
          local winner=preferred_name(name,keep) and name or keep
          local loser=winner==name and keep or name
          local saved=routes[winner]
          local discarded=routes[loser]
          if saved and discarded then
            profiles.preserve_custom(saved,discarded)
            routes[loser]=nil
            removed=removed+1
          end
          seen[key]=winner
        end
      end
    end
  end
  return removed
end

function M.data_final_fixes()
  local routes=data.raw["space-connection"]
  if not routes then return 0 end
  -- Never retain the stray Vulcanus-to-sun-orbit chord, including when the
  -- broader curated-network cleanup is disabled for compatibility testing.
  local forbidden=0
  for name,route in pairs(routes) do
    if unwanted_solaris_sun_route(route.from,route.to) then
      routes[name]=nil
      forbidden=forbidden+1
    end
  end
  local setting=settings and settings.startup
    and settings.startup["razi-curated-space-routes"]
  if setting and setting.value==false then return forbidden end
  local approved=approved_pairs()
  -- Sources can register a planet after the earlier route reconciliation.
  -- Ensure every present, approved endpoint still gets its planned connection.
  -- The only intentional exception is a redundant Muluna hub chord once the
  -- real Nauvis/Muluna moon connection already exists.
  local function has_pair(a,b)
    local wanted=pair(a,b)
    for _,route in pairs(routes) do
      if route.from and route.to and pair(route.from,route.to)==wanted then
        return true
      end
    end
    return false
  end
  local function ensure_route(from,to,km,hazard)
    if not exists(from) or not exists(to) or has_pair(from,to) then return end
    if pair(from,to)==pair("muluna","sye-calidus")
      and has_pair("nauvis","muluna") then return end
    local name="razi-curated-"..from.."-"..to
    if routes[name] then return end
    local a,b=member[from],member[to]
    -- Without two known same-system owners, a default arc would loop
    -- around Calidus rather than connect these actual relocated endpoints.
    local line=not (a and b) or a~=b or a=="calidus"
      or a=="solaris" or a=="nyxaris" or a=="vibrant" or a=="vespera"
      or a=="umbra" or a=="beetlejuice"
    local selected=reconcile.selected_curve and reconcile.selected_curve(from,to)
    local shape=selected and "arc" or (line and "line" or "arc")
    local origin=not line and reconcile.regional_origin
      and reconcile.regional_origin(from,to,shape) or nil
    data:extend({icons.assign({
      type="space-connection",name=name,from=from,to=to,
      length=km,shape=shape,origin=origin,
      asteroid_spawn_definitions=profiles.create(hazard)
    },hazard)})
  end
  for _,spec in ipairs(reconcile.specifications or {}) do
    ensure_route(spec[1],spec[2],spec[3],spec[4])
  end
  for _,spec in ipairs(side_routes) do
    ensure_route(spec[1],spec[2],spec[3],spec[4])
  end

  -- An author's old route to an optional planet may carry exclusive custom
  -- asteroid resources. If that planet is assigned a different Razi hub,
  -- migrate *only* custom definitions to its approved route before pruning.
  -- Never copy another system's vanilla asteroid size/density curve.
  for _,spec in ipairs(side_routes) do
    local world,hub=spec[1],spec[2]
    -- The Solaris/Nyxaris hub approaches are *not* optional-world spurs.
    -- Never import unrelated first-frontier custom asteroids onto Aegis.
    if world~="sye-solaris" and world~="sye-nyxaris"
      and exists(world) and exists(hub) then
      local target
      for _,route in pairs(routes) do
        if route.from and route.to
          and pair(route.from,route.to)==pair(world,hub) then
          target=route
          break
        end
      end
      if target then
        for _,route in pairs(routes) do
          if route~=target then
            local other
            if route.from==world then other=route.to end
            if route.to==world then other=route.from end
            if other and other~=hub and member[other] then
              profiles.preserve_custom(target,route)
            end
          end
        end
      end
    end
  end

  -- Only *ordinary known-world connections* are subject to total cleanup.
  -- Unknown-to-unknown custom sub-networks remain source owned. For mixed
  -- pairs, pick at most one lifeline to each new external destination.
  local lifelines={}
  local curated_external={}
  for _,spec in ipairs(side_routes) do
    if not member[spec[1]] and exists(spec[1]) and exists(spec[2]) then
      curated_external[spec[1]]=true
    end
  end
  for _,name in ipairs(ordered_names(routes)) do
    local route=routes[name]
    if route and type(route.from)=="string"
      and type(route.to)=="string" then
      local a,b=route.from,route.to
      if (member[a] and not member[b]) or (member[b] and not member[a]) then
        local outsider=member[a] and b or a
        -- A world with a defined Razi side connection needs no additional
        -- speculative source lifeline to another managed system.
        if not curated_external[outsider]
          and not approved[pair(a,b)] and not is_critical_native(a,b) then
          local current=lifelines[outsider]
          if better(name,route,current,outsider) then
            lifelines[outsider]={name=name,route=route}
          end
        end
      end
    end
  end

  local removed,exceptions=0,0
  for _,name in ipairs(ordered_names(routes)) do
    local route=routes[name]
    if route and type(route.from)=="string"
      and type(route.to)=="string" then
      local a,b=route.from,route.to
      local key=pair(a,b)
      if not approved[key] then
        if is_critical_native(a,b) then
          approved[key]=true
          exceptions=exceptions+1
        elseif member[a] and member[b] then
          routes[name]=nil
          removed=removed+1
        elseif member[a] or member[b] then
          local outsider=member[a] and b or a
          if not lifelines[outsider] or lifelines[outsider].name~=name then
            routes[name]=nil
            removed=removed+1
          else
            approved[key]=true
            exceptions=exceptions+1
          end
        end
      end
    end
  end
  removed=removed+dedupe(routes,approved)
  -- A single native 5,000 km connection traverses the rock band.
  -- The outside approach has a clear straight corridor too, so never
  -- reintroduce an arc that swerves into the asteroid artwork.
  for _,route in pairs(routes) do
    if route.from and route.to
      and (pair(route.from,route.to)==
        pair("asteroid-belt-inner-edge","asteroid-belt-outer-edge")
        or pair(route.from,route.to)==
        pair("sye-vibrant","asteroid-belt-outer-edge")) then
      route.shape="line"
      route.origin=nil
    end
  end
  -- Normalize retained native routes, not just freshly added ones.
  -- Vespera's two optional spurs also need straight lines; neither
  -- should arc around the sun or cut through the asteroid survey.
  for _,route in pairs(routes) do
    local system=member[route.from]
    local curated_side=(moon_id and pair(route.from,route.to)==pair(moon_id,"vesta"))
      or pair(route.from,route.to)==pair("athos","muria")
      or pair(route.from,route.to)==pair("obsidiax","vesta")
      or pair(route.from,route.to)==pair("ferrum","sye-beetlejuice")
      or pair(route.from,route.to)==pair("bm-balack","aquilo")
    if ((system=="nyxaris" or system=="vibrant" or system=="vespera"
          or system=="umbra" or system=="beetlejuice")
        and member[route.to]==system
        and not native_parent_link(route.from,route.to))
      or curated_side then
      if reconcile.selected_curve and
        reconcile.selected_curve(route.from,route.to) then
        route.shape="arc"
        route.origin=reconcile.regional_origin and
          reconcile.regional_origin(route.from,route.to,"arc") or nil
      else
        route.shape="line"
        route.origin=nil
      end
    end
  end
  if type(log)=="function" then
    local kept=0
    for _ in pairs(routes) do kept=kept+1 end
    log(string.format(
      "[Razi Protocol/routes] Authoritative network: %d ordinary shortcuts removed; %d protected/unknown-world bridges; %d total retained (Razi authored + native exceptions)",
      removed,exceptions,kept))
  end
  return removed+forbidden
end
return M
