local vehicle_variant_items = {}

-- PlanetsLib gives an entity replacement placeable_by only when an item named
-- after the replacement exists (PlanetsLib/lib/add-entity-replacement.lua:87-89,109-111).
-- The Muluna boat is placed by the item "boat", so its variant otherwise has no item.
local item_types = {
	"item",
	"ammo",
	"armor",
	"capsule",
	"gun",
	"module",
	"tool",
	"repair-tool",
	"item-with-entity-data",
	"item-with-inventory",
	"item-with-label",
	"item-with-tags",
	"rail-planner",
	"spidertron-remote",
	"selection-tool",
	"blueprint",
	"blueprint-book",
	"copy-paste-tool",
	"deconstruction-item",
	"upgrade-item",
	"space-platform-starter-pack",
}

local function has_placeable_by(prototype)
	local placeable_by = prototype.placeable_by
	if type(placeable_by) ~= "table" then
		return false
	end
	if placeable_by.item then
		return true
	end
	for _, entry in ipairs(placeable_by) do
		if type(entry) == "table" and entry.item then
			return true
		end
	end
	return false
end

local function place_results()
	local result = {}
	for _, type_name in ipairs(item_types) do
		for _, item in pairs(data.raw[type_name] or {}) do
			if type(item.place_result) == "string" then
				result[item.place_result] = true
			end
		end
	end
	return result
end

local function item_for_base(base_name, base)
	for _, type_name in ipairs(item_types) do
		local names = {}
		for name in pairs(data.raw[type_name] or {}) do
			names[#names + 1] = name
		end
		table.sort(names)
		for _, name in ipairs(names) do
			local item = data.raw[type_name][name]
			if item.place_result == base_name then
				return name
			end
		end
	end

	if has_placeable_by(base) then
		local placeable_by = base.placeable_by
		if placeable_by.item then
			return placeable_by.item
		end
		for _, entry in ipairs(placeable_by) do
			if type(entry) == "table" and entry.item then
				return entry.item
			end
		end
	end

	return nil
end

function vehicle_variant_items.data_final_fixes()
	local place_results_by_entity = place_results()
	for _, type_name in ipairs({ "car", "spider-vehicle" }) do
		for name, variant in pairs(data.raw[type_name] or {}) do
			local base_name = name:match("^(.+)%-PlanetsLib%-[^-]+$")
			if base_name and not variant.placeable_by and not place_results_by_entity[name] then
				local base = (data.raw.car and data.raw.car[base_name])
					or (data.raw["spider-vehicle"] and data.raw["spider-vehicle"][base_name])
				local item = base and item_for_base(base_name, base)
				if item then
					variant.placeable_by = { { item = item, count = 1 } }
					log("razi-protocol: " .. name .. " is placed by " .. item .. ", as " .. base_name .. " is")
				end
			end
		end
	end
end

return vehicle_variant_items
