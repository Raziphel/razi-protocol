-- Fulgora must be reachable without Ribbonia: Ribbonia's research needs electromagnetic science, made on Fulgora
-- (prototypes/technology/gates/campaign_weave.lua). With the inner belt edge on Ribbonia, Fulgora's only routes led
-- through Ribbonia and the game could not go on.
--   lua5.2 tests/lua/test_fulgora_before_ribbonia.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, message)
  if not ok then error(message, 2) end
end

-- Source-owned links the reconcile pass keeps (route_authority.lua, native_pairs): the belt crossing and Cerys.
local NATIVE = { { "asteroid-belt-inner-edge", "asteroid-belt-outer-edge" }, { "fulgora", "cerys" } }

local function reachable(specifications, start, target, closed)
  local links = {}
  local all = {}
  for _, route in ipairs(specifications) do all[#all + 1] = route end
  for _, route in ipairs(NATIVE) do all[#all + 1] = route end
  for _, route in ipairs(all) do
    local a, b = route[1], route[2]
    links[a] = links[a] or {}
    links[b] = links[b] or {}
    table.insert(links[a], b)
    table.insert(links[b], a)
  end
  local seen, queue = { [start] = true }, { start }
  while #queue > 0 do
    local here = table.remove(queue, 1)
    if here == target then return true end
    for _, next_place in ipairs(links[here] or {}) do
      if not seen[next_place] and next_place ~= closed then
        seen[next_place] = true
        queue[#queue + 1] = next_place
      end
    end
  end
  return false
end

-- The route specifications are all this test reads; the hazard, icon and layout helpers are stubs.
package.loaded["prototypes.world.asteroids.asteroid_profiles"] = setmetatable({}, { __index = function() return function() end end })
package.loaded["prototypes.world.routes.route_icons"] = setmetatable({}, { __index = function() return function() end end })
package.loaded["prototypes.world.starmap.galaxy_layout"] = setmetatable({}, { __index = function() return function() end end })

for _, with_belt in ipairs({ true, false }) do
  local locations = {}
  if with_belt then
    locations["asteroid-belt-outer-edge"] = {}
    locations["asteroid-belt-inner-edge"] = {}
  end
  rawset(_G, "data", { raw = { ["space-location"] = locations, planet = {}, ["space-connection"] = {} } })
  rawset(_G, "mods", {})
  package.loaded["prototypes.world.routes.route_reconcile"] = nil
  local reconcile = require("prototypes.world.routes.route_reconcile")
  local label = with_belt and "with the belt" or "without the belt"
  check(reachable(reconcile.specifications, "sye-vibrant", "fulgora", "ribbonia"),
    "Fulgora is reachable only through Ribbonia " .. label)
  check(reachable(reconcile.specifications, "sye-vibrant", "ribbonia", nil), "Ribbonia is unreachable " .. label)
end
print("ok")
