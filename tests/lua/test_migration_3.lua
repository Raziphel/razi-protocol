-- The 3.0 migration: research a 2.x save has passed, and the route renames.
-- Run from the mod root: lua5.2 tests/lua/test_migration_3.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = {}
rawset(_G, "log", function(message) logged[#logged + 1] = message end)

-- A small galaxy shaped like the real one: two belts, worlds on both sides of each.
local ROUTES = {
	{"nauvis", "sye-calidus"}, {"sye-calidus", "sye-solaris"}, {"sye-calidus", "sye-nyxaris"},
	{"sye-solaris", "sye-vibrant"}, {"sye-nyxaris", "sye-vespera"},
	{"sye-vibrant", "asteroid-belt-outer-edge"}, {"asteroid-belt-outer-edge", "sye-beetlejuice"},
	{"asteroid-belt-outer-edge", "paracelsin"}, {"paracelsin", "shchierbin"},
	{"asteroid-belt-inner-edge", "asteroid-belt-outer-edge"},
	{"ribbonia", "asteroid-belt-inner-edge"}, {"fulgora", "ribbonia"}, {"cerys", "fulgora"},
	{"sye-vespera", "sye-umbra"}, {"sye-beetlejuice", "sye-umbra"},
	-- An island: two places joined to each other and to nothing else.
	{"island-west", "island-east"},
	{"sye-umbra", "razi-umbra-belt-outer"}, {"razi-umbra-belt-inner", "razi-umbra-belt-outer"},
	{"razi-umbra-belt-inner", "tenebris"}, {"tenebris", "crucible"}, {"muria", "sye-vespera"}
}

local function unlock(...)
	local effects = {}
	for _, location in ipairs({...}) do
		effects[#effects + 1] = {type = "unlock-space-location", space_location = location}
	end
	return {effects = effects}
end

local TECHNOLOGIES = {
	["space-discovery-asteroid-belt"] = unlock("asteroid-belt-inner-edge", "asteroid-belt-outer-edge"),
	["razi-umbra-belt-survey"] = unlock("razi-umbra-belt-inner", "razi-umbra-belt-outer"),
	["planet-discovery-ribbonia"] = unlock("ribbonia"),
	["planet-discovery-fulgora"] = unlock("fulgora"),
	["moon-discovery-cerys"] = unlock("cerys"),
	["planet-discovery-paracelsin"] = unlock("paracelsin"),
	["planet-discovery-shchierbin"] = unlock("shchierbin"),
	["planet-discovery-tenebris"] = unlock("tenebris"),
	["planet-discovery-crucible"] = unlock("crucible"),
	-- On the near side of both belts: never a reason to grant a survey.
	["planet-discovery-muria"] = unlock("muria"),
	["island-discovery"] = unlock("island-west", "island-east"),
	["beetlejuice-discovery"] = unlock("sye-beetlejuice"),
	["vespera-discovery"] = unlock("sye-vespera"),
	["umbra-discovery"] = unlock("sye-umbra"),
	["razi-outer-frontier-mastery"] = {effects = {}},
	["razi-singularity-theory"] = {effects = {}},
	["automation"] = {effects = {{type = "unlock-recipe", recipe = "assembling-machine-1"}}}
}

---@param researched string[]|nil
---@return any
local function force_of(name, researched, known)
	local technologies = {}
	for tech in pairs(known or TECHNOLOGIES) do
		technologies[tech] = {name = tech, researched = false}
	end
	for _, tech in ipairs(researched or {}) do
		technologies[tech].researched = true
	end
	return {name = name, technologies = technologies}
end

---@param forces any[]
---@param technologies table|nil
local function world(forces, technologies, locations)
	logged = {}
	local connections, known = {}, {}
	for index, route in ipairs(ROUTES) do
		connections["route-" .. index] = {from = {name = route[1]}, to = {name = route[2]}}
		known[route[1]], known[route[2]] = {}, {}
	end
	local by_name = {}
	for _, force in ipairs(forces) do
		by_name[force.name] = force
	end
	rawset(_G, "game", {forces = by_name})
	rawset(_G, "prototypes", {
		technology = technologies or TECHNOLOGIES,
		space_connection = connections,
		space_location = locations or known
	})
end

local function researched(force, name)
	return force.technologies[name] and force.technologies[name].researched
end

local M = require("scripts.razi_migration_3")

-- The transceiver chain: its new ancestors come with it.
do
	local player = force_of("player", {"automation", "razi-singularity-theory"})
	world({player})
	M.run()
	for _, name in ipairs({"vespera-discovery", "umbra-discovery", "razi-outer-frontier-mastery"}) do
		check(researched(player, name), name .. " granted with the singularity theory")
	end
	check(not researched(player, "space-discovery-asteroid-belt") and not researched(player, "razi-umbra-belt-survey"),
		"no survey without a world behind a belt")
	check(#logged == 1 and logged[1] == "[Razi Protocol/migration] player: vespera-discovery, umbra-discovery, razi-outer-frontier-mastery",
		"one log line per force: " .. tostring(logged[1]))

	-- A second run changes nothing and says nothing.
	world({player})
	M.run()
	check(#logged == 0, "second run is silent")
end

-- Without the singularity theory the three stay as they are.
do
	local player = force_of("player", {"automation", "planet-discovery-muria"})
	world({player})
	M.run()
	check(not researched(player, "vespera-discovery") and not researched(player, "umbra-discovery")
		and not researched(player, "razi-outer-frontier-mastery"), "nothing granted without the singularity theory")
	check(#logged == 0, "nothing granted, nothing logged")
end

-- One already researched ancestor is kept, the rest is granted.
do
	local player = force_of("player", {"razi-singularity-theory", "umbra-discovery"})
	world({player})
	M.run()
	check(researched(player, "vespera-discovery") and researched(player, "razi-outer-frontier-mastery"), "missing ones granted")
	check(logged[1] == "[Razi Protocol/migration] player: vespera-discovery, razi-outer-frontier-mastery",
		"only what was granted is logged: " .. tostring(logged[1]))
end

-- Every world behind the Vibrant belt grants its survey, and only that one.
for _, tech in ipairs({"planet-discovery-ribbonia", "planet-discovery-fulgora", "moon-discovery-cerys",
	"planet-discovery-paracelsin", "planet-discovery-shchierbin"}) do
	local player = force_of("player", {"automation", tech})
	world({player})
	M.run()
	check(researched(player, "space-discovery-asteroid-belt"), tech .. " grants the Vibrant belt survey")
	check(not researched(player, "razi-umbra-belt-survey"), tech .. " does not grant the Umbra belt survey")
	check(logged[1] == "[Razi Protocol/migration] player: space-discovery-asteroid-belt", "log for " .. tech)
end

-- Every world behind the Umbra belt grants its survey, and only that one.
for _, tech in ipairs({"planet-discovery-tenebris", "planet-discovery-crucible"}) do
	local player = force_of("player", {"automation", tech})
	world({player})
	M.run()
	check(researched(player, "razi-umbra-belt-survey"), tech .. " grants the Umbra belt survey")
	check(not researched(player, "space-discovery-asteroid-belt"), tech .. " does not grant the Vibrant belt survey")
end

-- Worlds on the near side of a belt grant nothing, nor do research and a survey already done.
do
	local player = force_of("player", {"automation", "planet-discovery-muria", "beetlejuice-discovery", "vespera-discovery"})
	world({player})
	M.run()
	check(not researched(player, "space-discovery-asteroid-belt") and not researched(player, "razi-umbra-belt-survey"),
		"near-side worlds grant no survey")
	check(#logged == 0, "nothing logged")

	local done = force_of("player", {"space-discovery-asteroid-belt", "planet-discovery-fulgora"})
	world({done})
	M.run()
	check(#logged == 0, "a survey already researched is not granted again")
end

-- A place with no route to the home planet at all is not behind a belt.
do
	local player = force_of("player", {"automation", "island-discovery"})
	world({player})
	M.run()
	check(not researched(player, "space-discovery-asteroid-belt") and not researched(player, "razi-umbra-belt-survey"),
		"an isolated place grants no survey")
	check(#logged == 0, "nothing logged for an isolated place")
end

-- Both belts, the theory and a second force; each force by its own research.
do
	local first = force_of("player", {"automation", "razi-singularity-theory", "planet-discovery-fulgora", "planet-discovery-tenebris"})
	local second = force_of("rabbascans", {"automation", "planet-discovery-paracelsin"})
	world({first, second})
	M.run()
	check(researched(first, "space-discovery-asteroid-belt") and researched(first, "razi-umbra-belt-survey"), "both surveys")
	check(researched(second, "space-discovery-asteroid-belt") and not researched(second, "razi-umbra-belt-survey"),
		"the second force gets its own survey only")
	check(not researched(second, "vespera-discovery"), "the second force has no theory")
	check(#logged == 2, "one line per force")
end

-- Forces with nothing researched, and the enemy and neutral forces, are left alone.
do
	local empty = force_of("rabbascans", {})
	local enemy = force_of("enemy", {"razi-singularity-theory", "planet-discovery-fulgora"})
	local neutral = force_of("neutral", {"razi-singularity-theory"})
	world({empty, enemy, neutral})
	M.run()
	check(not researched(empty, "vespera-discovery") and not researched(empty, "space-discovery-asteroid-belt"), "empty force untouched")
	check(not researched(enemy, "vespera-discovery") and not researched(enemy, "space-discovery-asteroid-belt"), "enemy untouched")
	check(not researched(neutral, "vespera-discovery"), "neutral untouched")
	check(#logged == 0, "nothing logged")
end

-- Missing technologies and locations are tolerated.
do
	local known = {}
	for name, prototype in pairs(TECHNOLOGIES) do
		if name ~= "vespera-discovery" and name ~= "razi-umbra-belt-survey" then
			known[name] = prototype
		end
	end
	local player = force_of("player", {"razi-singularity-theory", "planet-discovery-tenebris", "planet-discovery-fulgora"}, known)
	world({player}, known)
	M.run()
	check(researched(player, "umbra-discovery") and researched(player, "razi-outer-frontier-mastery"), "the existing ones are granted")
	check(researched(player, "space-discovery-asteroid-belt"), "the Vibrant survey does not depend on the Umbra one")
	check(player.technologies["vespera-discovery"] == nil and player.technologies["razi-umbra-belt-survey"] == nil,
		"absent technologies are not invented")

	-- No home planet: no belt can be told, nothing is granted for the surveys.
	local lost = force_of("player", {"planet-discovery-fulgora"})
	world({lost}, nil, {})
	M.run()
	check(not researched(lost, "space-discovery-asteroid-belt"), "no home planet, no survey")
end

-- migrations/3.0.0.json: well formed, and each new name is a route this mod creates.
do
	local function read(path)
		local file = assert(io.open(path, "r"))
		local text = file:read("*a")
		file:close()
		return text
	end
	local json = read("migrations/3.0.0.json")
	local sections = 0
	for kind in json:gmatch('"([%w%-]+)"%s*:%s*%[') do
		sections = sections + 1
		check(kind == "space-connection", "unexpected migration type " .. kind)
	end
	check(sections == 1, "one migration type")

	local reconcile = read("prototypes/system/route_reconcile.lua")
	local authority = read("prototypes/system/route_authority.lua")
	local pairs_found = 0
	for old, new in json:gmatch('%[%s*"([^"]+)"%s*,%s*"([^"]+)"%s*%]') do
		pairs_found = pairs_found + 1
		check(old ~= new, "a rename changes the name: " .. old)
		local from, to = new:match("^razi%-curated%-(.-)%-(.+)$")
		local source = authority
		if not from then
			from, to = new:match("^razi%-(.-)%-(.+)$")
			source = reconcile
		end
		check(from and to, "not a route name this mod creates: " .. new)
		-- The route is listed with these ends in this order, so its position along the route is kept.
		local listed = source:find('{%s*"' .. from .. '"%s*,%s*"' .. to .. '"%s*,') ~= nil
		check(listed, "no route " .. from .. " to " .. to .. " for " .. new)
		check(old == from .. "-" .. to, "the old route had the same ends in the same order: " .. old)
	end
	check(pairs_found == 2, "two renamed routes")
end

print("test_migration_3 ok")
