local bellicos = {}

local entry_gate = "calidus-bellicos-stargate-calidus"
-- Native source prototype was an unreachable, obsolete return gateway.
-- Retire only this far-side destination; keep the real Aegis entry gate.
local retired_gate = "calidus-bellicos-stargate-bellicos"
local old_calidus_entry_route = "sye-calidus-bellicos-stargate"
-- This is a shared frontier BELOW the two starter stars. These native IDs
-- must remain stable even though their upstream names say "calidus".
local root_parent = "sye-calidus"
-- Compact southern system. The entry and every inhabited waypoint sit on
-- the EAST side of the pulsar beam, leaving the native star art untouched
-- and preventing the Nyxaris route from crossing Panglia freight.
local pulsar_radius, pulsar_turn = 190, .5
local entry_radius, entry_turn = 151, .468

local function remove_stock_entry_routes()
	deleteRoute("nauvis-stargate-connection")
	deleteRoute("fulgora-stargate-connection")
	deleteRoute(old_calidus_entry_route)
	deleteRoute("solar-system-edge-aegis-stargate")
	deleteRoute("razi-vespera-aegis-stargate")
	deleteRoutesBetween("nauvis", entry_gate)
	deleteRoutesBetween("fulgora", entry_gate)
	deleteRoutesBetween("sye-calidus", entry_gate)
	deleteRoutesBetween("sye-vespera", entry_gate)
end

-- Preserve the source pulsar artwork below Solaris and Nyxaris.
-- Both first-frontier gates converge here; deeper Bellicos remains tier three.
-- Guard missing or retyped source prototypes.
-- Set real Factorio origin/distance/orientation in addition to orbit
-- metadata: PlanetsLib's sprite-baking and prototype cleanup stages can
-- otherwise leave old horizontal native marker positions behind.
local function endpoint_type(name)
	if data.raw["space-location"] and data.raw["space-location"][name] then
		return "space-location"
	end
	if data.raw.planet and data.raw.planet[name] then
		return "planet"
	end
	return nil
end

local function near_orbit()
  for _,n in ipairs({"near-bellicos-orbit","bellicos-near-orbit","near_bellicos_orbit"}) do
    if endpoint_type(n) then return n end
  end
  for _,kind in ipairs({"space-location","planet"}) do
    for n in pairs(data.raw[kind] or {}) do
      local low=n:lower()
      if low:find("bellicos",1,true) and low:find("orbit",1,true)
        and not low:find("stargate",1,true) then return n end
    end
  end
end

-- The pulsar is a PlanetsLib sprite-only parent. It exists while star art is
-- baked, then disappears from data.raw before Razi's last native positioning.
-- Construct a FIXED virtual coordinate for it even after that deletion.
local function offset(x,y,r,turn)
  local angle=2*math.pi*turn
  return x+r*math.sin(angle),y-r*math.cos(angle)
end

-- Factorio runs Lua 5.2. math.atan(y, x) silently ignores x there;
-- only math.atan2(y, x) correctly handles the missing-pulsar fallback.
-- In offline Lua >= 5.3 fixtures math.atan supports two arguments instead.
local atan2=math.atan2 or math.atan
local function parent_polar(x,y,parent)
  local dx,dy=x-parent.x,y-parent.y
  return math.sqrt(dx*dx+dy*dy),
    (atan2(dx,-dy)/(2*math.pi))%1
end

