---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- /razi-prepare-3 (scripts/razi_prepare_3.lua) on a mocked game: it saves the level, the researched flag and the progress of
-- every infinite technology of every force, next to the laboratories and platforms, in a record dev can read.
-- Run from the mod root:
--   lua5.2 tests/lua/test_prepare_3.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

rawset(_G, "defines", {inventory = {lab_input = 1}})
local logged = {}
rawset(_G, "log", function(text) logged[#logged + 1] = text end)

local INFINITE = 4294967295

local function technology(max_level, level, researched, saved_progress)
	return {prototype = {max_level = max_level}, level = level, researched = researched, saved_progress = saved_progress or 0}
end

---@type table<string, any>
local technologies_of_player

local function world()
	local printed = {}
	local player_force = {
		name = "player",
		research_progress = 0,
		platforms = {},
		technologies = {
			-- infinite: level 9 researched past the new cap, progress saved
			["agriculture-productivity"] = technology(INFINITE, 9, false, 0.25),
			-- infinite and being researched: the progress is in the force
			["asteroid-productivity"] = technology(INFINITE, 4, false, 0),
			-- infinite, never touched
			["axe-mining-speed"] = technology(INFINITE, 1, false),
			-- infinite, already done at its top
			["done-productivity"] = technology(INFINITE, 6, true),
			-- finite
			["steel-processing"] = technology(1, 1, true),
			["mining-productivity-1"] = technology(3, 2, false, 0.5),
		}
	}
	technologies_of_player = player_force.technologies
	player_force.current_research = player_force.technologies["asteroid-productivity"]
	player_force.current_research.name = "asteroid-productivity"
	player_force.research_progress = 0.5
	local second = {
		name = "second",
		platforms = {},
		research_progress = 0,
		technologies = {["agriculture-productivity"] = technology(INFINITE, 3, false)}
	}
	local enemy = {name = "enemy", platforms = {}, technologies = {["agriculture-productivity"] = technology(INFINITE, 1, false)}}
	local admin = {valid = true, admin = true, print = function(message) printed[#printed + 1] = message end}
	local guest = {valid = true, admin = false, print = function(message) printed[#printed + 1] = message end}
	rawset(_G, "game", {
		tick = 77,
		forces = {player = player_force, second = second, enemy = enemy},
		surfaces = {},
		players = {admin, guest},
		get_player = function(index) return index == 1 and admin or guest end,
		print = function(message) printed[#printed + 1] = message end
	})
	rawset(_G, "storage", {})
	logged = {}
	return printed
end

local M = require("scripts.razi_prepare_3")

local function find(records, force, name)
	for _, record in ipairs(records) do
		if record.force == force and record.name == name then
			return record
		end
	end
end

-- an admin gets the record with every infinite technology of every force but the enemy
do
	local printed = world()
	M.command({player_index = 1})
	local data = storage.razi_prepare_3
	check(data and data.version == 1, "the record keeps the version dev reads")
	check(data.labs and #data.labs == 0 and data.platforms and #data.platforms == 0, "labs and platforms still recorded")
	check(data.infinite and data.infinite.version == 1, "the infinite record has its own version")
	local records = data.infinite.technologies
	check(#records == 5, "4 of the player's and 1 of the second force, got " .. #records)

	local agriculture = find(records, "player", "agriculture-productivity")
	check(agriculture and agriculture.level == 9 and agriculture.researched == false and agriculture.progress == 0.25,
		"level and saved progress of a technology not being researched")
	local asteroid = find(records, "player", "asteroid-productivity")
	check(asteroid and asteroid.level == 4 and asteroid.progress == 0.5, "the technology being researched takes the progress of the force")
	local done = find(records, "player", "done-productivity")
	check(done and done.researched == true and done.level == 6 and done.progress == 0, "researched flag kept")
	check(find(records, "player", "axe-mining-speed").level == 1, "untouched technology recorded too")
	check(find(records, "second", "agriculture-productivity").level == 3, "other forces recorded")
	check(not find(records, "player", "steel-processing") and not find(records, "player", "mining-productivity-1"),
		"finite technologies are not recorded")
	check(not find(records, "enemy", "agriculture-productivity"), "the enemy force is not recorded")

	check(printed[1][1] == "razi-prepare-3.summary" and printed[1][5] == 5, "the summary has the number of technologies")
	check(printed[1][2] == 0 and printed[1][3] == 0 and printed[1][4] == 0, "the old summary numbers are in place")
	check(logged[#logged]:find("5 infinite technologies", 1, true), "the log has the number: " .. tostring(logged[#logged]))
end

-- a repeat call rewrites the levels with the current ones and keeps the old record's version
do
	world()
	M.command({player_index = 1})
	technologies_of_player["axe-mining-speed"].level = 7
	M.command({player_index = 1})
	local records = storage.razi_prepare_3.infinite.technologies
	check(#records == 5, "a repeat call does not add records twice")
	check(find(records, "player", "axe-mining-speed").level == 7, "a repeat call takes the new level")
end

-- a guest changes nothing
do
	local printed = world()
	M.command({player_index = 2})
	check(storage.razi_prepare_3 == nil, "a guest saved something")
	check(printed[1][1] == "razi-prepare-3.admin-only", "a guest is told off")
end

-- the console works without a player
do
	world()
	M.command({})
	check(#storage.razi_prepare_3.infinite.technologies == 5, "console run")
end

print("test_prepare_3: ok")
