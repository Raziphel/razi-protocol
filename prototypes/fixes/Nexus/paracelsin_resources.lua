-- Nexus 1.4.0 keeps the old Paracelsin resource keys
-- (Nexus_1.4.0/compatibility/paracelsin/planet_paracelsin_compatibility.lua:60-63,74,76,121-122).
-- Paracelsin 1.11.0 renamed water-cryovolcano to cryovolcanic-vent (migrations/1.11.0.json);
-- Paracelsin 1.13.0 renamed vaterite to calcium-crystals (migrations/1.13.0.json).
-- If Nexus loads after Paracelsin, the planet may point at resource prototypes that no longer exist.
local paracelsin_resources = {}

local RENAMED = {
	{
		entity = "vaterite",
		new_entity = "calcium-crystals",
		control = "vaterite",
		new_control = "calcium_crystals",
	},
	{
		entity = "water-cryovolcano",
		new_entity = "cryovolcanic-vent",
		control = "water_cryovolcano",
		new_control = "cryovolcanic_vent",
	},
}

local function rename_key(container, old_name, new_name, table_name)
	if type(container) ~= "table" or container[old_name] == nil then
		return
	end

	if container[new_name] == nil then
		container[new_name] = container[old_name]
		log("razi-protocol: paracelsin " .. table_name .. ": " .. old_name .. " renamed to " .. new_name)
	else
		log("razi-protocol: paracelsin " .. table_name .. ": " .. old_name .. " removed, "
			.. new_name .. " is already set")
	end
	container[old_name] = nil
end

function paracelsin_resources.data_final_fixes()
	local raw = data and data.raw
	local planet = raw and raw.planet and raw.planet.paracelsin
	local resources = raw and raw.resource
	if not planet or not resources then
		return
	end

	local map_gen_settings = planet.map_gen_settings
	for _, pair in ipairs(RENAMED) do
		if not resources[pair.entity] and resources[pair.new_entity] then
			local autoplace_settings = map_gen_settings and map_gen_settings.autoplace_settings
			local entity_settings = autoplace_settings and autoplace_settings.entity and autoplace_settings.entity.settings
			rename_key(entity_settings, pair.entity, pair.new_entity, "autoplace_settings.entity.settings")

			local property_names = map_gen_settings and map_gen_settings.property_expression_names
			rename_key(property_names, "entity:" .. pair.entity .. ":probability",
				"entity:" .. pair.new_entity .. ":probability", "property_expression_names")
			rename_key(property_names, "entity:" .. pair.entity .. ":richness",
				"entity:" .. pair.new_entity .. ":richness", "property_expression_names")

			local controls = raw["autoplace-control"]
			if controls and controls[pair.new_control] then
				local autoplace_controls = map_gen_settings and map_gen_settings.autoplace_controls
				rename_key(autoplace_controls, pair.control, pair.new_control, "autoplace_controls")
			end
		end
	end
end

return paracelsin_resources
