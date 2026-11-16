local bellicos = {}

local places = require("prototypes.world.systems.bellicos_places")
local routes = require("prototypes.world.systems.bellicos_routes")
local entry_gate = places.entry_gate
local root_parent = places.root_parent
local endpoint_type = places.endpoint_type
local near_orbit = places.near_orbit
local offset = places.offset
local atan2 = places.atan2
local parent_polar = places.parent_polar
local find_wardens = places.find_wardens
local native_point = places.native_point
local old_calidus_entry_route = "sye-calidus-bellicos-stargate"
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
local function plan_expedition()
  if not endpoint_type(root_parent) then return nil end
  local layout=require("prototypes.world.starmap.galaxy_layout")
  local ex,ey=layout.anchor_position(root_parent)
  if not ex then return nil end
  local edge={x=ex,y=ey}
  local sx,sy=offset(ex,ey,pulsar_radius,pulsar_turn)
  local virtual_pulsar={x=sx,y=sy}
  local nx,ny=offset(sx,sy,3,.25)
  local virtual_near={x=nx,y=ny}
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
  if near then
    -- The sprite-only bellicos-pulsar is removed by PlanetsLib. Put the
    -- orbit at its EXACT place beside the virtual pulsar by converting the
    -- offset into the Edge's polar coordinates, using quadrant-aware atan2
    -- (Lua 5.2).
    local r,t=parent_polar(nx,ny,edge)
    append(near,root_parent,edge,r,t)
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
      local body=(data.raw[kind] or {})[target.name] --[[@as table?]]
      if body then
        local orbit={}
        for key,value in pairs(body.orbit or {}) do orbit[key]=value end
        local parent=endpoint_type(target.parent)
        if parent then
          orbit.parent={type=parent,name=target.parent}
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
  local ui=(data.raw["utility-sprites"] or {}).default
  local layers=ui and ui.starmap_star and ui.starmap_star.layers
  if type(layers)~="table" then return 0 end
  local count=0
  for _,item in ipairs(layers) do
    local layer=item --[[@as table]]
    local target=type(layer)=="table"
      and by_name[layer.planetslib_orbit_name]
    local delta=layer and layer.planetslib_orbit_shift
    if target and type(delta)=="table"
      and type(delta[1])=="number" and type(delta[2])=="number" then
      -- Near Bellicos has a native parent at the Calidus slip stream. Its
      -- orbit artwork is already baked around the pulsar. Keep the virtual
      -- pulsar position.
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

-- Aegis & Bellicos draws its pulsar as one starmap_star layer at the place of
-- its sprite-only `bellicos-pulsar` (data-updates.lua:33-57 of 0.4.5), which
-- is nowhere near where this mod lays the system out.
local pulsar_picture="__bellicos-and-aegis-assets__/graphics/starmap/starmap-pulsar.png"

local function pulsar_layers()
  local util=data.raw["utility-sprites"] and data.raw["utility-sprites"].default
  local layers=util and util.starmap_star and util.starmap_star.layers
  local found={}
  if type(layers)~="table" then return found end
  for _,item in ipairs(layers) do
    local layer=item --[[@as table]]
    if layer.filename==pulsar_picture then found[#found+1]=layer end
  end
  return found
end

-- The picture belongs at the point the system is laid out around: the virtual
-- pulsar, which is also the parent of Near Bellicos Orbit and of everything
-- the plan places beyond it.
local function move_pulsar_art()
  local layers=pulsar_layers()
  local x,y=bellicos.pulsar_position()
  if #layers==0 or not x or not y then
    if type(log)=="function" then
      log("[Razi Protocol/starmap] Aegis pulsar picture not found, left as it is")
    end
    return
  end
  for _,layer in ipairs(layers) do layer.shift={32*x,32*y} end
  if type(log)=="function" then
    log(("[Razi Protocol/starmap] Moved the Aegis pulsar picture to the centre of the Bellicos system (%.1f, %.1f)")
      :format(x,y))
  end
end

local function soften_pulsar_art()
  local touched=0
  for _,layer in ipairs(pulsar_layers()) do
    local tint=layer.tint or {r=1,g=1,b=1,a=1}
    layer.tint={r=tint.r or 1,g=tint.g or 1,b=tint.b or 1,
      a=math.min(tint.a or 1,.50)}
    touched=touched+1
  end
  if touched>0 and type(log)=="function" then
    log("[Razi Protocol/starmap] Dimmed "..touched.." pulsar atlas layers")
  end
end

function bellicos.data_final_fixes()
  if not (mods and mods["bellicos-and-aegis"]) then return end
  remove_stock_entry_routes()
  bellicos.reconcile_final_positions()
  move_pulsar_art()
  local glare=settings and settings.startup
    and settings.startup["razi-starmap-soften-bellicos"]
  if not glare or glare.value~=false then soften_pulsar_art() end
end

-- The route passes live in bellicos_routes.lua.
bellicos.retire_far_gate = routes.retire_far_gate
bellicos.dedupe_internal_routes = routes.dedupe_internal_routes
bellicos.fortify_routes = routes.fortify_routes

return bellicos
