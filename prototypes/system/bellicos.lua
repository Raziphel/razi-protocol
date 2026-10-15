local bellicos = {}

local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

local entry_gate = "calidus-bellicos-stargate-calidus"
local bellicos_gate = "calidus-bellicos-stargate-bellicos"
local old_calidus_entry_route = "sye-calidus-bellicos-stargate"
local deep_space_entry_route = "solar-system-edge-aegis-stargate"

local function remove_stock_entry_routes()
	deleteRoute("nauvis-stargate-connection")
	deleteRoute("fulgora-stargate-connection")
	deleteRoute(old_calidus_entry_route)
	deleteRoutesBetween("nauvis", entry_gate)
	deleteRoutesBetween("fulgora", entry_gate)
	deleteRoutesBetween("sye-calidus", entry_gate)
end

-- Preserve the source pulsar artwork in a distinct northern annex,
-- beyond Nexus/Oort/Sol. Guard missing or retyped source prototypes.
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

local function position_expedition()
  if not endpoint_type("solar-system-edge") then return end
  -- Anchor to Razi's canonical star-chart origin rather than relying on an
  -- upstream location that may still carry stale absolute coordinates.
  local layout=require("prototypes.system.galaxy_layout")
  local edge_x,edge_y=layout.anchor_position("solar-system-edge")
  if not edge_x then return end
  local positions={["solar-system-edge"]={x=edge_x,y=edge_y}}
  local updates,planned={},{}
  local function place(n,parent,r,t,gate)
    local kind,pk=endpoint_type(n),endpoint_type(parent)
    local origin=positions[parent]
    if not (kind and pk and origin) then return end
    local orbit={parent={type=pk,name=parent},
      distance=r,orientation=t}
    updates[#updates+1]={type=kind,name=n,orbit=orbit,
      draw_orbit=false,redrawn_connections_exclude=gate or nil}
    planned[#planned+1]={kind=kind,name=n,origin=origin,r=r,t=t}
    local angle=t*2*math.pi
    positions[n]={x=origin.x+r*math.sin(angle),
      y=origin.y-r*math.cos(angle)}
  end
  local near=near_orbit()
  local pulsar=endpoint_type("pulsar") and "pulsar" or nil
  if pulsar then place(pulsar,"solar-system-edge",170,0.055) end
  if near then
    if pulsar then place(near,pulsar,3,0.25)
    else place(near,"solar-system-edge",170,0.055) end
  end
  place(entry_gate,"solar-system-edge",62,0.035,true)
  if near then
    -- Distinct bearings for each visible Aegis destination. The short
    -- inner/warden corridor is no longer horizontal, and the outer rim
    -- and return stargate form a readable downward arc.
    place("aegis-inner-edge",near,29,0.205)
    place("point-warden",near,48,0.285)
    place("aegis-outer-edge",near,74,0.33)
    place(bellicos_gate,near,57,0.43,true)
  elseif pulsar then place(bellicos_gate,pulsar,57,0.43,true)
  else place(bellicos_gate,"solar-system-edge",170,0.055,true) end
  if #updates>0 then PlanetsLib:update(updates) end
  -- PlanetsLib:update updates orbit data, but some source versions leave the
  -- Factorio-native absolute fields unchanged. Reconcile them on BOTH
  -- data.lua and final-fixes so art/labels do not snap back to a flat row.
  for _,item in ipairs(planned) do
    local location=(data.raw[item.kind] or {})[item.name]
    if location then
      location.origin={x=item.origin.x,y=item.origin.y}
      location.distance=item.r
      location.orientation=item.t
      location.draw_orbit=false
    end
  end
end

function bellicos.data()
	if not mods["bellicos-and-aegis"] then
		return
	end

	position_expedition()
	remove_stock_entry_routes()
	deleteRoute(deep_space_entry_route)

	-- When a different Aegis version omits the gateway, do not register a
	-- space connection with nonexistent endpoints.
	if not endpoint_type("solar-system-edge") or not endpoint_type(entry_gate) then
		return
	end

	data:extend({
		{
			type = "space-connection",
			name = deep_space_entry_route,
			from = "solar-system-edge",
			to = entry_gate,
			length = 250000,
			asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.aquilo_solar_system_edge)
		}
	})
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
        a=math.min(tint.a or 1,.54)}
      touched=touched+1
    end
  end
  if touched>0 and type(log)=="function" then
    log("[Razi Protocol/starmap] Dimmed "..touched.." pulsar atlas layers")
  end
end

function bellicos.data_final_fixes()
	if not mods["bellicos-and-aegis"] then
		return
	end

	-- Other route compatibility passes can run after the source mod. Keep only
	-- Razi Protocol's deep-space entrance while preserving every route inside Aegis.
	remove_stock_entry_routes()
	-- Source data-final-fixes may reparent its giant pulsar after data.lua.
	-- Reaffirm only existing Razi-managed anchors at the final stage.
	position_expedition()
	local glare=settings and settings.startup
	  and settings.startup["razi-starmap-soften-bellicos"]
	if not glare or glare.value~=false then soften_pulsar_art() end
	-- A gateway removed by a later dependency pass must not leave our
	-- replacement deep-space route pointing to an invalid endpoint.
	if not endpoint_type("solar-system-edge") or not endpoint_type(entry_gate) then
		deleteRoute(deep_space_entry_route)
	end
end

return bellicos