-- Name variants must not leave a source waypoint in another star system.
-- Inspect real prototypes and source route endpoints rather than locale text.
local function find_wardens()
  local result,seen={},{}
  local function include(name)
    if type(name)~="string" or seen[name] or not endpoint_type(name) then return end
    local simplified=name:lower():gsub("[^%w]","")
    if simplified:find("warden",1,true) and
      (simplified:find("point",1,true)
        or simplified:find("aegis",1,true)) then
      seen[name]=true
      result[#result+1]=name
    end
  end
  include("point-warden")
  for _,kind in ipairs({"space-location","planet"}) do
    for name in pairs(data.raw[kind] or {}) do include(name) end
  end
  for _,route in pairs(data.raw["space-connection"] or {}) do
    include(route.from)
    include(route.to)
  end
  table.sort(result)
  return result
end
bellicos.find_wardens=find_wardens

local function plan_expedition()
  if not endpoint_type(root_parent) then return nil end
  local layout=require("prototypes.system.galaxy_layout")
  local ex,ey=layout.anchor_position(root_parent)
  if not ex then return nil end
  local edge={x=ex,y=ey}
  local sx,sy=offset(ex,ey,pulsar_radius,pulsar_turn)
  local virtual_pulsar={x=sx,y=sy}
  local nx,ny=offset(sx,sy,3,.25)
  local virtual_near={x=nx,y=ny}
  local pulsar=endpoint_type("pulsar") and "pulsar" or nil
  local near=near_orbit()
  local entries={}
  local function append(name,parent,parent_position,r,turn,gate)
    if not endpoint_type(name) then return end
    local x,y=offset(parent_position.x,parent_position.y,r,turn)
    entries[#entries+1]={
      name=name,parent=parent,parent_position=parent_position,
      radius=r,turn=turn,x=x,y=y,gate=gate
    }
  end
  if pulsar then append(pulsar,root_parent,edge,pulsar_radius,pulsar_turn) end
  if near then
    if pulsar then
      append(near,pulsar,virtual_pulsar,3,.25)
    else
      -- The sprite-only pulsar is gone; preserve the EXACT world position
      -- by converting the virtual pulsar offset into the Edge's native
      -- polar coordinates, using quadrant-aware atan2 (Lua 5.2).
      local r,t=parent_polar(nx,ny,edge)
      append(near,root_parent,edge,r,t)
    end
  end
  append(entry_gate,root_parent,edge,entry_radius,entry_turn,true)
  if near then
    -- Fan the Warden spur apart from the Inner -> Outer belt crossing.
    -- The older bearings drew two nearly parallel routes across Aegis.
    -- The final route pass picks one source-compatible spine and preserves
    -- the author-provided custom asteroid resources before pruning shortcuts.
    append("aegis-inner-edge",near,virtual_near,29,.21)
    for _,name in ipairs(find_wardens()) do
      append(name,near,virtual_near,48,.32)
    end
    -- The exterior crossing leads to the real inner rim and Point Warden.
    -- Do not position or draw the source's dead-end Bellicos stargate.
    append("aegis-outer-edge",near,virtual_near,32,.10)
  end
  return entries,virtual_pulsar
end
bellicos.plan_expedition=plan_expedition
-- The decorative background and native starmap MUST share this one anchor.
-- Read the plan, never duplicate a stale static coordinate in another module.
function bellicos.pulsar_position()
  local _,position=plan_expedition()
  return position and position.x,position and position.y
end

-- The same single plan drives (1) pre-render PlanetsLib orbit placement and
-- (2) the post-render native coordinates. Never call PlanetsLib:update in the
-- post-render stage: that utility can recursively reposition CHILDREN and
-- pull Warden back into another solar system after baked sprites have moved.
-- Never recursively call PlanetsLib:update during Razi placement. In the
-- early data stages that routine recomputes children's global polar values
-- while their native position may already contain a local origin. The
-- result can strand Point Warden in Beetlejuice after the pulsar moves.
local function position_expedition(pre_render)
  local plan=plan_expedition()
  if not plan then return 0 end
  local count=0
  for _,target in ipairs(plan) do
    for _,kind in ipairs({"space-location","planet"}) do
      local body=(data.raw[kind] or {})[target.name]
      if body then
        local orbit={}
        for key,value in pairs(body.orbit or {}) do orbit[key]=value end
        local parent=endpoint_type(target.parent)
        if parent then
          orbit.parent={type=parent,name=target.parent}
        elseif target.parent=="pulsar" then
          orbit.parent={type="space-location",name=root_parent}
        end
        orbit.distance=target.radius
        orbit.orientation=target.turn
        body.orbit=orbit
        body.draw_orbit=false
        if pre_render then
          -- PlanetsLib uses the native origin when baking the source art.
          body.origin={x=target.parent_position.x,y=target.parent_position.y}
          body.distance=target.radius
          body.orientation=target.turn
        else
          -- FINAL: absolute Factorio starmap coordinates, including
          -- renamed endpoints and both prototype types. No hidden
          -- relative source orbit can override this rendered position.
          local x,y=target.x,target.y
          body.origin={x=0,y=0}
          body.distance=math.sqrt(x*x+y*y)
          body.orientation=(atan2(x,-y)/(2*math.pi))%1
        end
        count=count+1
      end
    end
  end
  return count
end

-- PlanetsLib tags custom orbit sprites with their ORIGINAL local shift.
-- Re-anchor tagged Bellicos layers to the same parent coordinates as native
-- destinations, without deleting, tinting or redrawing the source artwork.
local function reconcile_baked_art()
  local plan,virtual_pulsar=plan_expedition()
  if not plan then return 0 end
  local near=near_orbit()
  local by_name={}
  for _,target in ipairs(plan) do by_name[target.name]=target end
  -- Sprite-only pulsar no longer exists, but its artwork still has a tag.
  local ex,ey=require("prototypes.system.galaxy_layout")
    .anchor_position(root_parent)
  if ex and ey then by_name.pulsar={parent_position={x=ex,y=ey}} end
  local ui=(data.raw["utility-sprites"] or {}).default
  local layers=ui and ui.starmap_star and ui.starmap_star.layers
  if type(layers)~="table" then return 0 end
  local count=0
  for _,layer in ipairs(layers) do
    local target=type(layer)=="table"
      and by_name[layer.planetslib_orbit_name]
    local delta=layer and layer.planetslib_orbit_shift
    if target and type(delta)=="table"
      and type(delta[1])=="number" and type(delta[2])=="number" then
      -- When PlanetsLib deletes the sprite-only pulsar, Near Bellicos
      -- gets a native parent fallback to the Calidus slip stream. Its orbit
      -- artwork is already baked around the pulsar. Keep the virtual pulsar
      -- position even after PlanetsLib removes the sprite-only prototype.
      local origin=target.parent_position
      if target.name==near and virtual_pulsar then
        origin=virtual_pulsar
      end
      layer.shift={
        delta[1]+origin.x*32,
        delta[2]+origin.y*32
      }
      count=count+1
    end
  end
  return count
end
bellicos.reconcile_baked_art=reconcile_baked_art

-- Validate the actual native absolute placement, not only the orbit parent
-- names. A stale parent bearing previously passed the latter test while the
-- entire Aegis system appeared next to Nexus and Secretas.
local function native_point(name)
  for _,kind in ipairs({"space-location","planet"}) do
    local p=(data.raw[kind] or {})[name]
    local o=p and p.origin
    if p and o and type(p.distance)=="number"
      and type(p.orientation)=="number" then
      local x,y=o.x or o[1],o.y or o[2]
      if type(x)=="number" and type(y)=="number" then
        return offset(x,y,p.distance,p.orientation)
      end
    end
  end
end

function bellicos.reconcile_final_positions()
  if not (mods and mods["bellicos-and-aegis"]) then return 0 end
  local n=position_expedition(false)
  local art=reconcile_baked_art()
  local _,pulsar=plan_expedition()
  local near=near_orbit()
  -- A Lua 'and' expression returns ONE value even when native_point()
  -- returns x,y. Assigning through boolean short-circuit discarded the
  -- second value, crashing the Factorio data stage on every near-orbit load.
  local nx,ny
  if near then
    nx,ny=native_point(near)
  end
  local drift
  -- This is diagnostics only. Optional/retyped source prototypes must
  -- never be allowed to abort the entire modpack during loading.
  if type(pulsar)=="table"
    and type(pulsar.x)=="number" and type(pulsar.y)=="number"
    and type(nx)=="number" and type(ny)=="number" then
    drift=math.sqrt((nx-pulsar.x)^2+(ny-pulsar.y)^2)
    if drift>5 and type(log)=="function" then
      log(("[Razi Protocol/Bellicos] WARNING: Near orbit %.2f units from pulsar; expected <= 5"):format(drift))
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/Bellicos] Synchronized "..n..
      " expedition targets and "..art..
      " original orbit sprites; near-pulsar offset "..tostring(drift or "unknown"))
    local ids=find_wardens()
    if #ids==0 then
      log("[Razi Protocol/Bellicos] WARNING: No Point Warden source ID found; inspect enabled Aegis mod")
    end
    for _,name in ipairs(ids) do
      for _,kind in ipairs({"space-location","planet"}) do
        local body=(data.raw[kind] or {})[name]
        if body and body.origin then
          local wx,wy=offset(body.origin.x,body.origin.y,
            body.distance,body.orientation)
          log(string.format("[Razi Protocol/Bellicos] FINAL Warden %s (%s) x=%.2f y=%.2f",name,kind,wx,wy))
        end
      end
    end
  end
  return n,art
