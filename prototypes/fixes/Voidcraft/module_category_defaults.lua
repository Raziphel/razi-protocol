local module_category_defaults = {}

-- Module Category Defaults (a dependency of Panglia, Moshine and Rigor Module, which Planet Crucible needs) widens the module list of
-- a machine to every ordinary category when that list holds ordinary categories only (process_prototypes in the mod's autodetect.lua;
-- Rigor Module forces its dynamic mode on in settings-final-fixes.lua). Machines whose author wrote "speed, quality, omega" (Nexus' nano
-- factory and the other Nexus machines with their Tenebris copies) or "efficiency, quality" (Panglia's cloning vat) take productivity,
-- efficiency or speed modules this way.
-- Voidcraft adds Iridescent Industry's "azure-speed" and Arcanyx's "arcanyx-curse" to the list of every lab, assembling machine, furnace,
-- rocket silo and mining drill in its data-updates.lua (:191-206, through IridescentIndustry prototypes/prismorphing-blue.lua:59-66 and
-- Arcanyx prototypes/curses.lua:3-20; Arcanyx only for machines that pollute). The mod then sees a category that is not ordinary, leaves
-- the list alone, and those 24 machines keep the author's short list: no productivity or efficiency modules in the Nexus machines, no
-- speed modules in the cloning vat, unlike the same pack without Voidcraft.
-- The mod's own way to register an ordinary category is to add it to ModuleCategoryDefaults.default_categories in data or data-updates
-- (its README); that is done here, in data-updates, which comes before the mod's data-final-fixes. Only the two categories that Voidcraft
-- appends to existing lists are registered: "bio-module" (Khemia), "tolerance" (Foliax) and the "voidcraft-*" categories belong to the
-- machines of their own mods, whose lists are meant to stay short.
-- A list that holds nothing but these two categories is not a list of ordinary categories made wider by Voidcraft but a deliberate
-- restriction: Voidcraft and Iridescent Industry give the voidforges "arcanyx-curse" alone (Voidcraft prototypes/voidworks.lua:567,
-- :710, :806, Iridescent Industry prototypes/voidworks-red.lua:114), and a machine with an empty list gets "azure-speed" alone. Once the
-- categories are ordinary these would be widened to every module, so they are marked as processed, which the mod skips. This needs
-- Voidcraft's data-updates to have run first, which it has: Arcanyx, a dependency of the pack, requires Voidcraft.
-- Remove this module when Voidcraft or Iridescent Industry registers "azure-speed" and Arcanyx "arcanyx-curse" itself, or when Module
-- Category Defaults keeps categories that were appended to a list of ordinary ones.

local CATEGORIES = {"azure-speed", "arcanyx-curse"}

local function contains(list, value)
	for _, item in pairs(list) do
		if item == value then
			return true
		end
	end
	return false
end

-- true for a list that is not empty and holds registered categories only
local function holds_only_registered(list)
	if type(list) ~= "table" or next(list) == nil then
		return false
	end
	for _, category in pairs(list) do
		if not contains(CATEGORIES, category) then
			return false
		end
	end
	return true
end

local function keep_restricted_lists(defaults)
	local processed = defaults.processed_prototypes
	if type(processed) ~= "table" or type(defaults.moduled_types) ~= "table" then
		return
	end

	for _, prototype_type in ipairs(defaults.moduled_types) do
		local marked = processed[prototype_type]
		for name, prototype in pairs(data.raw[prototype_type] or {}) do
			if holds_only_registered(prototype.allowed_module_categories) and not (marked and marked[name]) then
				marked = marked or {}
				processed[prototype_type] = marked
				marked[name] = true
				log("razi-protocol: " .. prototype_type .. " " .. name .. " keeps its list of module categories (" ..
					table.concat(prototype.allowed_module_categories, ", ") .. ") when Module Category Defaults widens the others")
			end
		end
	end
end

function module_category_defaults.data_updates()
	local defaults = rawget(_G, "ModuleCategoryDefaults")
	if not mods["module-category-defaults"] or type(defaults) ~= "table" or type(defaults.default_categories) ~= "table" then
		return
	end

	local existing = data.raw["module-category"] or {}
	local added = false
	for _, category in ipairs(CATEGORIES) do
		if existing[category] and not contains(defaults.default_categories, category) then
			table.insert(defaults.default_categories, category)
			added = true
			log("razi-protocol: module category " .. category .. " registered as an ordinary one in Module Category Defaults")
		end
	end

	if added then
		keep_restricted_lists(defaults)
	end
end

return module_category_defaults
