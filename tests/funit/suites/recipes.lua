---@diagnostic disable: need-check-nil
-- Recipes that the start of the game must keep closed, and the recipes the difficulty closes.

-- What razi-resource-loops is on each difficulty (lib/difficulty/presets.lua, prototypes/balance/resource_loops.lua):
-- Normal closes the loops that run on the base productivity of a machine, Hard and Nightmare close all of them.
local loops_of = {easy = "open", normal = "closed", hard = "strict", nightmare = "strict"}

return function(runner)
	-- alchemy-khemia writes enabled = true on the recipes that smelt a glyph; they open with glyph-discovery.
	runner.test("the glyph smelting recipes are closed on a new force until glyph-discovery is researched", function()
		local names = {}
		for name in pairs(prototypes.recipe) do
			if name:find("^glyph%-smelt%-") then
				names[#names + 1] = name
			end
		end
		table.sort(names)
		runner.assert(#names > 0, "no glyph smelting recipe found")
		runner.assert(prototypes.technology["glyph-discovery"], "no technology glyph-discovery")

		local open = {}
		for _, name in ipairs(names) do
			if game.players[1].force.recipes[name].enabled then
				open[#open + 1] = name
			end
		end
		runner.assert(#open == 0, "open at the start: " .. table.concat(open, ", "))

		-- a force of its own, so the research does not change the player's
		local force = game.create_force("funit-glyphs")
		for _, name in ipairs(names) do
			runner.assert(not force.recipes[name].enabled, name .. " is open on a new force")
		end
		force.technologies["glyph-discovery"].researched = true
		for _, name in ipairs(names) do
			runner.assert(force.recipes[name].enabled, name .. " stays closed after glyph-discovery")
		end
		game.merge_forces("funit-glyphs", "player")
	end)

	local preset = settings.startup["razi-difficulty-preset"].value
	local level = loops_of[preset]

	runner.test("the difficulty preset is one this test knows", function()
		runner.assert(level, "unknown razi-difficulty-preset " .. tostring(preset))
	end)

	-- Hidden and disabled together: a recipe nobody can craft or unlock.
	local function closed(name)
		local recipe = prototypes.recipe[name]
		runner.assert(recipe, "no recipe " .. name)
		return recipe.hidden and not recipe.enabled and not game.players[1].force.recipes[name].enabled
	end

	-- nulls-k2so-tweaks: matter no longer makes bones from "closed" up; bones still sell for matter.
	runner.test("resource loops (" .. tostring(preset) .. "): matter to bones is " .. (level == "open" and "open" or "closed"), function()
		runner.assert(level, "unknown razi-difficulty-preset " .. tostring(preset))
		runner.assert(closed("kr-matter-to-bones") == (level ~= "open"),
			"kr-matter-to-bones is " .. (closed("kr-matter-to-bones") and "closed" or "open") .. " at " .. level)
		runner.assert(not closed("kr-bones-to-matter"), "kr-bones-to-matter is closed too")
	end)

	-- corrundum: the recrystallization recipes go at "strict" only.
	runner.test("resource loops (" .. tostring(preset) .. "): Corrundum recrystallization is " .. (level == "strict" and "closed" or "open"), function()
		runner.assert(level, "unknown razi-difficulty-preset " .. tostring(preset))
		for _, name in ipairs({"iron-recrystalization", "copper-recrystalization"}) do
			runner.assert(closed(name) == (level == "strict"),
				name .. " is " .. (closed(name) and "closed" or "open") .. " at " .. level)
		end
	end)
end
