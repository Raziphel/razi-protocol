-- Runtime: enemy expansion builds no vanilla nests on Castra (scripts/compatibility/castra-prime/expansion_nests.lua),
-- on a mocked game.
-- Run from the mod root:
--   lua5.2 tests/lua/test_castra_expansion_nests.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

rawset(_G, "log", function() end)
rawset(_G, "defines", {
	command = {wander = "wander", build_base = "build_base"},
	distraction = {by_anything = "by_anything"}
})
rawset(_G, "storage", {})

local function surface(name)
	return {name = name, entities = {}}
end

local castra = surface("castra")
local nauvis = surface("nauvis")

-- An entity whose methods fail once it is destroyed, as LuaEntity does.
local function entity(on, name, type)
	local object = {name = name, type = type, surface = on, valid = true, commands = {}}
	object.commandable = {
		set_command = function(command)
			check(object.valid, "command for a destroyed " .. name)
			object.commands[#object.commands + 1] = command
		end
	}
	function object.destroy()
		check(object.valid, name .. " destroyed twice")
		object.valid = false
	end
	on.entities[#on.entities + 1] = object
	return object
end

local function group(on, members)
	local object = {surface = on, valid = true, is_unit_group = true, members = members}
	function object.destroy()
		object.valid = false
	end
	return object
end

local expansion = require("scripts.compatibility.castra-prime.expansion_nests")

-- A settler group on Castra is broken up, and its tanks wander again under Castra Prime's own tank loop.
local tank_a = entity(castra, "castra-enemy-tank", "unit")
local tank_b = entity(castra, "castra-enemy-tank", "unit")
local settlers = group(castra, {tank_a, tank_b})
expansion.on_build_base_arrived({group = settlers})
check(not settlers.valid, "the settler group on Castra is still there")
for _, tank in ipairs({tank_a, tank_b}) do
	check(tank.valid, "a tank of the group was destroyed")
	check(#tank.commands == 1 and tank.commands[1].type == "wander", "a tank of the group does not wander")
	check(tank.commands[1].distraction == "by_anything", "a tank of the group ignores enemies")
end

-- A single unit sent to build on Castra wanders too.
local lone = entity(castra, "castra-enemy-tank", "unit")
expansion.on_build_base_arrived({unit = lone})
check(#lone.commands == 1 and lone.commands[1].type == "wander", "a single settler on Castra does not wander")

-- Expansion on other planets is left alone.
local biter = entity(nauvis, "small-biter", "unit")
local nauvis_settlers = group(nauvis, {biter})
expansion.on_build_base_arrived({group = nauvis_settlers})
check(nauvis_settlers.valid, "a settler group on Nauvis was broken up")
check(#biter.commands == 0, "a settler on Nauvis got a command")

-- A base built on Castra all the same is removed; Castra Prime's own spawner and other planets are not touched.
local built = entity(castra, "biter-spawner", "unit-spawner")
expansion.on_biter_base_built({entity = built})
check(not built.valid, "a biter spawner built on Castra stays")
local collector = entity(castra, "data-collector", "unit-spawner")
expansion.on_biter_base_built({entity = collector})
check(collector.valid, "a data collector was removed")
local nauvis_spawner = entity(nauvis, "biter-spawner", "unit-spawner")
expansion.on_biter_base_built({entity = nauvis_spawner})
check(nauvis_spawner.valid, "a biter spawner on Nauvis was removed")

-- Once per save, what earlier expansions left on Castra is removed: spawners, worms and their units, not Castra's own.
castra.entities = {}
local left = {
	entity(castra, "biter-spawner", "unit-spawner"),
	entity(castra, "medium-worm-turret", "turret"),
	entity(castra, "small-biter", "unit")
}
local kept = {
	entity(castra, "data-collector", "unit-spawner"),
	entity(castra, "castra-enemy-tank", "unit"),
	entity(castra, "data-collector-gunpowder", "unit"),
	entity(castra, "gun-turret", "ammo-turret")
}
function castra.find_entities_filtered(filter)
	local types = {}
	for _, type in ipairs(filter.type) do
		types[type] = true
	end
	local found = {}
	for _, object in ipairs(castra.entities) do
		if object.valid and types[object.type] then
			found[#found + 1] = object
		end
	end
	return found
end
rawset(_G, "game", {surfaces = {castra = castra, nauvis = nauvis}})

check(expansion.clear_built_nests() == 3, "not all three expansion entities were counted")
for _, object in ipairs(left) do
	check(not object.valid, object.name .. " left by expansion stays on Castra")
end
for _, object in ipairs(kept) do
	check(object.valid, object.name .. " of Castra Prime was removed")
end
local late = entity(castra, "biter-spawner", "unit-spawner")
check(expansion.clear_built_nests() == 0 and late.valid, "the clean-up ran a second time")

-- A save without Castra marks the clean-up done as well.
rawset(_G, "storage", {})
rawset(_G, "game", {surfaces = {nauvis = nauvis}})
check(expansion.clear_built_nests() == 0, "a save without Castra removed something")
check(storage.castra_expansion_nests_cleared, "a save without Castra keeps the clean-up pending")

print("castra expansion nests: ok")
