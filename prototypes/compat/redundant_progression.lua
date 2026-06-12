local redundant_progression = {}

local function raw(type_name, name)
	return data.raw[type_name] and data.raw[type_name][name]
end

local function set_hidden_flags(prototype)
	if not prototype then
		return
	end

	prototype.hidden = true
	prototype.hidden_in_factoriopedia = true
end

local function hide_item_family(name)
	for _, type_name in ipairs({
		"item",
		"item-with-entity-data",
		"tool",
		"ammo",
		"capsule",
		"gun",
		"armor",
		"module",
		"rail-planner",
		"repair-tool"
	}) do
		set_hidden_flags(raw(type_name, name))
	end
end

local function hide_recipe(name)
	local recipe = raw("recipe", name)
	if not recipe then
		return
	end

	recipe.enabled = false
	recipe.hide_from_player_crafting = true
	recipe.hide_from_stats = true
	set_hidden_flags(recipe)
end

local function hide_entity(name)
	for _, type_name in ipairs({
		"assembling-machine",
		"furnace",
		"mining-drill",
		"inserter",
		"transport-belt",
		"underground-belt",
		"splitter"
	}) do
		local prototype = raw(type_name, name)
		if prototype then
			prototype.next_upgrade = nil
			set_hidden_flags(prototype)
		end
	end
end

local function clear_next_upgrade_references(name)
	for _, type_name in ipairs({
		"assembling-machine",
		"furnace",
		"mining-drill",
		"inserter",
		"transport-belt",
		"underground-belt",
		"splitter"
	}) do
		for _, prototype in pairs(data.raw[type_name] or {}) do
			if prototype.next_upgrade == name then
				prototype.next_upgrade = nil
			end
		end
	end
end

local function has_visible_place_result(entity_name)
	for _, type_name in ipairs({
		"item",
		"item-with-entity-data",
		"tool",
		"ammo",
		"capsule",
		"gun",
		"armor",
		"module",
		"rail-planner",
		"repair-tool"
	}) do
		for _, item in pairs(data.raw[type_name] or {}) do
			if item.place_result == entity_name and not item.hidden then
				return true
			end
		end
	end

	return false
end

local function clear_hidden_next_upgrade_targets()
	for _, type_name in ipairs({
		"assembling-machine",
		"furnace",
		"mining-drill",
		"inserter",
		"transport-belt",
		"underground-belt",
		"splitter"
	}) do
		for _, prototype in pairs(data.raw[type_name] or {}) do
			local next_upgrade = prototype.next_upgrade
			if next_upgrade and type(next_upgrade) == "string" and raw(type_name, next_upgrade) then
				if not has_visible_place_result(next_upgrade) then
					prototype.next_upgrade = nil
				end
			end
		end
	end
end

local function technology_has_dependents(technology_name)
	for _, technology in pairs(data.raw.technology or {}) do
		for _, prerequisite in ipairs(technology.prerequisites or {}) do
			if prerequisite == technology_name then
				return true
			end
		end
	end

	return false
end

local function strip_recipe_unlock(recipe_name)
	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects
		if effects then
			for index = #effects, 1, -1 do
				local effect = effects[index]
				if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
					table.remove(effects, index)
				end
			end
		end

		if effects and #effects == 0 and not technology_has_dependents(technology.name) then
			set_hidden_flags(technology)
		end
	end
end

local function hide_redundant_machine(name)
	hide_item_family(name)
	hide_recipe(name)
	hide_entity(name)
	clear_next_upgrade_references(name)
	strip_recipe_unlock(name)
end

function redundant_progression.data_final_fixes()
	local hide_redundant = settings.startup["razi-hide-redundant-assembler-tiers"]
	if not (hide_redundant and hide_redundant.value) then
		return
	end

	if mods["planetaris-hyarion"] and raw("assembling-machine", "planetaris-assembling-machine-4") then
		hide_redundant_machine("planetaris-assembling-machine-4")
	end

	if mods["LithiumBattery"] and raw("assembling-machine", "assembling-machine-4") then
		hide_redundant_machine("assembling-machine-4")
	end

	clear_hidden_next_upgrade_targets()
end

return redundant_progression
