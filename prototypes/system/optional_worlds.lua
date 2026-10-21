-- Worlds that the required path to the intergalactic transceiver must never depend on: optional mods
-- (`?` and `+` in info.json) and side trips (community_expansions.lua). Their research may gate late technologies
-- of other mods, but nothing on the way to `razi-stable-intergalactic-singularity` may need their discovery,
-- their science packs or the technologies that unlock those packs.
--
-- Plain data with no requires: the pack's in-game tests load it from the control stage, and the offline test
-- (tests/lua/test_optional_worlds.lua) keeps it in step with info.json.
--   mod        the mod that adds the world (info.json dependency)
--   locations  space locations whose unlock effect marks the discovery
--   packs      science packs the mod adds
-- Cerys and Dea Dia are not here: razi-protocol puts them on the path on purpose (regional_research_bridges.lua:17-19,
-- technology/progression.lua:268-286).
-- Secretas is not here: it is a required dependency and its discovery and golden science are on the path.
local M = {}

M.final_technology = "razi-stable-intergalactic-singularity"

M.worlds = {
	{mod = "planet-ferrum", locations = {"ferrum"},
		packs = {"ferrum-robotics-science-pack"}},
	{mod = "planet-rabbasca", locations = {"rabbasca"},
		packs = {"athletic-science-pack"}},
	{mod = "rabbasca-underground", locations = {"rabbasca-underground"},
		packs = {"rabbasca-warpfield-science-pack", "rabbasca-imaginary-science-pack"}},
	{mod = "skewer_shattered_planet", locations = {"skewer_shattered_planet", "skewer_lost_beyond"},
		packs = {"ske_heu_science_pack", "ske_hep_science_pack", "ske_hea_science_pack",
			"ske_hec_science_pack", "ske_hef_science_pack"}},
	-- a required dependency, but a side trip: its research and bio-factory stay out of the milestones
	{mod = "biological-machines-planet-balack", locations = {"bm-balack"}, packs = {}},
}

return M