end

function bellicos.data_updates()
  -- Source mods can revise their system artwork in data-updates.
  -- Reapply placement WITH source sprites intact, before PlanetsLib bakes
  -- and removes sprite-only parent stars during data-final-fixes.
  if mods and mods["bellicos-and-aegis"] then position_expedition(true) end
end

function bellicos.data()
  if not (mods and mods["bellicos-and-aegis"]) then return end
  position_expedition(true)
  -- Only the final route authority installs the two researched approaches.
  -- Avoid another unapproved data-stage link which it would later remove.
  remove_stock_entry_routes()
end

local function soften_pulsar_art()
  local util=data.raw["utility-sprites"] and data.raw["utility-sprites"].default
  local layers=util and util.starmap_star and util.starmap_star.layers
  if type(layers)~="table" then return end
  local touched=0
  for _,layer in ipairs(layers) do
    local filename=type(layer.filename)=="string" and layer.filename:lower() or ""
    local tagged=layer.planetslib_orbit_name=="pulsar"
    local source_file=filename:find("__bellicos-and-aegis",1,true)
      and filename:find("pulsar",1,true)
    if tagged or source_file then
      local tint=layer.tint or {r=1,g=1,b=1,a=1}
      layer.tint={r=tint.r or 1,g=tint.g or 1,b=tint.b or 1,
        a=math.min(tint.a or 1,.50)}
      touched=touched+1
    end
  end
  if touched>0 and type(log)=="function" then
    log("[Razi Protocol/starmap] Dimmed "..touched.." pulsar atlas layers")
  end
