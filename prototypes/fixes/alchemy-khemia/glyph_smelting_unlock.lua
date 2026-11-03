local glyph_smelting_unlock = {}

-- Khemia writes enabled = true on the recipes that smelt a glyph into slag, so all of them stand in the recipe list of a
-- furnace from the first minute of the game (prototypes/recipes/smelting-recipes.lua). They open with the glyphs.
function glyph_smelting_unlock.data_final_fixes()
	local technology = data.raw.technology and data.raw.technology["glyph-discovery"]
	if not technology then
		return
	end
	local names = {}
	for name, recipe in pairs(data.raw.recipe or {}) do
		if name:find("^glyph%-smelt%-") and recipe.enabled == true then
			names[#names + 1] = name
		end
	end
	table.sort(names)
	technology.effects = technology.effects or {}
	for _, name in ipairs(names) do
		data.raw.recipe[name].enabled = false
		technology.effects[#technology.effects + 1] = {type = "unlock-recipe", recipe = name}
		log("razi-protocol: " .. name .. " opens with glyph-discovery instead of the start of the game")
	end
end

return glyph_smelting_unlock
