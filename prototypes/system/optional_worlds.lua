-- What the required path to the intergalactic transceiver (`razi-stable-intergalactic-singularity`) must never depend on.
--
-- The path takes in every installed world of a star system before the gateways of the next one
-- (technology/regional_research_bridges.lua, the roster is system/world_roster.lua). The worlds here are the
-- exceptions: their discovery and the science packs of their mods stay off the path. Their research may gate late
-- technologies of other mods.
--
-- Plain data with no requires: the pack's in-game tests load it from the control stage, and the offline test
-- (tests/lua/test_optional_worlds.lua) keeps it in step with info.json.
--   mod        the mod that adds the world (info.json dependency)
--   locations  space locations whose unlock effect marks a discovery the path must not need; empty when the
--              world is woven into the path and only its packs stay out
--   packs      science packs the mod adds that the path must not need
--   reason     why the world is not woven (or why its packs are not)
-- Woven worlds, with or without a mod of their own, are not listed unless a pack of theirs stays out.
-- Cerys and Dea Dia are woven (and so are Igrys, Foliax, Pelagos, Terra Palus, Shchierbin, Bellicos and the rest);
-- Secretas is a required dependency whose discovery and golden science are on the path anyway.
local M = {}

M.final_technology = "razi-stable-intergalactic-singularity"

M.worlds = {
	{mod = "planet-ferrum", locations = {}, packs = {"ferrum-robotics-science-pack"},
		reason = "the world opens before Outer Frontier Mastery; its robotics pack is made only on Ferrum"},
	{mod = "planet-rabbasca", locations = {}, packs = {"athletic-science-pack"},
		reason = "the world opens before Vibrant and Vespera; its athletic pack is made only on Rabbasca"},
	{mod = "rabbasca-underground", locations = {"rabbasca-underground"},
		packs = {"rabbasca-warpfield-science-pack", "rabbasca-imaginary-science-pack"},
		reason = "its research takes seven packs, among them Ferrum, Rabbasca and Athos"},
	{mod = "skewer_shattered_planet", locations = {"skewer_shattered_planet", "skewer_lost_beyond"},
		packs = {"ske_heu_science_pack", "ske_hep_science_pack", "ske_hea_science_pack",
			"ske_hec_science_pack", "ske_hef_science_pack"},
		reason = "its discovery takes the promethium science pack, which waits for the transceiver"},
	{mod = "biological-machines-planet-balack", locations = {"bm-balack"}, packs = {},
		reason = "a side trip behind Aquilo; its discovery takes the Ferrum, interstellar and particulate packs"},
	{mod = "moon-eneas", locations = {"eneas"}, packs = {},
		reason = "its discovery is a chain of eight build and craft triggers"},
	{mod = "Nexus-Updated", locations = {"nexus"}, packs = {},
		reason = "its discovery waits for the transceiver signal"},
}

return M
