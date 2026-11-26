local M = {}

-- Mech Armor Expanded gives the tiers 160/180/200 grid cells and resistance values up to 95 percent
-- (mech-armor-expanded/prototypes/equipment-grid.lua:6-18, prototypes/armor.lua:8-65).
-- Razi places them at 140/160/180 cells with an 80 percent / 60 decrease ceiling and a mech-armor floor;
-- this also carries Krastorio 2 Spaced Out radiation added after the armor copy
-- (Krastorio2-spaced-out/prototypes/updates/base/items.lua:5-8).
local tiers = {
	{ name = "mech-armor-mk2", width = 10, height = 14, inventory = 60 },
	{ name = "mech-armor-mk3", width = 10, height = 16, inventory = 80 },
	{ name = "mech-armor-mk4", width = 10, height = 18, inventory = 100 },
}

local function note(message)
	if log then
		log("razi-protocol: mech-armor-expanded: " .. message)
	end
end

local function display(value)
	return value == nil and "—" or tostring(value)
end

local function resistance_value(resistance)
	if not resistance then
		return "none"
	end
	return display(resistance.decrease) .. "/" .. display(resistance.percent)
end

local function copy_resistance(resistance)
	local copy = {}
	for key, value in pairs(resistance) do
		copy[key] = value
	end
	return copy
end

local function max_field(current, base, field)
	local current_value = current[field]
	local base_value = base[field]
	if current_value == nil and base_value == nil then
		return nil
	end
	return math.max(current_value or 0, base_value or 0)
end

local function balance_resistances(armor, base_armor, tier_name, raw)
	local resistances = {}
	local by_type = {}
	local original_by_type = {}
	for _, resistance in ipairs(armor.resistances or {}) do
		local copy = copy_resistance(resistance)
		resistances[#resistances + 1] = copy
		by_type[copy.type] = #resistances
		if not original_by_type[copy.type] then
			original_by_type[copy.type] = copy_resistance(resistance)
		end
	end

	for _, resistance in ipairs(resistances) do
		if resistance.percent and resistance.percent > 80 then
			resistance.percent = 80
		end
		if resistance.decrease and resistance.decrease > 60 then
			resistance.decrease = 60
		end
	end

	for _, base_resistance in ipairs(base_armor and base_armor.resistances or {}) do
		local index = by_type[base_resistance.type]
		if index then
			local resistance = resistances[index]
			resistance.decrease = max_field(resistance, base_resistance, "decrease")
			resistance.percent = max_field(resistance, base_resistance, "percent")
		else
			local copy = copy_resistance(base_resistance)
			resistances[#resistances + 1] = copy
			by_type[copy.type] = #resistances
		end
	end

	local damage_types = raw["damage-type"] or {}
	local poison_index = by_type.poison
	if damage_types.toxic and poison_index then
		local toxic = copy_resistance(resistances[poison_index])
		toxic.type = "toxic"
		local toxic_index = by_type.toxic
		if toxic_index then
			resistances[toxic_index] = toxic
		else
			resistances[#resistances + 1] = toxic
			by_type.toxic = #resistances
		end
	end

	for _, resistance in ipairs(resistances) do
		local previous = original_by_type[resistance.type]
		local old_value = resistance_value(previous)
		local new_value = resistance_value(resistance)
		if old_value ~= new_value then
			note(tier_name .. " resistance " .. resistance.type .. " " .. old_value .. " -> " .. new_value)
		end
	end

	armor.resistances = resistances
end

function M.data_final_fixes()
	if not (mods and mods["mech-armor-expanded"]) then
		return
	end

	local raw = data.raw or {}
	local armors = raw.armor or {}
	local base_armor = armors["mech-armor"]
	local grids = raw["equipment-grid"] or {}

	for _, tier in ipairs(tiers) do
		local armor = armors[tier.name]
		if armor then
			local grid = armor.equipment_grid and grids[armor.equipment_grid]
			if grid then
				local old_size = tostring(grid.width) .. "x" .. tostring(grid.height)
				if grid.width ~= tier.width or grid.height ~= tier.height then
					grid.width = tier.width
					grid.height = tier.height
					note(tier.name .. " grid " .. old_size .. " -> " .. tier.width .. "x" .. tier.height)
				end
			end

			if armor.inventory_size_bonus ~= tier.inventory then
				local old_inventory = tostring(armor.inventory_size_bonus)
				armor.inventory_size_bonus = tier.inventory
				note(tier.name .. " inventory_size_bonus " .. old_inventory .. " -> " .. tier.inventory)
			end

			balance_resistances(armor, base_armor, tier.name, raw)
		end
	end
end

return M
