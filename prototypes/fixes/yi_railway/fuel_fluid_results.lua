local M = {}

-- YIR 1.4.0 names the heavy-oil and petroleum-gas recipes for u1 and u3 but both make u2
-- (yi_railway prototypes/z_recipes.lua:609, 637). Those fuels cannot be made for the YIR diesel engines until each
-- recipe produces the fuel named by its recipe, when both the recipe and item survive yir_disable_content.
local fuel_names = { "yir_fuel_fluid_u1", "yir_fuel_fluid_u3" }

local function note(message)
	if log then
		log("razi-protocol: yi_railway: " .. message)
	end
end

function M.data_final_fixes()
	if not (mods and mods["yi_railway"]) then
		return
	end

	local recipes = data.raw.recipe or {}
	local items = data.raw.item or {}
	for _, name in ipairs(fuel_names) do
		local recipe = recipes[name]
		if recipe and items[name] then
			local changed = false
			for _, result in pairs(recipe.results or {}) do
				if result.name == "yir_fuel_fluid_u2" then
					result.name = name
					changed = true
				end
			end

			if changed then
				note("recipe " .. name .. " makes " .. name .. ", not yir_fuel_fluid_u2")
			end
		end
	end
end

return M
