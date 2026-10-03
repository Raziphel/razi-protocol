local logistics_cleanup = {}

local group_name = "razi-infrastructure"

local subgroup_definitions = {
	{name = "razi-infrastructure-vehicles", order = "a[vehicles]"},
	{name = "razi-infrastructure-rail", order = "b[rail]"},
	{name = "razi-infrastructure-power", order = "c[power]"},
	{name = "razi-infrastructure-surfaces", order = "d[surfaces]"},
	{name = "razi-infrastructure-misc", order = "z[misc]"}
}

local function prototype(type_name, name)
	return data.raw[type_name] and data.raw[type_name][name]
end

local function ensure_group()
	if not (data.raw["item-group"] and data.raw["item-group"][group_name]) then
		data:extend({
			{
				type = "item-group",
				name = group_name,
				localised_name = {"item-group-name.razi-infrastructure"},
				icon = "__base__/graphics/icons/rail.png",
				icon_size = 64,
				order = "c[logistics]-b[infrastructure]"
			}
		})
	end

	for _, subgroup in ipairs(subgroup_definitions) do
		local existing = data.raw["item-subgroup"] and data.raw["item-subgroup"][subgroup.name]
		if existing then
			existing.group = group_name
			existing.order = subgroup.order
		else
			data:extend({
				{
					type = "item-subgroup",
					name = subgroup.name,
					group = group_name,
					order = subgroup.order
				}
			})
		end
	end
end

local function set_subgroup(type_name, name, subgroup)
	local target = prototype(type_name, name)
	if target then
		target.subgroup = subgroup
	end
end

local function move_item_and_recipe(name, subgroup)
	for _, item_type in ipairs({"item", "item-with-entity-data", "rail-planner", "space-platform-starter-pack"}) do
		set_subgroup(item_type, name, subgroup)
	end

	set_subgroup("recipe", name, subgroup)
end

local function recipe_result_name(recipe)
	local result = recipe.result
	if result then
		return result
	end

	local results = recipe.results
	if not results or not results[1] then
		return nil
	end

	return results[1].name or results[1][1]
end

local function item_places_entity(item, entity_types)
	local place_result = item and item.place_result
	if not place_result then
		return false
	end

	for _, entity_type in ipairs(entity_types) do
		if prototype(entity_type, place_result) then
			return true
		end
	end

	return false
end

local function name_matches_any(name, patterns)
	for _, pattern in ipairs(patterns) do
		if name:find(pattern) then
			return true
		end
	end

	return false
end

local function move_by_entity_types(entity_types, subgroup)
	for _, item_type in ipairs({"item", "item-with-entity-data"}) do
		for item_name, item in pairs(data.raw[item_type] or {}) do
			if item_places_entity(item, entity_types) then
				move_item_and_recipe(item_name, subgroup)
			end
		end
	end
end

local function move_by_name_patterns(patterns, subgroup)
	for _, item_type in ipairs({"item", "item-with-entity-data", "rail-planner", "space-platform-starter-pack"}) do
		for item_name, _ in pairs(data.raw[item_type] or {}) do
			if name_matches_any(item_name, patterns) then
				move_item_and_recipe(item_name, subgroup)
			end
		end
	end

	for recipe_name, recipe in pairs(data.raw.recipe or {}) do
		local result_name = recipe_result_name(recipe)
		if name_matches_any(recipe_name, patterns) or (result_name and name_matches_any(result_name, patterns)) then
			set_subgroup("recipe", recipe_name, subgroup)
		end
	end
end

local function move_tiles_and_floors()
	for item_name, item in pairs(data.raw.item or {}) do
		if item.place_as_tile
			or name_matches_any(item_name, {
				"floor",
				"tile",
				"concrete",
				"landfill",
				"foundation",
				"platform%-foundation",
				"scaffolding",
				"pavement"
			}) then
			move_item_and_recipe(item_name, "razi-infrastructure-surfaces")
		end
	end
end

local function move_infrastructure()
	move_by_entity_types({
		"car",
		"locomotive",
		"cargo-wagon",
		"fluid-wagon",
		"artillery-wagon",
		"spider-vehicle"
	}, "razi-infrastructure-vehicles")

	move_by_entity_types({
		"electric-pole",
		"power-switch",
		"lightning-attractor"
	}, "razi-infrastructure-power")

	move_by_name_patterns({
		"rail",
		"train%-stop",
		"rail%-signal",
		"rail%-chain%-signal",
		"rail%-ramp",
		"rail%-support",
		"locomotive",
		"cargo%-wagon",
		"fluid%-wagon"
	}, "razi-infrastructure-rail")

	move_by_name_patterns({
		"electric%-pole",
		"substation",
		"power%-switch",
		"lightning%-rod",
		"lightning%-collector",
		"lightning%-attractor"
	}, "razi-infrastructure-power")

	move_tiles_and_floors()
end

local function keep_railguns_in_combat()
	for _, item_type in ipairs({"item", "item-with-entity-data", "ammo", "gun"}) do
		for item_name, _ in pairs(data.raw[item_type] or {}) do
			if item_name:find("railgun") then
				set_subgroup(item_type, item_name, item_name:find("ammo") and "ammo" or "gun")
			end
		end
	end

	for recipe_name, recipe in pairs(data.raw.recipe or {}) do
		local result_name = recipe_result_name(recipe)
		if recipe_name:find("railgun") or (result_name and result_name:find("railgun")) then
			set_subgroup("recipe", recipe_name, (recipe_name:find("ammo") or (result_name and result_name:find("ammo"))) and "ammo" or "gun")
		end
	end
end

function logistics_cleanup.data_final_fixes()
	ensure_group()
	move_infrastructure()
	keep_railguns_in_combat()
end

return logistics_cleanup
