local bellicos = {}

local entry_gate = "calidus-bellicos-stargate-calidus"
local bellicos_gate = "calidus-bellicos-stargate-bellicos"
local old_calidus_entry_route = "sye-calidus-bellicos-stargate"
-- This is a shared frontier BELOW the two starter stars. These native IDs
-- must remain stable even though their upstream names say "calidus".
local root_parent = "sye-calidus"
local pulsar_radius, pulsar_turn = 226, .5
local entry_radius, entry_turn = 166, .5

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
    -- Keep all SOURCE connections and asteroid encounters unchanged;
    -- only the visual native destination positions are reshaped.
    append("aegis-inner-edge",near,virtual_near,29,.205)
    for _,name in ipairs(find_wardens()) do
      append(name,near,virtual_near,48,.255)
    end
    -- Outer Edge turns southeast, then the Bellicos-side stargate follows
    -- on a short almost-vertical exit instead of doubling back to the west.
    append("aegis-outer-edge",near,virtual_near,66,.345)
    append(bellicos_gate,near,virtual_near,81,.37,true)
  elseif pulsar then
    append(bellicos_gate,pulsar,virtual_pulsar,81,.37,true)
  else
    local gx,gy=offset(sx,sy,81,.37)
    -- Also used when the source supplies neither a persistent pulsar
    -- prototype nor the Near Bellicos parent. Keep the gateway near the
    -- missing pulsar rather than projecting it toward the central stars.
    local r,t=parent_polar(gx,gy,edge)
    append(bellicos_gate,root_parent,edge,r,t,true)
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
        a=math.min(tint.a or 1,.82)}
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

-- Run after final route ownership and asteroid-family integration. Keep the
-- author's native species/curves; harden vanilla asteroid mid-route encounters.
function bellicos.fortify_routes()
  if not (mods and mods["bellicos-and-aegis"]) then return 0 end
  local routes=data.raw["space-connection"] or {}
  local asteroid=require("prototypes.system.asteroid_profiles")
  local icons=require("prototypes.system.route_icons")
  local warden={}
  for _,name in ipairs(find_wardens()) do warden[name]=true end
  local points={
    ["aegis-inner-edge"]=true,["aegis-outer-edge"]=true,
    ["calidus-bellicos-stargate-calidus"]=true,
    ["calidus-bellicos-stargate-bellicos"]=true,
    ["near-bellicos-orbit"]=true,["bellicos-near-orbit"]=true,
    ["near_bellicos_orbit"]=true
  }
  for name in pairs(warden) do points[name]=true end
  local function has(a,b)
    for _,route in pairs(routes) do
      if (route.from==a and route.to==b)
        or (route.to==a and route.from==b) then return true end
    end
    return false
  end
  -- Restore missing native connections without overwriting a genuine
  -- author route or bridging directly around their original Aegis belt.
  local links={
    {entry_gate,"aegis-inner-edge",56000,"aegis_approach"},
    {"aegis-outer-edge",bellicos_gate,38000,"aegis_depths"}
  }
  for _,name in ipairs(find_wardens()) do
    links[#links+1]={"aegis-inner-edge",name,28000,"aegis_depths"}
    links[#links+1]={name,"aegis-outer-edge",34000,"aegis_depths"}
  end
  local added=0
  for _,link in ipairs(links) do
    local a,b,km,profile=link[1],link[2],link[3],link[4]
    if endpoint_type(a) and endpoint_type(b) and not has(a,b) then
      local key="razi-aegis-"..a.."-"..b
      data:extend({icons.assign({
        type="space-connection",name=key,from=a,to=b,length=km,
        shape="line",asteroid_spawn_definitions=asteroid.create(profile)
      },profile)})
      added=added+1
    end
  end
  for _,route in pairs(routes) do
    if points[route.from] or points[route.to] then
      local internal=points[route.from] and points[route.to]
      asteroid.apply_field(route,internal and 1.80 or 1.52)
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/Aegis] Restored "..added..
      " missing source-compatible links and reinforced native asteroid routes")
  end
  return added
end

return bellicos
