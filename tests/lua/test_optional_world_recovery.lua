-- Source-mod shims for Nulla (compat/nulla_guard.lua) and PlanetAthos (compat/athos_cycle_guard.lua) on mocked data.
-- Run from the mod root:
--   lua5.2 tests/lua/test_optional_world_recovery.lua
package.path = "./?.lua;./?/init.lua;" .. package.path
dofile("tests/lua/razi_lib_bootstrap.lua")
local function check(ok, message)
  if not ok then error(message, 2) end
end

-- Nulla 1.0.2 calls add_radio_interference_energy(data.raw.furnace["electric-furnace"], 2); K2SO has no such furnace.
rawset(_G, "mods", { nulla = "1.0.2", PlanetAthos = "1.1.3" })
local calls = 0
local source = {
  add_radio_interference_energy = function(proto, value)
    calls = calls + 1
    proto.energy_source.emissions_per_minute.radio_interference = value
  end
}
package.loaded["lib"] = source
package.preload["__nulla__/lib"] = function() return source end
package.loaded["prototypes.compat.nulla_guard"] = nil
local nulla = require("prototypes.compat.nulla_guard")
check(nulla.data_updates(), "Nulla source helper was not guarded")
source.add_radio_interference_energy(nil, 2)
local energy = { energy_source = { emissions_per_minute = {} } }
source.add_radio_interference_energy(energy, 3)
check(calls == 1 and energy.energy_source.emissions_per_minute.radio_interference == 3,
  "Missing prototype guard must not affect valid source emissions")
nulla.data_updates()
source.add_radio_interference_energy(energy, 4)
check(calls == 2, "Idempotent Nulla guard must not wrap twice")

-- Without Nulla nothing is wrapped: the helper still reaches the source function with a missing prototype.
rawset(_G, "mods", {})
local plain_calls = 0
package.loaded["lib"] = { add_radio_interference_energy = function() plain_calls = plain_calls + 1 end }
local installed = nulla.data_updates()
package.loaded["lib"].add_radio_interference_energy(nil, 2)
check(installed == false and plain_calls == 1, "The Nulla guard must do nothing without the mod")
package.loaded["lib"] = nil
package.preload["__nulla__/lib"] = nil

-- PlanetAthos walks every descendant of a technology recursively and cannot cope with a cycle.
package.loaded["prototypes.compat.athos_cycle_guard"] = nil
local athos = require("prototypes.compat.athos_cycle_guard")

-- Athos is not installed: the guard leaves the graph alone.
rawset(_G, "data", { raw = { technology = {
  ["a"] = { prerequisites = { "b" } },
  ["b"] = { prerequisites = { "a" } }
} } })
check(athos.repair() == 0 and #data.raw.technology["a"].prerequisites == 1,
  "The Athos guard must do nothing without the mod")

rawset(_G, "mods", { nulla = "1.0.2", PlanetAthos = "1.1.3" })
rawset(_G, "data", { raw = { technology = {
  ["athos-particulate"] = { prerequisites = { "engine-building" } },
  ["engine-building"] = { prerequisites = { "athos-particulate" } },
  ["other-a"] = { prerequisites = { "other-b" } },
  ["other-b"] = { prerequisites = { "other-a" } }
} } })
check(athos.find_cycle(data.raw.technology) ~= nil, "Fixture cycle not found")
check(athos.repair("before-athos-data-updates") == 1,
  "The data-stage pass must repair Athos cycles before its data-updates traversal")
check(#data.raw.technology["athos-particulate"].prerequisites == 0, "Cyclic source edge not removed")
check(#data.raw.technology["other-a"].prerequisites == 1 and #data.raw.technology["other-b"].prerequisites == 1,
  "Unrelated dependency cycles must not be silently rewritten")
data.raw.technology["other-b"].prerequisites = {}
check(athos.repair("later-stage") == 0 and athos.find_cycle(data.raw.technology) == nil,
  "Acyclic technology graphs must remain unchanged")

-- The two bootstrap loops of the full pack that exist before Athos's data-updates (both were seen in the log of
-- the pack with Nulla and Athos): only those two edges go, and only with their witnesses in the cycle.
local function pack_graph()
  return {
    ["space-science-pack"] = { prerequisites = { "muluna-alice-propellant" } },
    ["muluna-alice-propellant"] = { prerequisites = { "muluna-aluminum-processing" } },
    ["muluna-aluminum-processing"] = { prerequisites = { "muluna-alumina-processing" } },
    ["muluna-alumina-processing"] = { prerequisites = { "muluna-anorthite-processing" } },
    ["muluna-anorthite-processing"] = { prerequisites = { "planet-discovery-muluna" } },
    ["planet-discovery-muluna"] = { prerequisites = { "thruster-fuel" } },
    ["thruster-fuel"] = { prerequisites = { "thruster-oxidizer" } },
    ["thruster-oxidizer"] = { prerequisites = { "space-platform-thruster" } },
    ["space-platform-thruster"] = { prerequisites = { "space-science-pack", "space-platform" } },
    ["space-platform"] = { prerequisites = {} },
    ["nyxaris-discovery"] = { prerequisites = { "lithium-processing", "planet-discovery-corrundum" } },
    ["lithium-processing"] = { prerequisites = { "planet-discovery-aquilo" } },
    ["planet-discovery-aquilo"] = { prerequisites = { "vibrant-discovery" } },
    ["vibrant-discovery"] = { prerequisites = { "nyxaris-discovery" } },
    ["planet-discovery-corrundum"] = { prerequisites = {} },
    ["unrelated-a"] = { prerequisites = { "unrelated-b" } },
    ["unrelated-b"] = { prerequisites = { "unrelated-a" } }
  }
end
rawset(_G, "data", { raw = { technology = pack_graph() } })
check(athos.repair("before-athos-data-updates") == 2, "Both bootstrap cycles must be repaired before Athos traverses")
---@type table
local technology = data.raw.technology
check(#technology["space-platform-thruster"].prerequisites == 1
  and technology["space-platform-thruster"].prerequisites[1] == "space-platform",
  "The thruster must be researchable without Muluna's Space Science")
check(technology["space-science-pack"].prerequisites[1] == "muluna-alice-propellant",
  "Muluna's original space science role must remain in place")
check(technology["nyxaris-discovery"].prerequisites[1] == "planet-discovery-corrundum",
  "Keep the original Solaris -> Nyxaris gateway intact")
check(technology["lithium-processing"].prerequisites[1] == "planet-discovery-aquilo",
  "Aquilo's original lithium source research must stay untouched")
check(#technology["unrelated-a"].prerequisites == 1 and #technology["unrelated-b"].prerequisites == 1,
  "Never silently delete unrelated mod research")
technology["unrelated-b"].prerequisites = {}
check(athos.find_cycle(technology) == nil and athos.repair("second-pass") == 0,
  "The repaired graph must stay acyclic and the pass idempotent")

-- A cycle through the same edge without its witnesses is somebody else's and stays.
rawset(_G, "data", { raw = { technology = {
  ["space-platform-thruster"] = { prerequisites = { "space-science-pack" } },
  ["space-science-pack"] = { prerequisites = { "space-platform-thruster" } }
} } })
technology = data.raw.technology
check(athos.repair("no-witnesses") == 0 and #technology["space-platform-thruster"].prerequisites == 1,
  "A known edge outside its witness cycle must not be removed")
rawset(_G, "data", nil)
rawset(_G, "mods", nil)
print("Nulla and Athos source shims passed")
