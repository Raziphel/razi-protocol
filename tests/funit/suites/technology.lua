---@diagnostic disable: undefined-field
-- The research the finale needs, read from the technology prototypes of the loaded game.
local optional_worlds = require("__razi-protocol__.prototypes.world.systems.optional_worlds")

-- The end of the campaign: the final technology of the required path (contributing.md, rule 2), the signal that follows it,
-- and the last of the Convergence technologies.
local ends = {optional_worlds.final_technology, "razi-intergalactic-transceiver-signal", "razi-convergence-ignition"}

-- Every technology the ends need, with the ends: { name = true }.
local function needed(starts)
	local seen, queue = {}, {}
	for _, name in ipairs(starts) do
		seen[name] = true
		queue[#queue + 1] = name
	end
	local index = 1
	while queue[index] do
		local technology = prototypes.technology[queue[index]]
		index = index + 1
		for name in pairs(technology and technology.prerequisites or {}) do
			if not seen[name] then
				seen[name] = true
				queue[#queue + 1] = name
			end
		end
	end
	return seen
end

local function sorted(set)
	local names = {}
	for name in pairs(set) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

return function(runner)
	runner.test("every step of the way to the end technologies can be researched", function()
		local path = needed(ends)
		local count, broken = 0, {}
		-- Lignumis disables this technology and enables and researches it by script on the player's first arrival at
		-- another surface (lignumis/scripts/init.lua:88-92).
		local lignumis_red_science = script.active_mods["lignumis"] and "automation-science-pack"
		for _, name in ipairs(sorted(path)) do
			local technology = prototypes.technology[name]
			count = count + 1
			if not technology then
				broken[#broken + 1] = name .. " does not exist"
			elseif not technology.enabled and name ~= lignumis_red_science then
				broken[#broken + 1] = name .. " is disabled"
			elseif technology.hidden then
				broken[#broken + 1] = name .. " is hidden"
			end
		end
		runner.assert(#broken == 0, "on the way to " .. table.concat(ends, ", ") .. ": " .. table.concat(broken, "; "))
		runner.assert(count > 100, "only " .. count .. " technologies on the way: the walk found too little")
	end)

	-- contributing.md, rule 2: the way to the final technology does not run through a world a pack may leave out.
	runner.test("the way to the final technology needs no optional world", function()
		local location_of, pack_of = {}, {}
		for _, world in pairs(optional_worlds.worlds) do
			if script.active_mods[world.mod] then
				for _, location in pairs(world.locations) do location_of[location] = world.mod end
				for _, pack in pairs(world.packs) do pack_of[pack] = world.mod end
			end
		end
		runner.assert(next(location_of) or next(pack_of), "no optional world is installed; the test checks nothing")
		local broken = {}
		for name in pairs(needed({optional_worlds.final_technology})) do
			local technology = prototypes.technology[name]
			for _, effect in pairs(technology.effects) do
				if effect.type == "unlock-space-location" and location_of[effect.space_location] then
					broken[#broken + 1] = name .. " unlocks " .. effect.space_location .. " of " .. location_of[effect.space_location]
				end
			end
			for _, ingredient in pairs(technology.research_unit_ingredients) do
				if pack_of[ingredient.name] then
					broken[#broken + 1] = name .. " takes the " .. ingredient.name .. " of " .. pack_of[ingredient.name]
				end
			end
		end
		table.sort(broken)
		runner.assert(#broken == 0, table.concat(broken, "; "))
	end)
end
