local vehicle_wagon_copy = {}

-- Tenebris Prime 1.3.22 copies each cargo wagon except wagons with void energy
-- (prototypes/bioluminescent.lua:64-67,224). Its copy of Vehicle Wagon 2's wagon
-- has no slots and VW2 cannot use it: it finds empty wagons by the exact name
-- "vehicle-wagon" (VehicleWagon2/script/OnPlayerSelectedArea.lua:44).
function vehicle_wagon_copy.data_final_fixes()
	if not (mods and mods["VehicleWagon2"]) then
		return
	end

	local recipe = data.raw.recipe and data.raw.recipe["bioluminescent-vehicle-wagon"]
	if not recipe then
		return
	end

	if not recipe.hidden then
		recipe.hidden = true
		recipe.enabled = false
		log("razi-protocol: bioluminescent-vehicle-wagon can no longer be made: Vehicle Wagon 2 does not load the copy")
	end

	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and effect.recipe == "bioluminescent-vehicle-wagon" then
				table.remove(effects, index)
			end
		end
	end
end

return vehicle_wagon_copy
