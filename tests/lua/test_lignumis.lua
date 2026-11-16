---@diagnostic disable: missing-fields
-- Lignumis is an optional start: the player picks it by enabling the mod, and without it the game starts on Nauvis as
-- before. It is an optional dependency (never required or auto-enabled), Lignumis CF stays incompatible (it forces
-- lignumis-technology-progression, which adds the wood and steam packs to every later research), and the moon belongs
-- to Calidus next to Nauvis: in the world roster, the Atlas groups and the route membership, and its discovery is shown
-- with the essential research.
-- Run from the mod root:
--   lua5.2 tests/lua/test_lignumis.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local info = assert(io.open("info.json", "r")):read("*a")
local dependencies = {}
for entry in info:match('"dependencies"%s*:%s*(%b[])'):gmatch('"([^"]+)"') do
	local prefix, name = entry:match("^([%?%+!~%(%)]*)%s*(%S+)")
	dependencies[name] = prefix
end
check(dependencies["lignumis"] == "?", "lignumis must be an optional dependency (?), got " .. tostring(dependencies["lignumis"]))
check(dependencies["lignumis-cf"] == "!", "lignumis-cf must stay incompatible")

local roster = require("prototypes.world.systems.world_roster")
local in_calidus = false
for _, world in ipairs(roster.systems.calidus) do
	if world == "lignumis" then
		in_calidus = true
	end
end
check(in_calidus, "Lignumis must be a Calidus world in the roster")
for system, worlds in pairs(roster.systems) do
	if system ~= "calidus" then
		for _, world in ipairs(worlds) do
			check(world ~= "lignumis", "Lignumis is listed in " .. system)
		end
	end
end

local optional = require("prototypes.world.systems.optional_worlds")
for _, world in ipairs(optional.worlds) do
	check(world.mod ~= "lignumis", "Lignumis is a Calidus world, not one kept off the path")
end

local catalog = require("lib.galactic_catalog")
check(catalog.system("lignumis") == "calidus", "the Atlas puts Lignumis outside Calidus: " .. catalog.system("lignumis"))

-- route membership: the native Nauvis moon route is a local Calidus route
rawset(_G, "data", {raw = {}})
local stub = setmetatable({}, {__index = function()
	return function() end
end})
package.loaded["prototypes.world.asteroids.asteroid_profiles"] = stub
package.loaded["prototypes.world.routes.route_icons"] = stub
package.loaded["prototypes.world.starmap.galaxy_layout"] = stub
local reconcile = require("prototypes.world.routes.route_reconcile")
check(reconcile.membership.lignumis == "calidus", "route membership puts Lignumis outside Calidus")
check(reconcile.membership.lignumis == reconcile.membership.nauvis, "Lignumis and Nauvis must share a system")

-- the discovery of the moon (a new game starts with it researched, an older save researches it) is essential research
local visibility = require("prototypes.ui.tech_tree_visibility")
local techs = {
	["planet-discovery-lignumis"] = {effects = {{type = "unlock-space-location", space_location = "lignumis"}}},
}
rawset(_G, "data", {raw = {technology = techs}})
visibility.data_final_fixes()
check(techs["planet-discovery-lignumis"].essential, "the Lignumis discovery is not shown with the essential research")

print("test_lignumis: ok")
