local pinned_foreign_settings = {}

-- Startup settings of the Arcanyx family (Arcanyx, IridescentIndustry, Voidcraft), Balack, Nulla and Crushing Industry
-- (which PlanetAthos requires) whose default or opt-in value rewrites vanilla, Krastorio 2 or Space Age progression, or
-- removes what Razi Protocol relies on, of Rigor Module (which Planet Crucible requires) whose default would push the
-- recipe count past the engine limit, and of Renai Transportation, whose parts Ribbonia needs. Each is pinned and
-- hidden; a missing mod or setting is skipped.
-- Settings where only the default changes and the player keeps the choice are in default_only_bool_settings.
local pinned_bool_settings = {
	-- Default true: IridescentIndustry makes nuclear-power require s6x-mythril, which sits behind
	-- planet-discovery-arcanyx and umbra-discovery. Nuclear power, Cerys, K2 fusion and spidertron would move to the
	-- last system, and nuclear-reactor / uranium-fuel-cell would need mythril plates.
	["s6x-arcanyx-mythril-nuclear"] = false,
	-- Opt-in: strips surface_conditions from every recipe of the pack and from the crusher and captive biter spawner.
	["s6x-location-unlock"] = false,
	-- Opt-in: puts prismite on Nauvis and adds mythril or prismite to low-density-structure, space-platform-foundation
	-- and the starter pack, so early Space Age recipes would need Arcanyx ore.
	["s6x-prismite-on-nauvis"] = false,
	-- Default true: redefines the ten Planetaris refined concrete tiles (new layer, mined into vanilla-named colored
	-- concrete instead of the planetaris-* items) and adds a second set of colored concrete recipes and dyes.
	["s6x-colored-concrete"] = false,
	-- Default true: Balack removes the armoured biters' own nest from the map generator and hides the armoured biters
	-- (or, with the nest setting off, takes them out of the vanilla nests). Razi Protocol places that nest on Hyarion
	-- and, on the wider steps of the enemy homes, Panglia and Crucible
	-- (prototypes/compatibility/ArmouredBiters/armoured_biters.lua), which
	-- would then have no enemies at all. With false the nest stays; switching
	-- it off by name keeps it off Nauvis.
	["bm-armored-biters-override"] = false,
	-- Default true: Nulla adds robotic-science-pack to the price and prerequisites of follower-robot-count-5, which is
	-- first-system research; it would wait for Nulla's discovery in Vespera. The other two Nulla science settings only
	-- touch research that is already behind Vespera (promethium-science-pack, research-productivity) and stay on.
	["nulla-vanila-science"] = false,
	-- Default true: with Krastorio 2 present, Crushing Industry replaces the K2 sand and glass recipes: kr-glass is
	-- hidden in favour of its own glass recipe, and the kr-sand recipe loses its unlock in kr-stone-processing to the
	-- Crushing Industry sand recipe. Off, the K2 recipes stay (this needs the glass setting below off as well).
	["crushing-industry-k2"] = false,
	-- Default true: Crushing Industry adds glass to lab, chemical-plant, solar-panel, laser-turret, the rail signals,
	-- small-lamp and others. With the K2 replacement off the added glass becomes kr-glass beside the kr-glass that K2
	-- already has in small-lamp, and the game refuses to load (duplicate ingredient); with it on, the K2 glass recipe
	-- is replaced.
	["crushing-industry-glass"] = false,
	-- Default true: optical-fiber is made from the Crushing Industry glass and added to advanced-circuit. PlanetAthos
	-- and Muluna read this setting and expect the item, which does not exist without glass.
	["crushing-industry-optical-fiber"] = false,
	-- Default true: swaps the concrete item for a concrete-mix fluid in 36 recipes (K2 kr-fusion-reactor and
	-- kr-crush-concrete, nuclear-reactor, rocket-silo, centrifuge, cargo-landing-pad, rail ramps, the Planetaris
	-- concretes and others), moves them to fluid crafting and takes them out of hand crafting.
	["crushing-industry-concrete-mix"] = false,
	-- Default true: the vanilla crusher gets a base effect of +12.5 % quality and +25 % productivity and four
	-- quality-module-2 in its recipe (crushing-industry base-data-updates.lua:17-20). Asteroid chunks and their
	-- crushed products then come out with quality on every platform, and quality items block ordinary belts,
	-- filters and recipes. The productivity and the faster crusher of the same mod stay.
	["crushing-industry-space-crusher-quality"] = false,
	-- Default false: Rigor Module copies every recipe with a chance among its products into hidden
	-- <recipe>__rigor_module_mod__<N> variants, one per rigor step (25 776 copies of 395 recipes in the full pack), and
	-- the game stops at 65 535 recipes ("Reached id limit for recipe"). In compatibility mode only the vanilla recipes
	-- (next setting) and the recipes that Planet Crucible and Muluna whitelist get copies, so rigor modules keep
	-- working on those and the other recipes are left alone.
	["rigor-module-compatibility-mode"] = true,
	-- Default true: keeps the vanilla and Space Age recipes (uranium processing, scrap recycling, yumako and jellynut
	-- processing, bacteria, asteroid crushing and reprocessing) among those that get rigor copies in compatibility mode.
	["rigor-module-compatibility-mode-include-vanilla"] = true,
	-- Default false: Voidcraft machines and recipes can be built and run anywhere, including on space platforms, where
	-- they make fuel, asteroid chunks, foundation and ores of every planet from nothing, and void-fuel returns 12 MJ for
	-- 2.5 MJ of electricity. With true the machines and all voidcrafting recipes need magic = 100, which only Arcanyx has.
	["s6x-arcanyx-voidcraft"] = true,
	-- Default true: Ribbonia (renai-updates.lua) rewrites the recipes and technologies of the Renai Transportation
	-- throwers, bounce plates, primer plates and train ramps without checking that they exist. With any of these three
	-- off the game does not start ("attempt to index field 'PrimerBouncePlate' (a nil value)").
	["RTThrowersSetting"] = true,
	["RTBounceSetting"] = true,
	["RTTrainRampSetting"] = true,
	-- Default true: zircon is used in the stone furnace and other early recipes. False moves its use until after logistic
	-- science (bzzirconium/zirconium-recipe-updates.lua:32-34).
	["bzzirconium-early"] = false,
	-- RSC makes every stage non-minable immediately after placement when enabled, so the site cannot be dismantled for
	-- its stage materials (Rocket-Silo-Construction/control.lua:217, 377).
	["rsc-st-not-removable-site"] = true,
}

