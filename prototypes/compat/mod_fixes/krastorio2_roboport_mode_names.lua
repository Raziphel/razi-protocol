local roboport_mode_names = {}

-- Krastorio 2 makes a logistic and a construction mode of every roboport (prototypes/updates/
-- generate-roboport-variations.lua:15-44) and names them by the locale keys of the roboport: entity-name.<roboport>
-- and entity-description.<roboport>. A roboport named by its localised_name has no such keys, so its modes read
-- "Logistic mode: Unknown key: entity-name.bioluminescent-roboport". Hit: the nine bioluminescent roboports of Tenebris
-- Prime. A roboport without a description key gave its modes an unknown description too: the big roboport of Krastorio 2
-- (its own description is {"?", <that key>, ""}), the engineer roboport, the Arig roboport, the robowasp port, the enemy
-- roboport of Castra and the bioluminescent ones.
--
-- The modes take the name of the roboport as it is shown. The description falls back to nothing when the roboport has
-- no description key either, as the roboport itself does.

-- True for the {key, {sub_key}} the generator wrote.
local function is_generated_name(value, mode, name)
	return type(value) == "table"
		and value[1] == "entity-name.kr-" .. mode .. "-roboport"
		and type(value[2]) == "table"
		and value[2][1] == "entity-name." .. name
		and value[2][2] == nil
		and value[3] == nil
end

local function is_generated_description(value, name)
	return type(value) == "table" and value[1] == "entity-description." .. name and value[2] == nil
end

function roboport_mode_names.data_final_fixes()
	local roboports = data.raw.roboport or {}
	for name, roboport in pairs(roboports) do
		for _, mode in ipairs({"logistic", "construction"}) do
			local variant_name = name .. "-" .. mode .. "-mode"
			local variant = roboports[variant_name]
			if variant then
				local changed = false
				if roboport.localised_name and is_generated_name(variant.localised_name, mode, name) then
					variant.localised_name = {"entity-name.kr-" .. mode .. "-roboport", roboport.localised_name}
					changed = true
				end
				if is_generated_description(variant.localised_description, name) then
					variant.localised_description = roboport.localised_description
						or {"?", {"entity-description." .. name}, ""}
					changed = true
				end
				if changed then
					log("razi-protocol: roboport " .. variant_name .. " takes the shown name and description of " .. name)
				end
			end
		end
	end
end

return roboport_mode_names
