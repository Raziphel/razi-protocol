---@diagnostic disable: missing-fields
-- The list of worlds and packs the required path must not depend on (prototypes/system/optional_worlds.lua): well
-- formed, plain data with a reason for every entry, and every mod in it is a dependency in info.json. The worlds that
-- are woven into the path (regional_research_bridges.lua) are not in it, apart from their packs. The path itself is checked on the real prototypes of the full
-- pack by the in-game tests of my-razi-fixes (tests/data_raw.lua).
-- Run from the mod root:
--   lua5.2 tests/lua/test_optional_worlds.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

-- no data, mods or settings: the in-game tests load the list from the control stage
rawset(_G, "data", nil)
rawset(_G, "mods", nil)
local roster = require("prototypes.system.optional_worlds")

local info = assert(io.open("info.json", "r")):read("*a")
local dependencies = {}
for entry in info:match('"dependencies"%s*:%s*(%b[])'):gmatch('"([^"]+)"') do
	local name = entry:gsub("^[%?%+!~%(%)]+%s*", ""):match("^(%S+)")
	dependencies[name] = entry
end

check(roster.final_technology == "razi-stable-intergalactic-singularity", "the final technology changed")
check(#roster.worlds >= 6, "the list lost worlds")

local seen = {}
for _, world in ipairs(roster.worlds) do
	check(type(world.mod) == "string" and not seen[world.mod], "every world has its own mod: " .. tostring(world.mod))
	seen[world.mod] = true
	check(dependencies[world.mod], world.mod .. " is not a dependency in info.json")
	check(type(world.locations) == "table", world.mod .. " has no locations table")
	check(type(world.packs) == "table", world.mod .. " has no packs table")
	check(#world.locations + #world.packs > 0, world.mod .. " keeps nothing off the path")
	check(type(world.reason) == "string" and #world.reason > 0, world.mod .. " names no reason")
end

-- the worlds that stay off the path: their discovery is excluded from the weave
local excluded = {}
for _, world in ipairs(roster.worlds) do
	for _, location in ipairs(world.locations) do
		excluded[location] = world.mod
	end
end
for location, mod in pairs({["rabbasca-underground"] = "rabbasca-underground",
	skewer_shattered_planet = "skewer_shattered_planet", skewer_lost_beyond = "skewer_shattered_planet",
	["bm-balack"] = "biological-machines-planet-balack", eneas = "moon-eneas", nexus = "Nexus-Updated"}) do
	check(excluded[location] == mod, location .. " must stay off the path")
end
-- Rabbasca is woven: only its packs stay out
for _, mod in ipairs({"planet-rabbasca"}) do
	for _, world in ipairs(roster.worlds) do
		if world.mod == mod then
			check(#world.locations == 0 and #world.packs > 0, mod .. " is woven: no location, but its packs stay out")
		end
	end
end

-- the optional dependencies that add a world (Rabbasca, Rabbasca Underground, Skewer, Eneas) are all in the list
for _, mod in ipairs({"planet-rabbasca", "rabbasca-underground", "skewer_shattered_planet", "moon-eneas"}) do
	check(seen[mod], mod .. " is missing from the list")
	check(dependencies[mod]:match("^[%?%+]"), mod .. " is no longer an optional dependency")
end
-- Ferrum stays optional, but once installed it is woven and the path may need its pack
check(dependencies["planet-ferrum"]:match("^[%?%+]"), "planet-ferrum is no longer an optional dependency")
check(not seen["planet-ferrum"], "Ferrum and its pack are on the path and stay out of the list")
check(dependencies["Nexus-Updated"] == "Nexus-Updated >= 1.4.1", "Nexus-Updated must be a required dependency")
check(dependencies["nexus-bosses"] == "~ nexus-bosses >= 2.4.0",
	"`nexus-bosses` is required without a load order (`~`)")
-- Secretas is required and on the path to the final technology
check(not seen["secretas"], "Secretas is a required dependency and stays out of the list")

print("test_optional_worlds: ok")
