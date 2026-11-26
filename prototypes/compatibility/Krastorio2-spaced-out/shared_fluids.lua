-- One fluid per substance. Muria and Krastorio 2 both make hydrogen chloride: Muria as hydrogen-chloride
-- (Muria/prototypes/items.lua:77), K2 as kr-hydrogen-chloride (Krastorio2/prototypes/fluids.lua). Both are called
-- "Hydrogen chloride" in the game, but they do not mix, so one chain cannot feed the other and the player sees the
-- same gas twice. K2SO folds the materials it shares with other mods into the kr- names, chlorine among them
-- (Krastorio2-spaced-out/prototypes/final-fixes/enforce-k2-items.lua), but not hydrogen chloride. Here every recipe,
-- fluid turret, fluid box, tile, resource and research trigger takes K2's fluid instead of Muria's, as K2SO does
-- for its list, and Muria's fluid is hidden. A save keeps the fluid in its pipes: migrations/shared-fluids.json.
--
-- A retired fluid (Muria's hydrogen chloride, and the chlorine and other materials K2SO hid) keeps the recipes other
-- mods generate for every fluid: flaring (Flare Stack), the outlet (Linox), voiding (Maraxsis), burning (K2), and
-- its barrels with everything made of them (filling, emptying, crushing, recycling). Nothing makes the fluid any
-- more, so these recipes, the barrels and their unlocks are hidden too.
local shared_fluids = {}

-- Retired fluid -> the fluid that replaces it.
local merged = {
	["hydrogen-chloride"] = "kr-hydrogen-chloride",
}

-- Materials K2SO renames to kr-<name> and hides (enforce-k2-items.lua:3-12).
local k2so_materials = {"oxygen", "hydrogen", "chlorine", "ammonia", "lithium"}

-- The per-fluid recipes other mods generate, "%s" is the fluid.
local service_recipes = {
	"%s-flaring",
	"%s-outlet",
	"maraxsis-fluid-void-%s",
	"kr-burn-%s",
}

local function visible(prototype)
	return prototype and not prototype.hidden
end

local function hide(prototype)
	if prototype.hidden and prototype.hidden_in_factoriopedia then
		return false
	end
	prototype.hidden = true
	prototype.hidden_in_factoriopedia = true
	return true
end

local function rename_entries(entries, renamed)
	local changed = false
	for _, entry in pairs(entries or {}) do
		if entry.type == "fluid" and renamed[entry.name] then
			entry.name = renamed[entry.name]
			changed = true
		end
	end
	return changed
end

local function rename_fluid_box(box, renamed)
	if type(box) == "table" and box.filter and renamed[box.filter] then
		box.filter = renamed[box.filter]
		return true
	end
	return false
end

-- Every place a prototype names a fluid that the game reads in this set of mods.
local function rename_everywhere(renamed, skipped)
	local recipes, others = 0, 0
	for name, recipe in pairs(data.raw.recipe or {}) do
		if not skipped[name] then
			local changed = rename_entries(recipe.ingredients, renamed)
			changed = rename_entries(recipe.results, renamed) or changed
			if recipe.main_product and renamed[recipe.main_product] then
				recipe.main_product = renamed[recipe.main_product]
				changed = true
			end
			if changed then
				recipes = recipes + 1
			end
		end
	end

	for _, turret in pairs(data.raw["fluid-turret"] or {}) do
		local attack = turret.attack_parameters
		for _, ammo in pairs(attack and attack.fluids or {}) do
			if renamed[ammo.type] then
				ammo.type = renamed[ammo.type]
				others = others + 1
			end
		end
	end

	for _, prototypes in pairs(data.raw) do
		for _, prototype in pairs(prototypes) do
			if type(prototype) == "table" then
				for _, key in ipairs({"fluid_box", "input_fluid_box", "output_fluid_box"}) do
					if rename_fluid_box(prototype[key], renamed) then
						others = others + 1
					end
				end
				for _, box in pairs(type(prototype.fluid_boxes) == "table" and prototype.fluid_boxes or {}) do
					if rename_fluid_box(box, renamed) then
						others = others + 1
					end
				end
				if type(prototype.energy_source) == "table" and rename_fluid_box(prototype.energy_source.fluid_box, renamed) then
					others = others + 1
				end
			end
		end
	end

	for _, tile in pairs(data.raw.tile or {}) do
		if tile.fluid and renamed[tile.fluid] then
			tile.fluid = renamed[tile.fluid]
			others = others + 1
		end
	end

	for _, resource in pairs(data.raw.resource or {}) do
		local minable = resource.minable
		if minable then
			if minable.required_fluid and renamed[minable.required_fluid] then
				minable.required_fluid = renamed[minable.required_fluid]
				others = others + 1
			end
			if rename_entries(minable.results, renamed) then
				others = others + 1
			end
		end
	end

	for _, technology in pairs(data.raw.technology or {}) do
		local trigger = technology.research_trigger
		if trigger and trigger.fluid and renamed[trigger.fluid] then
			trigger.fluid = renamed[trigger.fluid]
			others = others + 1
		end
	end

	return recipes, others
end

-- Items named after the fluid that are made of it: hydrogen-chloride-barrel, hydrogen-chloride-titanium-barrel.
local function barrel_items(fluid)
	local items = {}
	for name in pairs(data.raw.item or {}) do
		if name == fluid .. "-barrel" or name == fluid .. "-titanium-barrel" then
			items[name] = true
		end
	end
	return items
end

local function names_any(entries, set)
	for _, entry in pairs(entries or {}) do
		if set[entry.name] then
			return true
		end
	end
	return false
end

-- The recipes that only exist for the retired fluid: the per-fluid service recipes and every recipe with its
-- barrels as an ingredient or a result.
local function retired_recipes(fluid, barrels)
	local recipes = {}
	for _, pattern in ipairs(service_recipes) do
		local name = string.format(pattern, fluid)
		if data.raw.recipe and data.raw.recipe[name] then
			recipes[name] = true
		end
	end
	if next(barrels) then
		for name, recipe in pairs(data.raw.recipe or {}) do
			if names_any(recipe.ingredients, barrels) or names_any(recipe.results, barrels) then
				recipes[name] = true
			end
		end
	end
	return recipes
end

local function remove_unlocks(recipes)
	local removed = 0
	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects
		if effects then
			for index = #effects, 1, -1 do
				local effect = effects[index]
				if effect.type == "unlock-recipe" and recipes[effect.recipe] then
					table.remove(effects, index)
					removed = removed + 1
				end
			end
		end
	end
	return removed
end

-- Nothing but the retired recipes makes the fluid, so nothing else needs them.
local function made_elsewhere(fluid, retired)
	for name, recipe in pairs(data.raw.recipe or {}) do
		if not retired[name] and visible(recipe) then
			for _, result in pairs(recipe.results or {}) do
				if result.type == "fluid" and result.name == fluid then
					return name
				end
			end
		end
	end
	return nil
end

local function retire(fluid)
	local barrels = barrel_items(fluid)
	local recipes = retired_recipes(fluid, barrels)
	local maker = made_elsewhere(fluid, recipes)
	if maker then
		log("razi-protocol: " .. fluid .. " is still made by " .. maker .. ", its flaring, voiding and barrels stay")
		return
	end
	local hidden = 0
	for name in pairs(recipes) do
		if hide(data.raw.recipe[name]) then
			hidden = hidden + 1
		end
	end
	for name in pairs(barrels) do
		if hide(data.raw.item[name]) then
			hidden = hidden + 1
		end
	end
	local unlocks = remove_unlocks(recipes)
	if hidden > 0 or unlocks > 0 then
		log("razi-protocol: retired fluid " .. fluid .. ": hid " .. hidden .. " recipes and barrels, removed " .. unlocks
			.. " unlocks")
	end
end

function shared_fluids.data_final_fixes()
	local fluids = data.raw.fluid or {}
	local renamed = {}
	for old, new in pairs(merged) do
		if visible(fluids[old]) and visible(fluids[new]) then
			renamed[old] = new
		end
	end

	-- The retired fluid's own barrel and service recipes are hidden below, not renamed: renamed, they would be
	-- second barrels and flare recipes of the K2 fluid.
	local skipped = {}
	for old in pairs(renamed) do
		for name in pairs(retired_recipes(old, barrel_items(old))) do
			skipped[name] = true
		end
	end

	if next(renamed) then
		local recipes, others = rename_everywhere(renamed, skipped)
		for old, new in pairs(renamed) do
			hide(fluids[old])
			log("razi-protocol: " .. old .. " is " .. new .. " now: " .. recipes .. " recipes and " .. others
				.. " other prototypes changed")
		end
	end

	if not mods["Krastorio2-spaced-out"] then
		return
	end
	local retired = {}
	for old in pairs(renamed) do
		retired[#retired + 1] = old
	end
	for _, material in ipairs(k2so_materials) do
		local old = fluids[material]
		if old and old.hidden and visible(fluids["kr-" .. material]) then
			retired[#retired + 1] = material
		end
	end
	table.sort(retired)
	for _, fluid in ipairs(retired) do
		retire(fluid)
	end
end

return shared_fluids
