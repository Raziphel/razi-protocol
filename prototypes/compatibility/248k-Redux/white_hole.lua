local M = {}

-- The furnace selects an enabled category recipe by input; 248k generates a
-- recipe that doubles every stackable item (248k-Redux/scripts/gravitation/gr_make_white_hole_recipes.lua:5-31).
-- Saves that already had 248k have these recipes disabled for each force on load; no migration is needed.
-- Disabled recipes need an unlock to run. The furnace and separate gr_white recipe remain available
-- (248k-Redux/prototypes/gravitation/gr_white_hole.lua:24-40; 248k-Redux/prototypes/gr_recipes.lua:574-588).
local recipe_prefix = "gr_white_hole_cycle_"

local function note(message)
	if log then
		log("razi-protocol: 248k: " .. message)
	end
end

local function has_recipe_prefix(name)
	return name:sub(1, #recipe_prefix) == recipe_prefix
end

function M.data_final_fixes()
	if not (mods and mods["248k-Redux"]) then
		return
	end

	local disabled = 0
	for name, recipe in pairs(data.raw.recipe or {}) do
		if has_recipe_prefix(name) then
			recipe.enabled = false
			recipe.hidden = true
			disabled = disabled + 1
		end
	end

	local removed_unlocks = 0
	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and has_recipe_prefix(effect.recipe or "") then
				table.remove(effects, index)
				removed_unlocks = removed_unlocks + 1
			end
		end
	end

	note("disabled " .. disabled .. " white-hole cycle recipes and removed " .. removed_unlocks .. " unlocks")
end

return M