end

function bellicos.data_final_fixes()
  if not (mods and mods["bellicos-and-aegis"]) then return end
  remove_stock_entry_routes()
  bellicos.reconcile_final_positions()
  local glare=settings and settings.startup
    and settings.startup["razi-starmap-soften-bellicos"]
  if not glare or glare.value~=false then soften_pulsar_art() end
end

-- Delete the obsolete far-side marker only AFTER source mods have read it.
-- Research itself survives for native progression; only effects that unlock
-- a nonexistent location are removed. Repeat safely after late research passes.
function bellicos.retire_far_gate()
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
    if (data.raw[kind] or {})[retired_gate] then
      data.raw[kind][retired_gate]=nil
      removed=removed+1
    end
  end
  local ui=(data.raw["utility-sprites"] or {}).default
  local layers=ui and ui.starmap_star and ui.starmap_star.layers
  if type(layers)=="table" then
    for i=#layers,1,-1 do
      if layers[i].planetslib_orbit_name==retired_gate then
        table.remove(layers,i)
      end
    end
  end
  return removed
end

-- Run after final route ownership and asteroid-family integration. Keep the
-- author's native species/curves; harden vanilla asteroid mid-route encounters.
-- Protect one readable route spine. The former fallback algorithm appended
-- more lines atop the source's multiple direct chords and bypassed the ring.
-- Preserve native IDs and custom asteroid drops on the surviving connections.
function bellicos.fortify_routes()
  if not (mods and mods["bellicos-and-aegis"]) then return 0 end
  local routes=data.raw["space-connection"] or {}
  local asteroid=require("prototypes.system.asteroid_profiles")
  local icons=require("prototypes.system.route_icons")
  local wardens=find_wardens()
  table.sort(wardens,function(a,b)
    if a=="point-warden" then return true end
    if b=="point-warden" then return false end
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
    if not route then
      local name="razi-aegis-"..spec.a.."-"..spec.b
      if not routes[name] then
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
      asteroid.apply(route,spec.profile)
      asteroid.apply_field(route,spec.profile=="aegis_approach" and 1.5 or 1.8)
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
    if candidate then asteroid.preserve_custom(candidate,old.route) end
    routes[old.name]=nil
  end
  local retired=bellicos.retire_far_gate()
  if type(log)=="function" then
    log(("[Razi Protocol/Aegis] Expedition spine: %d new links, %d obsolete chords, %d retired gateway prototypes/routes"):format(
      added,#discarded,retired))
  end
  return added,#discarded
end

return bellicos
