local eneas_gantry = {}

-- Moon Eneas builds its gantry from a deep copy of the base train stop
-- (prototypes/entity/gantry.lua) and keeps the copied next_upgrade. LTN sets
-- train-stop.next_upgrade to logistic-train-stop in its data stage, and without
-- cargo-ships (LTN's only optional dependency) LTN loads before Moon Eneas. The
-- gantry then upgrades to an entity with a different bounding box and the game
-- refuses to load. The gantry has no upgrade of its own.
function eneas_gantry.data_final_fixes()
	if not mods["moon-eneas"] then
		return
	end

	local gantry = data.raw["train-stop"] and data.raw["train-stop"]["gantry"]
	if gantry then
		gantry.next_upgrade = nil
	end
end

return eneas_gantry
