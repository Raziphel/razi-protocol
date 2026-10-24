local removed_fuel_category = {}

-- Factorio 2.1.20 removed ItemPrototype::fuel_category; the game now refuses to
-- load an item that still sets it ("fuel_category was removed. Please use
-- fuel_categories"). alchemy-khemia 0.3.6 sets it on kausimatic-crystal,
-- kausimatic-crystal-brine-canister, telepad-fuel and ambrosia, so the whole
-- pack fails to start.
-- Move the old field into the new list on every prototype until the source mods
-- are updated; the category itself is kept as the mod defined it.
function removed_fuel_category.data_final_fixes()
	for prototype_type, prototypes in pairs(data.raw) do
		for name, prototype in pairs(prototypes) do
			---@diagnostic disable-next-line: undefined-field
			local category = type(prototype) == "table" and prototype.fuel_category
			if type(category) == "string" then
				prototype.fuel_categories = prototype.fuel_categories or {category}
				---@diagnostic disable-next-line: inject-field
				prototype.fuel_category = nil
				log("razi-protocol: " .. prototype_type .. " " .. name .. " sets fuel_category, removed in Factorio 2.1.20 (moved to fuel_categories)")
			end
		end
	end
end

return removed_fuel_category
