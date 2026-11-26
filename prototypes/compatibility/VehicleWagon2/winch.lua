local winch = {}

-- Vehicle Wagon 2 4.2.3 gives both winch modes any-entity selection
-- (prototypes/items.lua:30,36). Limit it to the player's force.
function winch.data_final_fixes()
	if not (mods and mods["VehicleWagon2"]) then
		return
	end

	local prototype = data.raw["selection-tool"] and data.raw["selection-tool"]["winch-tool"]
	if not prototype then
		return
	end

	for _, key in ipairs({ "select", "alt_select" }) do
		local selection = prototype[key]
		if selection and selection.mode == "any-entity" then
			selection.mode = { "any-entity", "same-force" }
			log("razi-protocol: VehicleWagon2: the winch selects only vehicles of its own force (" .. key .. ")")
		end
	end
end

return winch