-- These recipes are left untouched by BZ. bypass() is global in each mod's data-util.lua, so the last loaded mod
-- provides the function and its recipe list applies to all six (bzlead/data-util.lua:110; bztitanium/data-util.lua:110;
-- bztin/data-util.lua:110; bzzirconium/data-util.lua:110; bzcarbon/data-util.lua:110; bzsilicon/data-util.lua:110).
-- For scrap-recycling, BZ sets independent_probability on existing shared_probability
-- (bzcarbon/data-util.lua:1181; bzlead/lead-recipe-updates.lua:8-12; bztin/tin-recipe-updates.lua:13-15;
-- bzcarbon/carbon-recipe-updates.lua:53-55).
local bz_recipe_bypass = "pipe,pipe-to-ground,electronic-circuit,advanced-circuit,processing-unit,steel-plate,space-platform-foundation,sulfuric-acid,plastic-bar,scrap-recycling"

-- Default "ii": IridescentIndustry deletes the Krastorio 2 air purifier, pollution filter and air cleaning recipes
-- and hides the kr-air-purification technology. "kr" keeps Krastorio 2 and adds no second purifier ("both" would).
local pinned_string_settings = {
	["s6x-ii-krastorio-overlap-tech"] = "kr",
	["bzlead-recipe-bypass"] = bz_recipe_bypass,
	["bztitanium-recipe-bypass"] = bz_recipe_bypass,
	["bztin-recipe-bypass"] = bz_recipe_bypass,
	["bzzirconium-recipe-bypass"] = bz_recipe_bypass,
	["bzcarbon-recipe-bypass"] = bz_recipe_bypass,
	["bzsilicon-recipe-bypass"] = bz_recipe_bypass,
	-- Default "yes" adds the bzlead expansion bolts and buildings. Foliax then copies the bolt recipe with foliax-iron-bar,
	-- an item that does not exist, and the game does not start (bzlead/settings.lua:17-20; foliax/prototypes/mod-compat.lua:368).
	["bzlead-more-entities"] = "no",
}

