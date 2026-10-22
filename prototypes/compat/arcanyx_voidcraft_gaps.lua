local arcanyx_voidcraft_gaps = {}

-- With "s6x-arcanyx-voidcraft" (or ArcanyxContainment's "s6x-ac-arcanyx-voidcraft") Arcanyx 1.1.5 keeps Voidcraft on its own
-- world by adding the surface condition magic = 100 to the voidcrafters and the recipes it knows (Arcanyx/data-final-fixes.lua:11-69).
-- Two things escape that list:
--   * the Astral voidforge "s6x-voidworks-fusion" (Voidcraft 2.10.0+, Space Age only, Voidcraft/prototypes/voidworks.lua:803-923) is
--     not among the voidcrafters (Arcanyx/data-final-fixes.lua:12-22). Neither the machine nor its recipe has a magic condition, and
--     it runs the same voidcrafting categories as the closed s6x-voidworks-nuke, so on any surface it makes stone, plates, circuits,
--     processors, low density structures, solar panels and accumulators out of nothing (s6x-entropic-conjuration and its variants);
--   * the inverse recipes (s6xvcinv-*) are meant to be closed by r.category == "voidcrafting-inverse" (Arcanyx/data-final-fixes.lua:56),
--     but Factorio 2.1 recipes have only "categories", so the test is never true and none of them gets the condition.
-- This module adds the same condition, exactly as Arcanyx does, to the machine and to the inverse recipes under the first setting,
-- and to the forge's recipe under both (Arcanyx's construction restriction), and only to a prototype that has no magic condition yet.
-- Remove this module when Arcanyx lists the voidforge and tests "categories".

local PROPERTY = "magic"
local INVERSE = "voidcrafting-inverse"
local FORGE = "s6x-voidworks-fusion"

local function setting_value(name)
	---@type table?
	local startup = settings and settings.startup
	local setting = startup and startup[name]
	return type(setting) == "table" and setting.value == true
end

local function has_magic(prototype)
	local conditions = prototype.surface_conditions
	if type(conditions) ~= "table" then
		return false
	end
	for _, condition in pairs(conditions) do
		if type(condition) == "table" and condition.property == PROPERTY then
			return true
		end
	end
	return false
end

local function is_inverse(recipe)
	if recipe.category == INVERSE then
		return true
	end
	if type(recipe.categories) == "table" then
		for _, category in pairs(recipe.categories) do
			if category == INVERSE then
				return true
			end
		end
	end
	return false
end

-- Returns true when the condition was added.
local function restrict(prototype)
	if type(prototype) ~= "table" or has_magic(prototype) then
		return false
	end
	if type(prototype.surface_conditions) ~= "table" then
		prototype.surface_conditions = {}
	end
	table.insert(prototype.surface_conditions, {property = PROPERTY, min = 100, max = 100})
	return true
end

function arcanyx_voidcraft_gaps.data_final_fixes()
	if not (mods and mods["Arcanyx"]) then
		return
	end

	-- The flags Arcanyx computes at data-final-fixes.lua:1-9.
	local only, restrict_construction
	if mods["ArcanyxContainment"] then
		only = setting_value("s6x-ac-arcanyx-voidcraft")
		restrict_construction = true
	else
		only = setting_value("s6x-arcanyx-voidcraft")
		restrict_construction = only
	end
	if not (only or restrict_construction) then
		return
	end

	local machines, recipes, inverse = 0, 0, 0

	if only and data.raw["assembling-machine"] and restrict(data.raw["assembling-machine"][FORGE]) then
		machines = machines + 1
		log("razi-protocol: assembling-machine " .. FORGE .. " is kept on Arcanyx like the other voidcrafters (added the magic surface condition)")
	end

	if restrict_construction and data.raw.recipe and restrict(data.raw.recipe[FORGE]) then
		recipes = recipes + 1
		log("razi-protocol: recipe " .. FORGE .. " is kept on Arcanyx like the other voidcrafter recipes (added the magic surface condition)")
	end

	if only and data.raw.recipe then
		local names = {}
		for name, recipe in pairs(data.raw.recipe) do
			if type(recipe) == "table" and name ~= FORGE and is_inverse(recipe) then
				names[#names + 1] = name
			end
		end
		table.sort(names)
		for _, name in ipairs(names) do
			if restrict(data.raw.recipe[name]) then
				inverse = inverse + 1
				log("razi-protocol: recipe " .. name .. " is kept on Arcanyx with the other inverse voidcrafting recipes (added the magic surface condition)")
			end
		end
	end

	if machines + recipes + inverse > 0 then
		log("razi-protocol: Arcanyx's Voidcraft restriction reaches " .. machines .. " machine(s), " .. recipes .. " forge recipe(s) and "
			.. inverse .. " inverse recipe(s) it missed")
	end
end

return arcanyx_voidcraft_gaps
