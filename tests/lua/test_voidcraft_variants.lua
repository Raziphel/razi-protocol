---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil, param-type-mismatch
-- Voidcraft's recipe variant unlock through the remote interface (scripts/compat/voidcraft_variants.lua) on mocked prototypes
-- and forces, compared with Voidcraft's own loop over every recipe (Voidcraft 2.11.0 control.lua:10-75).
-- Run from the mod root:
--   lua5.2 tests/lua/test_voidcraft_variants.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local COH_ALSO = {["vc-circuit"] = "vc-circuit-extra-coh"}
local TECHNOLOGIES = {"s6x-void-flux", "s6x-void-coherence", "s6x-void-quality"}

-- Base recipes with their variants; the first category decides what Voidcraft looks at.
local RECIPES = {
	{name = "vc-a", category = "voidcrafting", variants = {"flx", "qual", "coh"}},
	{name = "vc-b", category = "voidcrafting-advanced", variants = {"flx"}},
	{name = "vc-c", category = "voidcrafting", variants = {"coh"}},
	{name = "vc-circuit", category = "voidcrafting", variants = {"flx", "coh"}},
	{name = "vc-circuit-extra-coh", category = "voidcrafting", variants = {}},
	{name = "vc-lonely", category = "voidcrafting", variants = {}},
	{name = "vc-other", category = "crafting", variants = {"flx"}},
	{name = "vcinv-x", category = "voidcrafting-inverse", variants = {"flx"}},
	{name = "iron-plate", category = "smelting", variants = {}},
}

local active_mods = {quality = "2.1.0"}
local interfaces = {}
rawset(_G, "script", {active_mods = active_mods})
rawset(_G, "remote", {add_interface = function(name, functions) interfaces[name] = functions end})

