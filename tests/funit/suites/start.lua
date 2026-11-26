---@diagnostic disable: need-check-nil, param-type-mismatch
-- What a new map looks like before anything is played.
-- Lignumis starts the game on its moon: surface "lignumis", "planet-discovery-lignumis" researched
-- (lignumis/scripts/init.lua).
local LIGNUMIS = "lignumis"
-- Recommended mods that keep a service surface of their own from on_init: AAI Signal Transmission a 1x1 "aai-signals"
-- (aai-signal-transmission/control.lua:447), the Krastorio 2 air purifier helper a lab-tile surface of its planet
-- (kr-air-purifier-helper-updated/control.lua:48).
local SERVICE_SURFACES = {
	["aai-signal-transmission"] = "aai-signals",
	["kr-air-purifier-helper-updated"] = "kr-air-purifier-helper-updated",
}
-- Even Distribution Fork researches its hidden "enable-logistics-tab" so the logistics tab shows before logistic
-- robots (even-distribution-fork/scripts/setup.lua:323-327).
local SERVICE_RESEARCH = {
	["enable-logistics-tab"] = "even-distribution-fork",
}

return function(runner)
	runner.test("a new map has Nauvis and no other surface", function()
		local names = {}
		local has_lignumis = script.active_mods[LIGNUMIS] ~= nil
		local allowed_surfaces = {nauvis = true}
		if has_lignumis then allowed_surfaces[LIGNUMIS] = true end
		for mod_name, surface_name in pairs(SERVICE_SURFACES) do
			if script.active_mods[mod_name] then allowed_surfaces[surface_name] = true end
		end
		local unexpected_surface = false
		for name in pairs(game.surfaces) do
			names[#names + 1] = name
			if not allowed_surfaces[name] then unexpected_surface = true end
		end
		runner.assert(game.surfaces["nauvis"], "no surface nauvis")
		-- Other than Nauvis, Lignumis' starting moon and the service surfaces, worlds get their surface when first reached.
		local only_expected = not unexpected_surface
		runner.assert(only_expected, "a new map has more than Nauvis: " .. table.concat(names, ", "))
		runner.assert(game.planets["nauvis"].surface == game.surfaces["nauvis"], "the planet nauvis has another surface")
	end)

	runner.test("a new map has one player and no research done", function()
		runner.assert(#game.players == 1, "players: " .. #game.players)
		local force = game.players[1].force
		runner.assert(force.name == "player", "the player is in force " .. force.name)
		local done = {}
		for name, technology in pairs(force.technologies) do
			local service_mod = SERVICE_RESEARCH[name]
			if technology.researched and not (script.active_mods[LIGNUMIS] and name == "planet-discovery-lignumis")
				and not (service_mod and script.active_mods[service_mod]) then
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
