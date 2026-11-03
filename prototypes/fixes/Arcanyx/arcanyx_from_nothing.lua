local arcanyx_from_nothing = {}

-- With "s6x-arcanyx-voidcraft" (or ArcanyxContainment's "s6x-ac-arcanyx-voidcraft") Arcanyx keeps Voidcraft on its own world by
-- adding the surface condition magic = 100 to the voidcrafters and the recipes it knows (Arcanyx/data-final-fixes.lua:11-69).
-- Since Arcanyx 1.1.6 that list holds the Astral voidforge, the entropic voidcrafting and the inverse recipes too. Left out are
-- the Iridescent Industry and Arcanyx recipes that make ore, stone, sand and crystals out of a few inputs or none at all, with
-- productivity allowed: the deep mines (Iridescent Industry/prototypes/deep-mining.lua:55-120, 231-290) mine without ingredients
-- on any surface with gravity, and the entropic creation (Arcanyx/prototypes/entropic-creation.lua:20-57) turns prismite ore and
-- voidstone into several ores per craft in an ordinary centrifuge. ArcanyxContainment closes them with the same condition
-- (ArcanyxContainment/data-final-fixes.lua:102-111), Arcanyx and Iridescent Industry do not. The mining recipes themselves are
-- closed as well, not only the machines, and so are the Rabbasca copies of the machines (harene-infused-*): they are made at
-- Rabbasca's data-final-fixes, after Arcanyx and before this module, with the conditions the machine had then, so a copy
-- would otherwise stand on every surface the machine itself cannot. (The Tenebris Prime copies, bioluminescent-*, need
-- nothing: Tenebris Prime looks at the base's conditions after this module and hides their recipes.)
-- The cursed furnaces are left alone: they smelt one prismite ore into one plate on a void fuel that only Arcanyx makes,
-- which creates nothing.
-- This module adds the same condition, exactly as Arcanyx does, under the first setting, and only to a prototype that has no
-- magic condition yet (with ArcanyxContainment the six prototypes it lists have it already).
-- Remove this module when Arcanyx or Iridescent Industry close the deep mines and the entropic creation themselves.

local PROPERTY = "magic"

-- Made out of nothing or almost nothing (see the header). Entities by prototype type, recipes by name, and the prefix under
-- which another mod copies an entity.
local COPY_PREFIXES = {"harene-infused-"}
local FROM_NOTHING_ENTITIES = {
	["assembling-machine"] = {
		"s6x-prismite-deep-mine", -- fixed recipe s6x-prismite-deep-mining
		"s6x-prismite-deep-mine-advanced", -- also runs s6x-prismite-deeper-mining
	},
}
local FROM_NOTHING_RECIPES = {
	"s6x-prismite-deep-mine", -- the machine's own recipes, as in ArcanyxContainment
	"s6x-prismite-deep-mine-advanced",
	"s6x-prismite-deep-mining", -- no ingredients
	"s6x-prismite-deeper-mining", -- no ingredients
	"s6x-entropic-creation", -- prismite ore and voidstone into ores, in centrifuges and by hand
	"s6x-entropic-creation-crushed",
}

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

function arcanyx_from_nothing.data_final_fixes()
	if not (mods and mods["Arcanyx"]) then
		return
	end

	-- The flag Arcanyx computes at data-final-fixes.lua:1-9.
	local only
	if mods["ArcanyxContainment"] then
		only = setting_value("s6x-ac-arcanyx-voidcraft")
	else
		only = setting_value("s6x-arcanyx-voidcraft")
	end
	if not only then
		return
	end

	local machines, recipes = 0, 0

	local types = {}
	for prototype_type in pairs(FROM_NOTHING_ENTITIES) do
		types[#types + 1] = prototype_type
	end
	table.sort(types)
	for _, prototype_type in ipairs(types) do
		for _, name in ipairs(FROM_NOTHING_ENTITIES[prototype_type]) do
			local group = data.raw[prototype_type]
			---@type string[]
			local names = {name}
			for _, prefix in ipairs(COPY_PREFIXES) do
				names[#names + 1] = prefix .. name
			end
			for _, entity_name in ipairs(names) do
				if group and restrict(group[entity_name]) then
					machines = machines + 1
					log("razi-protocol: " .. prototype_type .. " " .. entity_name .. " is kept on Arcanyx, it makes ore and stone out of nothing (added the magic surface condition)")
				end
			end
		end
	end
	for _, name in ipairs(FROM_NOTHING_RECIPES) do
		if data.raw.recipe and restrict(data.raw.recipe[name]) then
			recipes = recipes + 1
			log("razi-protocol: recipe " .. name .. " is kept on Arcanyx, it makes ore and stone out of nothing (added the magic surface condition)")
		end
	end

	if machines + recipes > 0 then
		log("razi-protocol: Arcanyx and Iridescent Industry's out-of-nothing production reaches " .. machines .. " machine(s) and "
			.. recipes .. " recipe(s) that were not kept on Arcanyx")
	end
end

return arcanyx_from_nothing