-- A force and the prototype table of a world in which the listed recipes are enabled and the listed technologies researched.
local function build(enabled_names, researched_names)
	local prototype_recipes, recipes, cleared = {}, {}, {}
	local enabled = {}
	for _, name in ipairs(enabled_names) do
		enabled[name] = true
	end
	local function add(name, category)
		prototype_recipes[name] = {categories = {category}}
		recipes[name] = {name = name, enabled = enabled[name] == true}
	end
	for _, recipe in ipairs(RECIPES) do
		add(recipe.name, recipe.category)
		for _, suffix in ipairs(recipe.variants) do
			add(recipe.name .. "-" .. suffix, recipe.category)
		end
	end
	local force = {
		recipes = recipes,
		technologies = {},
		players = {{clear_recipe_notification = function(name) cleared[#cleared + 1] = name end}},
		prototype_recipes = prototype_recipes,
	}
	for _, name in ipairs(TECHNOLOGIES) do
		force.technologies[name] = {name = name, researched = false}
	end
	for _, name in ipairs(researched_names) do
		force.technologies[name].researched = true
	end
	return force, cleared
end

local function technology(name, unlocks)
	local effects = {}
	for _, recipe in ipairs(unlocks or {}) do
		effects[#effects + 1] = {type = "unlock-recipe", recipe = recipe}
	end
	effects[#effects + 1] = {type = "laboratory-speed", modifier = 0.1}
	return {name = name, prototype = {effects = effects}}
end

-- Voidcraft's own loop, as shipped before 2.11.1.
local function original(always, owner, event)
	local function clear(force, recipe_name)
		for _, player in pairs(force.players) do
			player.clear_recipe_notification(recipe_name)
		end
	end
	if ((not always and event.research.name == "s6x-void-flux") or owner.technologies["s6x-void-flux"].researched) then
		local coherence = ((not always and event.research.name == "s6x-void-coherence") or owner.technologies["s6x-void-coherence"].researched)
		local quality = (active_mods["quality"] and not active_mods["no-quality"])
			and ((not always and event.research.name == "s6x-void-quality") or owner.technologies["s6x-void-quality"].researched)
		for pr in pairs(owner.recipes) do
			local rcat = owner.prototype_recipes[pr].categories[1]
			if (string.sub(rcat, 1, 12) == "voidcrafting") then
				local fluxized = pr .. "-flx"
				if (owner.recipes[fluxized]) then
					if (owner.recipes[pr].enabled and not owner.recipes[fluxized].enabled) then
						owner.recipes[fluxized].enabled = true
						clear(owner, fluxized)
					end
				end
				if (quality) then
					local qual = pr .. "-qual"
					if (owner.recipes[qual]) then
						if (owner.recipes[pr].enabled and not owner.recipes[qual].enabled) then
							owner.recipes[qual].enabled = true
							clear(owner, qual)
						end
					end
				end
				if (coherence) then
					local coherized = pr .. "-coh"
					if (owner.recipes[coherized]) then
						if (owner.recipes[pr].enabled and not owner.recipes[coherized].enabled) then
							owner.recipes[coherized].enabled = true
							clear(owner, coherized)
							if (COH_ALSO[pr] and owner.recipes[COH_ALSO[pr]]) then
								local also = COH_ALSO[pr]
								if (not owner.recipes[also].enabled) then
									owner.recipes[also].enabled = true
									clear(owner, also)
								end
							end
						end
					end
				end
			end
		end
	end
end

local function load_module(prototype_recipes)
	rawset(_G, "prototypes", {recipe = prototype_recipes})
	package.loaded["scripts.compat.voidcraft_variants"] = nil
	return require("scripts.compat.voidcraft_variants")
end

local function enabled_list(force)
	local out = {}
	for name, recipe in pairs(force.recipes) do
		if recipe.enabled then
			out[#out + 1] = name
		end
	end
	table.sort(out)
	return table.concat(out, ",")
end

local function sorted(list)
	local copy = {table.unpack(list)}
	table.sort(copy)
	return table.concat(copy, ",")
end

-- The registration: only with Voidcraft, under a name of its own, with the function Voidcraft looks for.
local module = load_module({})
module.register()
check(next(interfaces) == nil, "no interface without Voidcraft")
active_mods["Voidcraft"] = "2.11.1"
module.register()
local registered = interfaces["razi_voidcraft_variants"]
check(registered and type(registered.voidcraft_unlock_variants) == "function", "the interface has the function Voidcraft looks for")
check(registered.voidcraft_unlock_variants == module.unlock_variants, "the interface calls the module")

-- The same result as Voidcraft's loop, notifications included. The world before a research is one in which the earlier
-- passes have run: every enabled base recipe already has the variants the researched technologies allow. The research
-- then enables the recipes it unlocks and, if it is one of the three technologies, becomes researched.
local ALL_BASES = {"vc-a", "vc-b", "vc-c", "vc-circuit", "vc-other", "vcinv-x", "vc-lonely", "iron-plate"}
local cases = {
	{name = "an unrelated research before the flux technology", researched = {}, bases = {"vc-a"}, research = technology("other-tech", {"vc-a"})},
	{name = "the flux technology", researched = {}, bases = {"vc-a", "vc-b", "vc-c", "vcinv-x", "vc-other"}, research = technology("s6x-void-flux")},
	{name = "coherence after flux", researched = {"s6x-void-flux"}, bases = {"vc-a", "vc-circuit", "vc-c"}, research = technology("s6x-void-coherence")},
	{name = "quality after flux", researched = {"s6x-void-flux"}, bases = {"vc-a", "vc-circuit"}, research = technology("s6x-void-quality")},
	{name = "a technology unlocks a base recipe with every kind on", researched = TECHNOLOGIES, bases = {"vc-a"},
		research = technology("circuit-tech", {"vc-circuit"})},
	{name = "a technology unlocks several base recipes", researched = {"s6x-void-flux"}, bases = {"vc-a"},
		research = technology("a-tech", {"vc-b", "vc-c", "vc-circuit"})},
	{name = "a technology unlocks the base recipe and one variant", researched = TECHNOLOGIES, bases = {},
		research = technology("variant-tech", {"vc-a", "vc-a-flx"})},
	{name = "a technology unlocks nothing the module looks at", researched = TECHNOLOGIES, bases = {"vc-a"},
		research = technology("plain-tech", {"iron-plate", "vc-lonely", "vc-other"})},
	{name = "every base recipe is enabled, the research unlocks none", researched = TECHNOLOGIES, bases = ALL_BASES, research = technology("t", {})},
}
for _, case in ipairs(cases) do
	for _, always in ipairs({false, true}) do
		local ours, ours_cleared = build(case.bases, case.researched)
		local theirs, theirs_cleared = build(case.bases, case.researched)
		-- the earlier passes
		original(true, ours, {research = {}})
		original(true, theirs, {research = {}})
		for index = #ours_cleared, 1, -1 do ours_cleared[index] = nil end
		for index = #theirs_cleared, 1, -1 do theirs_cleared[index] = nil end
		-- the research
		for _, world in ipairs({ours, theirs}) do
			if world.technologies[case.research.name] then
				world.technologies[case.research.name].researched = true
			end
			for _, effect in ipairs(case.research.prototype.effects) do
				if effect.type == "unlock-recipe" then
					world.recipes[effect.recipe].enabled = true
				end
			end
		end
		local event = always and {research = {}} or {research = case.research}
		local mod = load_module(ours.prototype_recipes)
		mod.unlock_variants(COH_ALSO, always, ours, event)
		original(always, theirs, event)
		local label = case.name .. (always and " (always)" or "")
		check(enabled_list(ours) == enabled_list(theirs), label .. ": the enabled recipes match Voidcraft's loop\n  ours:   "
			.. enabled_list(ours) .. "\n  theirs: " .. enabled_list(theirs))
		check(sorted(ours_cleared) == sorted(theirs_cleared), label .. ": the cleared notifications match Voidcraft's loop\n  ours:   "
			.. sorted(ours_cleared) .. "\n  theirs: " .. sorted(theirs_cleared))
	end
end

-- A research that unlocks a base recipe: the variants of exactly that recipe follow, and the extra coherence recipe too.
-- Another base recipe that a script enabled waits for the next full pass.
do
	local force, cleared = build({"vc-circuit", "vc-a"}, TECHNOLOGIES)
	local mod = load_module(force.prototype_recipes)
	mod.unlock_variants(COH_ALSO, false, force, {research = technology("circuit-tech", {"vc-circuit"})})
	check(force.recipes["vc-circuit-flx"].enabled and force.recipes["vc-circuit-coh"].enabled, "the variants of the unlocked recipe are enabled")
	check(force.recipes["vc-circuit-extra-coh"].enabled, "the recipe that goes with the coherence variant is enabled")
	check(not force.recipes["vc-a-flx"].enabled and not force.recipes["vc-a-qual"].enabled and not force.recipes["vc-a-coh"].enabled,
		"the variants of a recipe the research does not unlock wait for the next full pass")
	check(#cleared == 3, "three notifications cleared, got " .. #cleared)
	mod.unlock_variants(COH_ALSO, true, force, {research = {}})
	check(force.recipes["vc-a-flx"].enabled and force.recipes["vc-a-qual"].enabled and force.recipes["vc-a-coh"].enabled,
		"a full pass enables the variants that waited")
end

-- The three technologies that switch variant kinds on make a full pass.
for _, name in ipairs(TECHNOLOGIES) do
	local force = build({"vc-a", "vc-b", "vc-c", "vc-circuit"}, {"s6x-void-flux", name})
	local mod = load_module(force.prototype_recipes)
	mod.unlock_variants(COH_ALSO, false, force, {research = technology(name)})
	check(force.recipes["vc-b-flx"].enabled and force.recipes["vc-a-flx"].enabled, name .. " enables the flux variants of every enabled base recipe")
end

-- Without the quality mod, or with no-quality, the quality variants stay off.
for _, mods in ipairs({{}, {quality = "2.1.0", ["no-quality"] = "1.0.0"}}) do
	local saved = {}
	for key, value in pairs(active_mods) do
		saved[key] = value
		active_mods[key] = nil
	end
	for key, value in pairs(mods) do
		active_mods[key] = value
	end
	local force = build({"vc-a"}, {"s6x-void-flux", "s6x-void-quality"})
	local mod = load_module(force.prototype_recipes)
	mod.unlock_variants(COH_ALSO, true, force, {research = {}})
	check(force.recipes["vc-a-flx"].enabled and not force.recipes["vc-a-qual"].enabled, "no quality variants without the quality mod")
	for key in pairs(active_mods) do
		active_mods[key] = nil
	end
	for key, value in pairs(saved) do
		active_mods[key] = value
	end
end

-- Before the flux technology nothing is enabled, and a missing technology does not fail.
do
	local force = build({"vc-a"}, {"s6x-void-quality"})
	local mod = load_module(force.prototype_recipes)
	mod.unlock_variants(COH_ALSO, true, force, {research = {}})
	check(enabled_list(force) == "vc-a", "nothing is enabled before the flux technology")
	force.technologies["s6x-void-coherence"] = nil
	force.technologies["s6x-void-flux"].researched = true
	mod.unlock_variants(COH_ALSO, true, force, {research = {}})
	check(force.recipes["vc-a-flx"].enabled and not force.recipes["vc-a-coh"].enabled, "a missing technology counts as not researched")
	force.technologies["s6x-void-flux"] = nil
	mod.unlock_variants(COH_ALSO, true, force, {research = {}})
end

-- The list of base recipes is built once.
do
	local force = build({}, {"s6x-void-flux"})
	local walks = 0
	rawset(_G, "prototypes", {recipe = setmetatable({}, {
		__index = force.prototype_recipes,
		__pairs = function()
			walks = walks + 1
			return next, force.prototype_recipes, nil
		end,
	})})
	package.loaded["scripts.compat.voidcraft_variants"] = nil
	local mod = require("scripts.compat.voidcraft_variants")
	for _ = 1, 3 do
		mod.unlock_variants(COH_ALSO, false, force, {research = technology("x", {"vc-a"})})
	end
	check(walks == 1, "the prototypes are walked once, not for every research (walked " .. walks .. ")")
end

-- control.lua registers the interface at load, before the event registry installs its handlers.
do
	local file = assert(io.open("control.lua", "r"))
	local source = file:read("*a")
	file:close()
	local registration = assert(source:find("voidcraft_variants.register()", 1, true), "control.lua registers the interface")
	local install = assert(source:find("events:install()", 1, true))
	check(registration < install, "the interface is registered before the handlers are installed")
end

print("voidcraft_variants: ok")
