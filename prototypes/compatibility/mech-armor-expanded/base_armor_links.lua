local M = {}

-- The tiers copy mech-armor in data and define their own grids
-- (mech-armor-expanded/prototypes/armor.lua:3-12, prototypes/equipment-grid.lua:6,12,18).
-- Later grid categories such as Dea Dia's flying (dea-dia-system/prototype/equipment.lua:9-18)
-- and the base armor's corpse picture index are not copied to those tiers.
local tiers = {"mech-armor-mk2", "mech-armor-mk3", "mech-armor-mk4"}

local function note(message)
	if log then
		log("razi-protocol: mech-armor-expanded: " .. message)
	end
end

local function sorted_names(prototypes)
	local names = {}
	for name in pairs(prototypes) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

function M.data_final_fixes()
	if not (mods and mods["mech-armor-expanded"]) then
		return
	end

	local raw = data.raw or {}
	local armors = raw.armor or {}
	local base_armor = armors["mech-armor"]
	if not base_armor then
		return
	end

	local grids = raw["equipment-grid"] or {}
	local base_grid = base_armor.equipment_grid and grids[base_armor.equipment_grid]
	if base_grid then
		for _, tier_name in ipairs(tiers) do
			local armor = armors[tier_name]
			local grid = armor and armor.equipment_grid and grids[armor.equipment_grid]
			if grid then
				local categories = grid.equipment_categories or {}
				local has_category = {}
				for _, category in ipairs(categories) do
					has_category[category] = true
				end

				local added = {}
				for _, category in ipairs(base_grid.equipment_categories or {}) do
					if not has_category[category] then
						has_category[category] = true
						added[#added + 1] = category
					end
				end

				if #added > 0 then
					grid.equipment_categories = categories
					for _, category in ipairs(added) do
						categories[#categories + 1] = category
					end
					note(tier_name .. " grid " .. armor.equipment_grid .. " gets equipment categories " .. table.concat(added, ", "))
				end
			end
		end
	end

	local corpses = raw["character-corpse"] or {}
	for _, corpse_name in ipairs(sorted_names(corpses)) do
		local corpse = corpses[corpse_name]
		local mapping = corpse.armor_picture_mapping
		local base_index = mapping and mapping["mech-armor"]
		if mapping and base_index ~= nil then
			for _, tier_name in ipairs(tiers) do
				if mapping[tier_name] == nil then
					mapping[tier_name] = base_index
					note(corpse_name .. " armor_picture_mapping " .. tier_name .. " = " .. tostring(base_index))
				end
			end
		end
	end
end

return M
