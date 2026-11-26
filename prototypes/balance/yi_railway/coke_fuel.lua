local M = {}

-- Industrial Coks has 35 MJ (yi_railway prototypes/z_items.lua:133-134), and its chemical-plant recipe makes one from
-- four coal in five seconds (yi_railway prototypes/z_recipes.lua:756-766). The pack's 6 MJ Krastorio 2 coal therefore
-- returns 35 MJ from 24 MJ of input in any boiler or furnace. Razi Protocol caps the coke at 20 MJ, the pack's solid-fuel
-- value and below the coal it takes.
local fuel_name = "yir_fuel_coks"
local expected_value = "35MJ"
local balanced_value = "20MJ"

local function note(message)
	if log then
		log("razi-protocol: yi_railway: " .. message)
	end
end

function M.data_final_fixes()
	if not (mods and mods["yi_railway"]) then
		return
	end

	local fuel = data.raw.item and data.raw.item[fuel_name]
	if not fuel then
		return
	end

	if fuel.fuel_value == expected_value then
		fuel.fuel_value = balanced_value
		note(fuel_name .. " fuel_value " .. expected_value .. " -> " .. balanced_value)
	else
		note(fuel_name .. " fuel_value is " .. tostring(fuel.fuel_value) .. ", expected " .. expected_value .. ", left as is")
	end
end

return M
