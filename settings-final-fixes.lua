local adjust_maraxsis = data.raw["bool-setting"] and data.raw["bool-setting"]["adjust-maraxsis"]

if adjust_maraxsis then
	adjust_maraxsis.default_value = false
	adjust_maraxsis.forced_value = false
	adjust_maraxsis.hidden = true
end

-- Startup settings of the Arcanyx family (Arcanyx, IridescentIndustry, Voidcraft) and of Balack whose default or opt-in
-- value rewrites vanilla, Krastorio 2 or Space Age progression, or removes what Razi Protocol relies on. Each is pinned
-- and hidden; a missing mod or setting is skipped.
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
	-- (or, with the nest setting off, takes them out of the vanilla nests). Razi Protocol places that nest on Hyarion,
	-- Nexus, Crucible and Panglia (compat/armoured_biters.lua), which would then have no enemies at all. With false the
	-- nest stays; its tile restriction there keeps it off Nauvis.
	["bm-armored-biters-override"] = false,
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
