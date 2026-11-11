-- Regression: the first accessible planet beyond Vibrant's asteroid belt
-- must be Fulgora. Ribbonia needs Fulgora's electromagnetic science, so
-- entering the belt at Ribbonia would deadlock the campaign.
-- Runs the real route reconciler and final route authority with only the
-- rendering/starmap dependencies stubbed out.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
  if not ok then error(message, 2) end
end

local native_asteroids = {nauvis_fulgora = {}, fulgora_aquilo = {},
  gleba_aquilo = {}, aquilo_solar_system_edge = {}, vulcanus_castra = {},
  nauvis_gleba = {}, spawn_definitions = function()
    return {{type = "asteroid-chunk", asteroid = "metallic-asteroid-chunk",
      spawn_points = {{distance = 0.5, probability = .02, speed = .035}}}}
  end}
package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"] = native_asteroids
package.loaded["prototypes.world.asteroids.asteroid_profiles"] = nil
package.loaded["prototypes.world.routes.route_icons"] = {
  assign = function(proto) return proto end
}
package.loaded["prototypes.world.starmap.galaxy_layout"] = {
  anchor_position = function() return 0, 0 end
}
package.loaded["prototypes.world.systems.abacayba_integration"] = {
  planet_name = function() return nil end
}
rawset(_G, "settings", {startup = {
  ["razi-curated-space-routes"] = {value = true}
}})
rawset(_G, "mods", {base = "2.1.25"})

local function pair(a, b)
  if a > b then a, b = b, a end
  return a .. "|" .. b
end

local function connections(routes)
  local pairs = {}
  for _, route in pairs(routes) do
    local id = pair(route.from, route.to)
    check(not pairs[id], "Duplicate space connection: " .. id)
    pairs[id] = route
  end
  return pairs
end

local function has_asteroid(route, name)
  for _, entry in ipairs(route and route.asteroid_spawn_definitions or {}) do
    if entry.asteroid == name then return true end
  end
  return false
end

local function test_scenario(with_belt)
  local spaces = {["sye-vibrant"] = {}}
  local planets = {fulgora = {}, ribbonia = {}}
  local custom = {
    type = "asteroid-chunk", asteroid = "custom-inner-belt-ore",
    probability = .04, speed = .035
  }
  local source = {custom}
  local routes = {
    ["old-vibrant-ribbonia"] = {name = "old-vibrant-ribbonia",
      from = "sye-vibrant", to = "ribbonia", length = 20000,
      asteroid_spawn_definitions = {}}
  }
  if with_belt then
    spaces["asteroid-belt-outer-edge"] = {}
    spaces["asteroid-belt-inner-edge"] = {}
    routes["native-vibrant-belt"] = {name = "native-vibrant-belt",
      from = "asteroid-belt-outer-edge", to = "asteroid-belt-inner-edge",
      length = 5000, asteroid_spawn_definitions = {}}
    routes["legacy-ribbonia-inner"] = {name = "legacy-ribbonia-inner",
      from = "ribbonia", to = "asteroid-belt-inner-edge",
      length = 24000, asteroid_spawn_definitions = source}
  end
  rawset(_G, "data", {raw = {
    planet = planets, ["space-location"] = spaces,
    ["space-connection"] = routes, technology = {}
  }})
  function data:extend(protos)
    for _, proto in ipairs(protos) do
      self.raw[proto.type][proto.name] = proto
    end
  end
  package.loaded["prototypes.world.routes.route_reconcile"] = nil
  package.loaded["prototypes.world.routes.route_authority"] = nil
  local reconcile = require("prototypes.world.routes.route_reconcile")
  local authority = require("prototypes.world.routes.route_authority")
  reconcile.data_final_fixes()
  authority.data_final_fixes()

  local edges = connections(routes)
  local entry = with_belt and "asteroid-belt-inner-edge" or "sye-vibrant"
  local first = edges[pair(entry, "fulgora")]
  check(first, "First Vibrant arrival must connect directly to Fulgora")
  check(not edges[pair(entry, "ribbonia")],
    "Ribbonia must not be an entrance before Fulgora is discovered")
  check(edges[pair("fulgora", "ribbonia")],
    "Ribbonia must stay reachable from Fulgora after its discovery")
  check(not edges[pair("sye-vibrant", "ribbonia")],
    "The legacy direct Ribbonia shortcut must not survive")

  if with_belt then
    check(edges[pair("sye-vibrant", "asteroid-belt-outer-edge")],
      "Vibrant still needs its exterior approach")
    check(edges[pair("asteroid-belt-outer-edge", "asteroid-belt-inner-edge")]
      == routes["native-vibrant-belt"],
      "Physical belt crossing must remain in the route network")
    check(not edges[pair("sye-vibrant", "fulgora")],
      "Fulgora must not bypass the researched physical belt")
    check(has_asteroid(first, "custom-inner-belt-ore"),
      "Relocating the inner route must preserve source-owned asteroid resources")
    check(source[1] == custom and #source == 1,
      "Original route asteroid list must not be mutated")
  end

  -- Connectivity must follow actual researched locations, not merely a
  -- matching line on the starmap. At first, Ribbonia is still locked.
  local function reachable(unlocked)
    local visited = {["sye-vibrant"] = true}
    local queue = {"sye-vibrant"}
    for i = 1, #queue do
      local current = queue[i]
      for _, route in pairs(routes) do
        local other = route.from == current and route.to
          or route.to == current and route.from
        if other and not visited[other] and unlocked[other] then
          visited[other] = true
          queue[#queue + 1] = other
        end
      end
    end
    return visited
  end
  local known = {["sye-vibrant"] = true, fulgora = true}
  if with_belt then
    known["asteroid-belt-inner-edge"] = true
    known["asteroid-belt-outer-edge"] = true
  end
  local before = reachable(known)
  check(before.fulgora and not before.ribbonia,
    "Fulgora must be accessible before Ribbonia research")
  known.ribbonia = true
  check(reachable(known).ribbonia, "Ribbonia must open after Fulgora")
  local count = 0
  for _ in pairs(routes) do count = count + 1 end
  reconcile.data_final_fixes()
  check(authority.data_final_fixes() == 0,
    "Second route-authority pass must not modify the reconciled topology")
  local again = 0
  for _ in pairs(routes) do again = again + 1 end
  check(count == again and connections(routes)[pair(entry, "fulgora")],
    "Running route passes again must not recreate Ribbonia entry routes")
end

test_scenario(true)
test_scenario(false)
print("Vibrant first arrival: belt crossing, Fulgora unlock and Ribbonia access passed")
