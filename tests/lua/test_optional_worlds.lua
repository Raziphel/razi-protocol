---@diagnostic disable: missing-fields
-- The list of worlds the required path must not depend on (prototypes/system/optional_worlds.lua): well formed, plain
-- data, and every mod in it is a dependency in info.json. The path itself is checked on the real prototypes of the full
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
check(#roster.worlds >= 5, "the list lost worlds")

local seen = {}
for _, world in ipairs(roster.worlds) do
	check(type(world.mod) == "string" and not seen[world.mod], "every world has its own mod: " .. tostring(world.mod))
	seen[world.mod] = true
	check(dependencies[world.mod], world.mod .. " is not a dependency in info.json")
	check(type(world.locations) == "table" and #world.locations > 0, world.mod .. " names no location")
	check(type(world.packs) == "table", world.mod .. " has no packs table")
end

-- the optional dependencies that add a world (Ferrum, Rabbasca, Rabbasca Underground, Skewer) are all in the list
for _, mod in ipairs({"planet-ferrum", "planet-rabbasca", "rabbasca-underground", "skewer_shattered_planet"}) do
	check(seen[mod], mod .. " is missing from the list")
	check(dependencies[mod]:match("^[%?%+]"), mod .. " is no longer an optional dependency")
end
-- Secretas is required and on the path to the final technology
check(not seen["secretas"], "Secretas is a required dependency and stays out of the list")

print("test_optional_worlds: ok")