-- The stage power draw is 150 MW times this multiplier (Rocket-Silo-Construction/prototypes/entities.lua:7).
-- The cost multiplier applies to ingredients of stages 2, 4, 5 and 6
-- (Rocket-Silo-Construction/prototypes/recipe.lua:93-123, 269-276).
local pinned_double_settings = {
	["rsc-st-power-mp"] = 0.5,
	["rsc-st-cost-mp"] = 1,
}

-- Crushing Industry's coal setting replaces coal in recipes at crushing-industry_0.6.9/base-data-updates.lua:83-94.
-- Keep it visible and change only its default so a saved player choice still wins.
-- Nexus 1.4.0: with nexus-limit-frame-in-hand-only (per player, off by default, Nexus/settings.lua:10-15) the limit
-- frame shows only while the player holds a zero-point energy engine core; otherwise it stays on screen all game.
local default_only_bool_settings = {
	["crushing-industry-coal"] = false,
	["nexus-limit-frame-in-hand-only"] = true,
	-- Default false: 248k Redux shares KI channels across surfaces; one KI core feeds modules to beacons on every planet
	-- and platform (248k-Redux/scripts/electronic/el_ki_script.lua:414-422). With true, a beacon takes modules only from a
	-- core on its own surface. The setting stays visible, so the map admin can switch it.
	["el_ki_same_surface"] = true,
}

-- Big-Monsters 2.2.1: changing either per-player camera setting ends the game with a non-recoverable error. The handler
-- of on_runtime_mod_setting_changed reads ic_draggable_camera and ic_camera_size, names that do not exist (the settings
-- are bm_*: control.lua:49-56, settings.lua:365,373), so the settings never worked either. They are hidden: every
-- player keeps the defaults and the handler never runs.
local hidden_settings = {
	{ "bool-setting", "bm_draggable_camera" },
	{ "int-setting", "bm_camera_size" },
}

function pinned_foreign_settings.settings_final_fixes()
	local adjust_maraxsis = data.raw["bool-setting"] and data.raw["bool-setting"]["adjust-maraxsis"]

	if adjust_maraxsis then
		adjust_maraxsis.default_value = false
		adjust_maraxsis.forced_value = false
		adjust_maraxsis.hidden = true
	end

	for name, value in pairs(pinned_bool_settings) do
		local setting = data.raw["bool-setting"] and data.raw["bool-setting"][name]
		if setting then
			setting.default_value = value
			setting.forced_value = value
			setting.hidden = true
		end
	end

	for name, value in pairs(pinned_string_settings) do
		local setting = data.raw["string-setting"] and data.raw["string-setting"][name]
		if setting then
			setting.default_value = value
			setting.allowed_values = { value }
			setting.hidden = true
		end
	end

	for name, value in pairs(pinned_double_settings) do
		local setting = data.raw["double-setting"] and data.raw["double-setting"][name]
		if setting then
			setting.default_value = value
			setting.allowed_values = { value }
			setting.hidden = true
		end
	end

	for name, value in pairs(default_only_bool_settings) do
		local setting = data.raw["bool-setting"] and data.raw["bool-setting"][name]
		if setting then
			setting.default_value = value
		end
	end

	for _, entry in ipairs(hidden_settings) do
		local setting = data.raw[entry[1]] and data.raw[entry[1]][entry[2]]
		if setting then
			setting.hidden = true
		end
	end
end

return pinned_foreign_settings
