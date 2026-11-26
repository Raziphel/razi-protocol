local M = {}
local Science = require("__razi_lib__/lib/science")
local Graph = require("__razi_lib__/lib/technology_graph")

-- Mech Armor Expanded places its tiers after mech-armor without chapter cards
-- (mech-armor-expanded/prototypes/technology.lua:16,39,65). Razi assigns each tier a chapter card and gate.
local tiers = {
	{
		name = "mech-armor-mk2",
		card = "vibrant-tech-card",
		extra = "military-mk2-science-pack",
		gate = "planet-discovery-ribbonia",
	},
	{
		name = "mech-armor-mk3",
		card = "beetlejuice-tech-card",
		gate = "planet-discovery-cubium",
	},
	{
		name = "mech-armor-mk4",
		card = "deep-space-tech-card",
		gate = "razi-singularity-theory",
	},
}

local function note(message)
	if log then
		log("razi-protocol: mech-armor-expanded: " .. message)
	end
end

local function has_ingredient(ingredients, name)
	for _, ingredient in ipairs(ingredients or {}) do
		if (ingredient.name or ingredient[1]) == name then
			return true
		end
	end
	return false
end

function M.data_final_fixes()
	if not (mods and mods["mech-armor-expanded"]) then
		return
	end

	local technologies = data.raw.technology or {}
	for _, tier in ipairs(tiers) do
		local technology = technologies[tier.name]
		if technology and technology.unit then
			if not Science.exists(tier.card) then
				note(tier.name .. " left as is, no " .. tier.card)
			elseif not technologies[tier.gate] then
				note(tier.name .. " left as is, no " .. tier.gate)
			else
				technology.unit.ingredients = technology.unit.ingredients or {}
				Science.add_pack(technology.unit.ingredients, tier.card, 1)
				if tier.extra then
					Science.add_pack(technology.unit.ingredients, tier.extra, 1)
				end

				local gate_added = Graph.add_prerequisite(technologies, tier.name, tier.gate)
				local gate_status = gate_added and "added" or "already implied or would loop"
				local extra = tier.extra and has_ingredient(technology.unit.ingredients, tier.extra)
					and (" and " .. tier.extra) or ""
				note(tier.name .. " uses " .. tier.card .. extra .. "; gate " .. tier.gate .. " " .. gate_status)
			end
		end
	end
end

return M
