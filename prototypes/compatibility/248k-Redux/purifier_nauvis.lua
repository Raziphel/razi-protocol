local M = {}

-- The el_purify_stone* recipes process stone and water into metals; equivalent
-- stone-to-metal recipes from other mods are already bound to their planet
-- (248k-Redux/prototypes/el_recipes.lua:1097-1112,1126-1135,1210-1218).
local function note(message)
	if log then
		log("razi-protocol: 248k: " .. message)
	end
end

local function has_purifier_category(machine)
	for _, category in ipairs(machine.crafting_categories or {}) do
		if category == "el_purifier_category" then
			return true
		end
	end

	return false
end

local function has_planet_condition(machine)
	for _, condition in pairs(machine.surface_conditions or {}) do
		if condition.property == "planet-str" then
			return true
		end
	end

	return false
end

function M.data_final_fixes()
	if not (mods and mods["248k-Redux"]) then
		return
	end

	local nauvis = (data.raw.planet or {}).nauvis
	local planet_str = nauvis and nauvis.surface_properties and nauvis.surface_properties["planet-str"]
	if planet_str == nil then
		note("purifiers left as is, Nauvis has no planet-str")
		return
	end

	for name, machine in pairs(data.raw["assembling-machine"] or {}) do
		if has_purifier_category(machine) and not has_planet_condition(machine) then
			machine.surface_conditions = machine.surface_conditions or {}
			machine.surface_conditions[#machine.surface_conditions + 1] = {
				property = "planet-str",
				min = planet_str,
				max = planet_str,
			}
			note(name .. " restricted to Nauvis")
		end
	end
end

return M
