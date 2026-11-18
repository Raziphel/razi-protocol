---@diagnostic disable: missing-fields, need-check-nil, inject-field, undefined-field
-- A save whose current research is imersite asteroid crushing before Fulgora keeps its progress
-- (scripts/migration/imersite_crushing_gate.lua). Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

rawset(_G, "log", function(_) end)

local migration = require("scripts.migration.imersite_crushing_gate")

local function tech(name, researched, prerequisites)
	return {name = name, researched = researched, saved_progress = 0, prerequisites = prerequisites or {}}
end

-- A force as the game shows it to a migration: the old queue and progress, the new prerequisites.
local function force(queue, progress, fulgora_researched)
	local technologies = {
		["planet-discovery-fulgora"] = tech("planet-discovery-fulgora", fulgora_researched),
		["space-science-pack"] = tech("space-science-pack", true),
		["other"] = tech("other", false),
	}
	technologies["imersite-asteroid-crushing"] = tech("imersite-asteroid-crushing", false, {
		["space-science-pack"] = technologies["space-science-pack"],
		["planet-discovery-fulgora"] = technologies["planet-discovery-fulgora"],
	})
	local f = {name = "player", technologies = technologies, research_progress = progress}
	local function set_queue(names)
		f.research_queue = {}
		for _, name in ipairs(names) do
			f.research_queue[#f.research_queue + 1] = technologies[name]
		end
		f.current_research = f.research_queue[1]
	end
	set_queue(queue)
	-- Like the game: a queue is set by names, and the current research follows its head.
	return setmetatable({}, {
		__index = f,
		__newindex = function(_, key, value)
			check(key == "research_queue", "the migration writes only the queue, not " .. tostring(key))
			set_queue(value)
		end,
	})
end

local function queue_names(f)
	local names = {}
	for _, queued in ipairs(f.research_queue) do
		names[#names + 1] = queued.name
	end
	return table.concat(names, ",")
end

-- Current research before Fulgora: off the queue, progress kept on the technology.
local f = force({"imersite-asteroid-crushing", "other"}, 0.4, false)
rawset(_G, "game", {forces = {player = f}})
migration.run()
check(queue_names(f) == "other", "imersite leaves the queue, the rest stays, got " .. queue_names(f))
check(f.technologies["imersite-asteroid-crushing"].saved_progress == 0.4, "the progress is kept")

-- After Fulgora the research stays where it is.
f = force({"imersite-asteroid-crushing"}, 0.4, true)
rawset(_G, "game", {forces = {player = f}})
migration.run()
check(queue_names(f) == "imersite-asteroid-crushing" and f.technologies["imersite-asteroid-crushing"].saved_progress == 0,
	"after Fulgora nothing changes")

-- Another current research: nothing changes.
f = force({"other", "imersite-asteroid-crushing"}, 0.3, false)
rawset(_G, "game", {forces = {player = f}})
migration.run()
check(queue_names(f) == "other,imersite-asteroid-crushing" and f.technologies["imersite-asteroid-crushing"].saved_progress == 0,
	"a queued but not current research is left to the game")

-- Without Imersite Asteroids the technology is missing: nothing happens.
f = force({"other"}, 0.1, false)
f.technologies["imersite-asteroid-crushing"] = nil
rawset(_G, "game", {forces = {player = f}})
migration.run()
check(queue_names(f) == "other", "a missing technology is skipped")

print("test_imersite_crushing_migration ok")
