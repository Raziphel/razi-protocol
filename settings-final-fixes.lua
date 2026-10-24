local adjust_maraxsis = data.raw["bool-setting"] and data.raw["bool-setting"]["adjust-maraxsis"]

if adjust_maraxsis then
	adjust_maraxsis.default_value = false
	adjust_maraxsis.forced_value = false
	adjust_maraxsis.hidden = true
end

-- Startup settings of the Arcanyx family (Arcanyx, IridescentIndustry, Voidcraft), Balack, Nulla and Crushing Industry
-- (which PlanetAthos requires) whose default or opt-in value rewrites vanilla, Krastorio 2 or Space Age progression, or
-- removes what Razi Protocol relies on, and of Rigor Module (which Planet Crucible requires) whose default would push
-- the recipe count past the engine limit. Each is pinned and hidden; a missing mod or setting is skipped.
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
	-- and, on the wider steps of the enemy homes, Panglia and Crucible (compat/armoured_biters.lua), which would then
	-- have no enemies at all. With false the nest stays; switching it off by name keeps it off Nauvis.
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
}

for name, value in pairs(pinned_bool_settings) do
	local setting = data.raw["bool-setting"] and data.raw["bool-setting"][name]
	if setting then
		setting.default_value = value
		setting.forced_value = value
		setting.hidden = true
	end
end

-- Default "ii": IridescentIndustry deletes the Krastorio 2 air purifier, pollution filter and air cleaning recipes
-- and hides the kr-air-purification technology. "kr" keeps Krastorio 2 and adds no second purifier ("both" would).
local pinned_string_settings = {
	["s6x-ii-krastorio-overlap-tech"] = "kr",
}

for name, value in pairs(pinned_string_settings) do
	local setting = data.raw["string-setting"] and data.raw["string-setting"][name]
	if setting then
		setting.default_value = value
		setting.allowed_values = { value }
		setting.hidden = true
	end
end
