local redundant_progression = {}
local hide_recipes = require("prototypes.balance.common.hide_recipes")

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

-- Hide a technology that only unlocked this machine even if another technology requires it.
-- `hide_recipes` keeps required technologies visible, leaving players who paid science for
-- `automation-4` or `planetaris-automation-4` with an empty technology.
local function hide_redundant_machine(name)
	hide_item_family(name)
	local unlockers = {}
	for technology_name, technology in pairs(data.raw.technology or {}) do
		for _, effect in pairs(technology.effects or {}) do
			if effect and effect.type == "unlock-recipe" and effect.recipe == name then
				unlockers[technology_name] = true
				break
			end
		end
	end
	local emptied = hide_recipes.hide({name})
	local recipe = raw("recipe", name)
	if recipe then
		recipe.hide_from_player_crafting = true
		recipe.hide_from_stats = true
		set_hidden_flags(recipe)
	end
	for technology_name in pairs(unlockers) do
		local technology = raw("technology", technology_name)
		local effects = technology and technology.effects
		if technology and (effects == nil or #effects == 0) and technology.hidden ~= true then
			set_hidden_flags(technology)
			log("razi-protocol: technology " .. technology_name .. " hidden: it only unlocked the hidden machine " .. name)
		end
	end
	for technology_name in pairs(emptied) do
		set_hidden_flags(raw("technology", technology_name))
	end
	hide_entity(name)
	clear_next_upgrade_references(name)
end

function redundant_progression.data_final_fixes()
	local hide_redundant = settings.startup["razi-hide-redundant-assembler-tiers"]
	if not (hide_redundant and hide_redundant.value) then
		return
	end

	if mods["planetaris-hyarion"] and raw("assembling-machine", "planetaris-assembling-machine-4") then
		hide_redundant_machine("planetaris-assembling-machine-4")
	end

	if mods["LithiumBattery"] and raw("assembling-machine", "ao-assembling-machine-4") then
		hide_redundant_machine("ao-assembling-machine-4")
	end

	clear_hidden_next_upgrade_targets()
end

return redundant_progression
