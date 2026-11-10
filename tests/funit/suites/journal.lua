---@diagnostic disable: need-check-nil
-- The Journal and the projects it reports, on the real player of the scenario and the real GUI. The player has no
-- character yet (the freeplay intro runs), which does not matter for a window.
local journal = require("__razi-protocol__.scripts.journal.journal")
local window = require("__razi-protocol__.scripts.journal.window")
-- project_state adds status_for to the table that project_api returns
require("__razi-protocol__.scripts.journal.project_state")
local projects = require("__razi-protocol__.scripts.journal.project_api")
local great_projects = require("__razi-protocol__.scripts.projects.great_projects")

return function(runner)
	-- A mock accepts any caption, style or sprite; the game refuses a wrong one.
	for _, view in ipairs({"quests", "projects", "systems", "archive"}) do
		runner.test("the Journal opens its " .. view .. " view", function()
			local player = game.players[1]
			journal.preferences(player.index).view = view
			window.open(player)
			local frame = player.gui.screen[journal.FRAME]
			if not (frame and frame.valid) then
				runner.assert(false, "no Journal window")
				return
			end
			runner.assert(#frame.children > 0, "the Journal window is empty")
			window.close(player)
		end)
	end

	-- The Cargo Network project draws with the platform fleet and the corridors of the installed mods. The research
	-- that opens it is done for the test; the real window and style names are what is checked.
	runner.test("the Cargo Network project draws its overview", function()
		local player = game.players[1]
		local technology = player.force.technologies["interplanetary-trade-logistics"]
		runner.assert(technology, "no interplanetary-trade-logistics technology")
		local was_researched = technology.researched
		technology.researched = true
		local state = journal.preferences(player.index)
		state.view = "projects"
		state.project = "cargo"
		window.open(player)
		local frame = player.gui.screen[journal.FRAME]
		local drawn = frame and frame.valid and #frame.children > 0
		runner.assert(drawn, "no Journal window")
		runner.assert(state.project == "cargo", "the Journal moved off the cargo project to " .. tostring(state.project))
		local done, total, facts = projects.status_for(player.force, "cargo")
		runner.assert(done <= total and facts.platforms == total, "cargo reports " .. done .. " of " .. total)
		window.close(player)
		technology.researched = was_researched
	end)

	-- The storyline is off in the shipped mod, so the Archive relay prototype does not exist, as in writer mode.
	-- Asking the game for an entity that does not exist is an error (03.11), so the project must not ask.
	runner.test("the Archive Array project reports zero without the relay prototype", function()
		local force = game.players[1].force
		runner.assert(not prototypes.entity["razi-archive-relay"], "the relay prototype exists; this test needs the storyline off")
		runner.assert(not pcall(function() return force.get_entity_count("razi-archive-relay") end),
			"the game accepts a count of an unknown entity; the guard is not needed")
		local built, wanted, sites = projects.status_for(force, "array")
		runner.assert(built == 0 and wanted == 3, "array reports " .. tostring(built) .. " of " .. tostring(wanted))
		runner.assert(type(sites) == "table" and #sites == 0, "array reports sites")
		built, wanted = great_projects.array(force)
		runner.assert(built == 0 and wanted == 3, "great_projects.array reports " .. tostring(built) .. " of " .. tostring(wanted))
	end)
end
