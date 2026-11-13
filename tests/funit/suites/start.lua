---@diagnostic disable: need-check-nil, param-type-mismatch
-- What a new map looks like before anything is played.
-- Lignumis starts the game on its moon: surface "lignumis", "planet-discovery-lignumis" researched
-- (lignumis/scripts/init.lua).
local LIGNUMIS = "lignumis"

return function(runner)
	runner.test("a new map has Nauvis and no other surface", function()
		local names = {}
		local has_lignumis = script.active_mods[LIGNUMIS] ~= nil
		local allowed_surfaces = {nauvis = true}
		if has_lignumis then allowed_surfaces[LIGNUMIS] = true end
		local unexpected_surface = false
		for name in pairs(game.surfaces) do
			names[#names + 1] = name
			if not allowed_surfaces[name] then unexpected_surface = true end
		end
		runner.assert(game.surfaces["nauvis"], "no surface nauvis")
		-- Other than Nauvis and Lignumis' starting moon, worlds get their surface when first reached.
		local only_expected = #names == (has_lignumis and 2 or 1) and not unexpected_surface
		runner.assert(only_expected, "a new map has more than Nauvis: " .. table.concat(names, ", "))
		runner.assert(game.planets["nauvis"].surface == game.surfaces["nauvis"], "the planet nauvis has another surface")
	end)

	runner.test("a new map has one player and no research done", function()
		runner.assert(#game.players == 1, "players: " .. #game.players)
		local force = game.players[1].force
		runner.assert(force.name == "player", "the player is in force " .. force.name)
		local done = {}
		for name, technology in pairs(force.technologies) do
			if technology.researched and not (script.active_mods[LIGNUMIS] and name == "planet-discovery-lignumis") then
				done[#done + 1] = name
			end
		end
		table.sort(done)
		runner.assert(#done == 0, "researched at the start: " .. table.concat(done, ", "))
		runner.assert(#force.research_queue == 0, "the research queue is not empty")
		-- The Journal's first page needs the opening technology to exist, and the finale must not be open already.
		runner.assert(force.technologies["automation"], "no technology automation")
		for _, name in ipairs({"razi-stable-intergalactic-singularity", "razi-intergalactic-transceiver-signal"}) do
			runner.assert(force.technologies[name], "no technology " .. name)
			runner.assert(not force.technologies[name].researched, name .. " is researched at the start")
		end
	end)
end
