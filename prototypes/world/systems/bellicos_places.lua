-- The names and lookups the Bellicos passes share: the Aegis entry gate and the retired
-- far-side gate, the frontier they hang from, the Near orbit, the Wardens and the native
-- position of a body.
local entry_gate = "calidus-bellicos-stargate-calidus"
-- Native source prototype was an unreachable, obsolete return gateway.
-- Retire only this far-side destination; keep the real Aegis entry gate.
local retired_gate = "calidus-bellicos-stargate-bellicos"
-- This is a shared frontier BELOW the two starter stars. These native IDs
-- must remain stable even though their upstream names say "calidus".
local root_parent = "sye-calidus"

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
  include("aegis-warden")
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


return {
  entry_gate = entry_gate,
  retired_gate = retired_gate,
  root_parent = root_parent,
  endpoint_type = endpoint_type,
  near_orbit = near_orbit,
  offset = offset,
  atan2 = atan2,
  parent_polar = parent_polar,
  find_wardens = find_wardens,
  native_point = native_point,
}
