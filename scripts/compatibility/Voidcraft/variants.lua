-- Voidcraft's unlock of the flux, quality and coherence variants of its recipes, without the walk over every recipe.
--
-- Voidcraft 2.11.1 (control.lua:15-27) hands its unlock_variants to a remote interface that has a function named
-- "voidcraft_unlock_variants"; with one registered it does nothing itself. Its own version goes through
-- pairs(owner.recipes) on every finished research and reads the first crafting category of each of them. With ~56 000
-- recipes that is about 0.1 s per research after s6x-void-flux, so researching many technologies in a row (a cheat
-- command, a script, a late save) crawls.
--
-- The loop body is Voidcraft's own. Only the list it runs over changes:
--   * the base recipes (first category "voidcrafting*") that have a -flx, -qual or -coh variant are listed once from
--     prototypes.recipe: prototypes do not change in a session, so nothing is kept in storage;
--   * a finished research checks only the base recipes it unlocks (the game enables the variants it unlocks itself);
--   * the whole list is checked for "always" (/vc_fix_recipes, on_technology_effects_reset, on_configuration_changed) and
--     when the research is one of the three that switch variant kinds on.
-- One difference: a base recipe that another mod's script enables, not a technology, gets its variants at the next full
-- pass, not at the next research.
--
-- Remove this module when Voidcraft stops looking for the interface or does the same itself.

local voidcraft_variants = {}

local INTERFACE = "razi_voidcraft_variants"
local FUNCTION = "voidcraft_unlock_variants"
local CATEGORY_PREFIX = "voidcrafting"
local FLUX = "s6x-void-flux"
local COHERENCE = "s6x-void-coherence"
local QUALITY = "s6x-void-quality"
local FULL_PASS = {[FLUX] = true, [COHERENCE] = true, [QUALITY] = true}

-- Built on first use.
---@type {list: string[], set: table<string, true>}?
local base_recipes

local function variants_exist(name)
	local recipes = prototypes.recipe
	return recipes[name .. "-flx"] ~= nil or recipes[name .. "-qual"] ~= nil or recipes[name .. "-coh"] ~= nil
end

---@return string[] list
---@return table<string, true> set
local function bases()
	if not base_recipes then
		---@type string[]
		local list = {}
		---@type table<string, true>
		local set = {}
		for name, prototype in pairs(prototypes.recipe) do
			local category = prototype.categories[1]
			if category and string.sub(category, 1, #CATEGORY_PREFIX) == CATEGORY_PREFIX and variants_exist(name) then
				list[#list + 1] = name
				set[name] = true
			end
		end
		-- pairs() order is not defined: sort, so that every client walks the list the same way
		table.sort(list)
		base_recipes = {list = list, set = set}
	end
	local cached = base_recipes
	return cached.list, cached.set
end

-- The base recipes to check for this call.
---@return string[]
local function recipes_to_check(always, event)
	local list, set = bases()
	if always then
		return list
	end
	local research = event.research
	if FULL_PASS[research.name] then
		return list
	end
	local found = {}
	for _, effect in pairs(research.prototype.effects) do
		if effect.type == "unlock-recipe" and set[effect.recipe] then
			found[#found + 1] = effect.recipe
		end
	end
	return found
end

local function clear_notification(force, recipe_name)
	for _, player in pairs(force.players) do
		player.clear_recipe_notification(recipe_name)
	end
end

-- Enables one variant when its base recipe is enabled and it is not.
local function enable_variant(force, base_name, variant_name)
	local variant = force.recipes[variant_name]
	if variant and force.recipes[base_name].enabled and not variant.enabled then
		variant.enabled = true
		clear_notification(force, variant_name)
		return true
	end
	return false
end

---@param coh_also_enable table<string, string> base recipe -> recipe enabled together with its coherence variant
---@param always boolean check every recipe (Voidcraft passes true outside of a research)
---@param force LuaForce
---@param event table {research = LuaTechnology}, or {research = {}} when always is true
function voidcraft_variants.unlock_variants(coh_also_enable, always, force, event)
	local technologies = force.technologies
	local function now_or_before(name)
		if not always and event.research.name == name then
			return true
		end
		local technology = technologies[name]
		return technology ~= nil and technology.researched
	end

	if not now_or_before(FLUX) then
		return
	end
	local coherence = now_or_before(COHERENCE)
	local quality = script.active_mods["quality"] and not script.active_mods["no-quality"] and now_or_before(QUALITY)

	for _, name in ipairs(recipes_to_check(always, event)) do
		if force.recipes[name] then
			enable_variant(force, name, name .. "-flx")
			if quality then
				enable_variant(force, name, name .. "-qual")
			end
			if coherence and enable_variant(force, name, name .. "-coh") then
				local also = coh_also_enable[name]
				if also then
					local recipe = force.recipes[also]
					if recipe and not recipe.enabled then
						recipe.enabled = true
						clear_notification(force, also)
					end
				end
			end
		end
	end
end

-- Registers the interface Voidcraft looks for. Without Voidcraft nobody calls it.
function voidcraft_variants.register()
	if not script.active_mods["Voidcraft"] then
		return
	end
	remote.add_interface(INTERFACE, {[FUNCTION] = voidcraft_variants.unlock_variants})
end

return voidcraft_variants
