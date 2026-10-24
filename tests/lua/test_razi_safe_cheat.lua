-- Staged research for /razi-cheat, without a Factorio binary.
-- Run from the mod root: lua5.2 tests/lua/test_razi_safe_cheat.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function key(message)
	-- Command replies are {"razi-cheat.message", {"razi-cheat.<key>", ...}}.
	if type(message) ~= "table" then
		return nil
	end
	if message[1] == "razi-cheat.message" then
		return message[2][1]
	end
	return message[1]
end

local technologies = {
	["science"] = {name = "science", researched = false, valid = true,
		prototype = {enabled = true}, prerequisites = {}},
	["rocket"] = {name = "rocket", researched = false, valid = true,
		prototype = {enabled = true}, prerequisites = {science = true}},
	["network"] = {name = "network", researched = false, valid = true,
		prototype = {enabled = true}, prerequisites = {rocket = true}},
	["hidden"] = {name = "hidden", researched = false, valid = true,
		prototype = {enabled = true, hidden = true}, prerequisites = {}},
	["disabled"] = {name = "disabled", researched = false, valid = true,
		prototype = {enabled = false}, prerequisites = {}},
	["done"] = {name = "done", researched = true, valid = true,
		prototype = {enabled = true}, prerequisites = {}}
}
local force = {name = "player", valid = true, technologies = technologies}
local messages = {}
local logged = {}
local player = {index = 1, valid = true, admin = false, force = force, cheat_mode = false,
	print = function(message) messages[#messages + 1] = message end}
---@type table<string, any>
local state = {}
local world = {tick = 0, forces = {player = force}, get_player = function(index)
	if index == 1 then
		return player
	end
end}
rawset(_G, "storage", state)
rawset(_G, "game", world)
rawset(_G, "log", function(message) logged[#logged + 1] = message end)

local M = require("scripts.razi_safe_cheat")
local function command(parameter)
	M.command({player_index = 1, parameter = parameter})
end

-- Without a listener the module must work on its own.
command("")
check(not state.razi_cheat_jobs and not player.cheat_mode,
	"Non-admin cannot start staged research")
check(key(messages[#messages]) == "razi-cheat.admin-only", "Non-admin should get a localized refusal")
M.command({parameter = ""})
check(key(logged[#logged]) == "razi-cheat.player-only", "The server console should get a log line")

local notified = {}
M.set_research_listener(function(changed)
	notified[changed.name] = (notified[changed.name] or 0) + 1
end)

player.admin = true
command("bogus")
check(key(messages[#messages]) == "razi-cheat.usage" and not state.razi_cheat_jobs,
	"An unknown action should print usage and do nothing")
command("")
local job = assert(state.razi_cheat_jobs and state.razi_cheat_jobs.player, "Admin should start a job")
check(player.cheat_mode and #job.names == 3,
	"Admin should queue exactly the three eligible technologies")
check(job.names[1] == "science" and job.names[2] == "rocket" and job.names[3] == "network",
	"Research must respect prerequisite order")
check(key(messages[#messages]) == "razi-cheat.started" and messages[#messages][2][2] == 3,
	"Start should report the planned count")
command("start")
check(key(messages[#messages]) == "razi-cheat.already-running", "A second start must not queue again")

M.tick()
check(technologies.science.researched and not technologies.rocket.researched,
	"A tick must only research one technology")
command("status")
check(key(messages[#messages]) == "razi-cheat.status" and messages[#messages][2][2] == 1,
	"Status should report the position")
M.tick()
check(technologies.rocket.researched and not technologies.network.researched,
	"A tick must not research the entire tech tree")
command("cancel")
check(not state.razi_cheat_jobs and not technologies.network.researched,
	"Cancel must stop future research without undoing completed techs")
command("cancel")
check(key(messages[#messages]) == "razi-cheat.cancel-idle", "Cancel without a job should say so")

command("start")
check(#state.razi_cheat_jobs.player.names == 1,
	"Resuming should only include the remaining technology")
-- Jobs live in storage; re-requiring the helper does not erase them.
package.loaded["scripts.razi_safe_cheat"] = nil
---@diagnostic disable-next-line: duplicate-require
local resumed = require("scripts.razi_safe_cheat")
resumed.tick()
check(technologies.network.researched and not state.razi_cheat_jobs,
	"Resumed run should complete and clear its saved job")
check(key(messages[#messages]) == "razi-cheat.complete", "Completion should be reported")
check(not technologies.hidden.researched and not technologies.disabled.researched,
	"Research must not grant hidden or source-disabled technologies")
-- The re-required module has no listener: control.lua sets it again on load.
check(notified.player == 5, "The listener should hear start, cancel, restart and every step")

resumed.command({player_index = 1, parameter = "start"})
check(key(messages[#messages]) == "razi-cheat.nothing-left" and not state.razi_cheat_jobs,
	"With nothing left, start should only enable free crafting")

-- A force that disappears (merged or deleted) drops its job.
state.razi_cheat_jobs = {gone = {names = {"x"}, position = 1, completed = 0, failed = 0,
	last_reported = 0, player_index = 1}}
resumed.tick()
check(not state.razi_cheat_jobs, "A job of a missing force should be dropped")

-- The reminder runs once per admin, not once per join or every tick.
local before = #messages
resumed.admin_tip(player)
check(#messages == before + 1 and key(messages[#messages]) == "razi-cheat.admin-tip",
	"Admin should see the safe-cheat tip on first join")
resumed.admin_tip(player)
check(#messages == before + 1, "Admin reminder should appear only once")
local visitor = {index = 2, valid = true, admin = false,
	print = function(_) error("Ordinary players should not receive the admin tip") end}
resumed.admin_tip(visitor)
check(#messages == before + 1, "Non-admin should not receive the tip")

world.tick = 1000
resumed.warn_builtin({command = "CHEAT", parameters = "all", player_index = 1})
check(#messages == before + 2 and key(messages[#messages]) == "razi-cheat.builtin-warning",
	"The native cheat command should get a targeted warning")
resumed.warn_builtin({command = "cheat", parameters = "", player_index = 1})
check(#messages == before + 2, "Repeated cheat use should respect warning cooldown")
world.tick = 1700
resumed.warn_builtin({command = "cheat", parameters = "off", player_index = 1})
resumed.warn_builtin({command = "razi-cheat", parameters = "", player_index = 1})
check(#messages == before + 2, "Cheat off and the safe command must not warn")
resumed.warn_builtin({command = "cheat", parameters = "", player_index = 1})
check(#messages == before + 3, "Warn again after cooldown")

resumed.on_player_removed(1)
check(not state.razi_cheat_tip_seen[1] and not state.razi_cheat_last_warning[1],
	"Deleted players should not leave reminder state behind")
print("razi-cheat: permissions, pacing, cancel, persistence and reminders passed")
