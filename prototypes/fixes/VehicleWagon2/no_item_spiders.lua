local no_item_spiders = {}

-- Vehicle Wagon 2 4.2.3 adds every car and spider-vehicle below its weight limit to
-- its loading map (script/makeGlobalMaps.lua:32,57). Loading a vehicle without an
-- item crashes when getVehicleItem reads minable_properties
-- (script/getVehicleItem.lua:19, called by script/loadVehicleWagon.lua:108). A
-- spider above the limit is left out of the map; its weight does not affect its movement.
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

function no_item_spiders.data_final_fixes()
	if not (mods and mods["VehicleWagon2"] and settings and settings.startup
		and settings.startup["vehicle-wagon-maximum-weight"]) then
		return
	end

	local limit = settings.startup["vehicle-wagon-maximum-weight"].value
	if limit >= 1e30 then
		log("razi-protocol: VehicleWagon2: the maximum vehicle weight is unlimited, vehicles without an item are left as they are")
		return
	end

	local place_results = {}
	for _, type_name in ipairs(item_types) do
		for _, item in pairs(data.raw[type_name] or {}) do
			if type(item.place_result) == "string" then
				place_results[item.place_result] = true
			end
		end
	end

	for name, spider in pairs(data.raw["spider-vehicle"] or {}) do
		if not place_results[name] and not has_placeable_by(spider) and (spider.weight or 1) <= limit then
			spider.weight = limit + 1
			log("razi-protocol: VehicleWagon2: " .. name .. " has no item and weighs " .. (limit + 1)
				.. ", above the wagon limit")
		end
	end
end

return no_item_spiders
