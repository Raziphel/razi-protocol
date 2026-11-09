---@diagnostic disable: missing-fields, need-check-nil, undefined-field, assign-type-mismatch, inject-field
-- luacheck: ignore 122 211 212 411
-- Aegis & Bellicos 0.4.5 draws its pulsar as one starmap_star layer at the position of the
-- sprite-only `bellicos-pulsar`. Razi lays the system out elsewhere, so the picture has to follow.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
  if not condition then error(message, 2) end
end

package.loaded["__space-age__.prototypes.planet.asteroid-spawn-definitions"] = {
  aquilo_solar_system_edge = {},
  spawn_definitions = function() return {} end
}

local PULSAR_FILE = "__bellicos-and-aegis-assets__/graphics/starmap/starmap-pulsar.png"
-- Where Aegis puts the picture: 120 units from the sun at orientation 0.48, shift = 32 * position.
local aegis_x = 120 * math.sin(2 * math.pi * 0.48)
local aegis_y = -120 * math.cos(2 * math.pi * 0.48)

-- Design, not code under test: the Calidus slip stream is at (0, 20) and the system lies 190 units straight south.
local centre_x, centre_y = 0, 20 + 190

local function run(options)
  options = options or {}
  local locations = {
    ["solar-system-edge"] = {name = "solar-system-edge"},
    ["sye-vespera"] = {name = "sye-vespera"},
    ["sye-calidus"] = {name = "sye-calidus"},
    ["calidus-bellicos-stargate-calidus"] = {name = "calidus-bellicos-stargate-calidus"},
    ["calidus-bellicos-stargate-bellicos"] = {name = "calidus-bellicos-stargate-bellicos"},
    ["aegis-outer-edge"] = {name = "aegis-outer-edge"},
    ["aegis-inner-edge"] = {name = "aegis-inner-edge"},
    ["aegis-warden"] = {name = "aegis-warden"},
    ["bellicos-orbit"] = {name = "bellicos-orbit"},
  }
  local star = {shift = {0, 0}, filename = "__core__/graphics/icons/starmap-star.png", size = 512, scale = 0.5}
  local pulsar = {shift = {32 * aegis_x, 32 * aegis_y}, filename = PULSAR_FILE, size = 2600, scale = 1.6}
  local layers = {star}
  if not options.no_layer then layers[#layers + 1] = pulsar end
  local routes = {}
  rawset(_G, "data", {
    raw = {
      ["space-location"] = locations, planet = {}, ["space-connection"] = routes,
      ["utility-sprites"] = {default = {starmap_star = {layers = layers}}},
    },
    extend = function() end
  })
  rawset(_G, "mods", options.no_aegis and {} or {["bellicos-and-aegis"] = "0.4.5"})
  rawset(_G, "settings", {startup = {["razi-starmap-soften-bellicos"] = {value = not options.glare_off}}})
  rawset(_G, "deleteRoute", function(name) routes[name] = nil end)
  rawset(_G, "deleteRoutesBetween", function() end)
  local lines = {}
  rawset(_G, "log", function(line) lines[#lines + 1] = line end)
  package.loaded["prototypes.world.systems.bellicos"] = nil
  local module = require("prototypes.world.systems.bellicos")
  module.data()
  module.data_final_fixes()
  return layers, star, pulsar, locations, lines
end

local function position(body)
  local angle = 2 * math.pi * body.orientation
  return body.origin.x + body.distance * math.sin(angle), body.origin.y - body.distance * math.cos(angle)
end

local function logged(lines, text)
  local n = 0
  for _, line in ipairs(lines) do
    if line:find(text, 1, true) then n = n + 1 end
  end
  return n
end

-- The picture sits at the centre of the system razi lays out.
local layers, star, pulsar, locations, lines = run()
check(#layers == 2, "The pass must not add or drop star layers")
check(type(pulsar.shift) == "table" and #pulsar.shift == 2
  and type(pulsar.shift[1]) == "number" and type(pulsar.shift[2]) == "number",
  "The pulsar shift must stay a two-number array")
check(math.abs(pulsar.shift[1] / 32 - centre_x) < 0.01 and math.abs(pulsar.shift[2] / 32 - centre_y) < 0.01,
  ("The pulsar picture is at (%.2f, %.2f), not at the centre of the system (%.0f, %.0f)")
    :format(pulsar.shift[1] / 32, pulsar.shift[2] / 32, centre_x, centre_y))

-- The planets of the system lie around that point.
for _, name in ipairs({"bellicos-orbit", "aegis-warden", "aegis-inner-edge", "aegis-outer-edge"}) do
  local x, y = position(locations[name])
  check(math.sqrt((x - pulsar.shift[1] / 32) ^ 2 + (y - pulsar.shift[2] / 32) ^ 2) <= 75,
    "Aegis location is far from the pulsar picture: " .. name)
end

-- The dimming stays, and the star itself is left alone.
check(pulsar.tint and pulsar.tint.a == 0.5, "The pulsar picture must stay dimmed")
check(star.tint == nil and star.shift[1] == 0 and star.shift[2] == 0, "The star picture must not change")
check(logged(lines, "Dimmed 1 pulsar atlas layers") == 1, "The dimming is no longer logged")
check(logged(lines, "Moved the Aegis pulsar picture") == 1,
  "The move of the pulsar picture is not logged")

-- With the glare setting off the picture still moves, but is not dimmed.
local _, _, bright = run({glare_off = true})
check(math.abs(bright.shift[1] / 32 - centre_x) < 0.01 and math.abs(bright.shift[2] / 32 - centre_y) < 0.01,
  "The pulsar picture must move with the glare setting off too")
check(bright.tint == nil, "The glare setting off must leave the tint alone")

-- Soft failures: no layer, no Aegis.
local _, _, _, _, missing_lines = run({no_layer = true})
check(logged(missing_lines, "pulsar picture not found") == 1, "A missing pulsar layer must be logged once")
local _, _, untouched = run({no_aegis = true})
check(untouched.shift[1] == 32 * aegis_x and untouched.shift[2] == 32 * aegis_y and untouched.tint == nil,
  "Without Aegis the layer must not be touched")

print("Aegis pulsar picture tests passed")
