-- Tier the system cards across the EXISTING laboratories of other mods.
-- This module defines no entities, items, recipes or labs and does not touch lab recipes.
local M = {}

local cards = {
	"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card",
	"vibrant-tech-card", "vespera-tech-card", "beetlejuice-tech-card",
	"umbra-tech-card", "deep-space-tech-card"
}
M.cards = cards

M.rank = {
	["calidus-tech-card"] = 1,
	["solaris-tech-card"] = 2, ["nyxaris-tech-card"] = 2,
	["vibrant-tech-card"] = 3, ["vespera-tech-card"] = 3,
	["beetlejuice-tech-card"] = 4, ["umbra-tech-card"] = 4,
	["deep-space-tech-card"] = 5
}

-- Each name belongs to its original mod. Moshine's thermodynamics lab gives the middle pair
-- its own tier; if it is absent, K2SO's advanced lab takes that tier instead of a new machine.
M.native = {
	["lab"] = 1, ["biolab"] = 2, ["kr-advanced-lab"] = 2,
	["thermodynamics-lab"] = 3,
	["pressure-lab"] = 4, ["kr-singularity-lab"] = 4, ["omega-lab"] = 5
}

-- Lab order for the fallback in restore_science (native lab names only).
local fallback_labs = {
	"thermodynamics-lab", "kr-advanced-lab", "kr-singularity-lab",
	"pressure-lab", "omega-lab", "biolab", "lab"
}

local function tool(name)
	return (data.raw.tool or {})[name]
end

local function add(inputs, name, seen)
	if not seen[name] then
		inputs[#inputs + 1] = name
		seen[name] = true
	end
end

local function accepts(lab, science)
	if not (lab and lab.inputs) then return false end
	local present = {}
	for _, id in ipairs(lab.inputs) do present[id] = true end
	for _, id in ipairs(science) do
		if not present[id] then return false end
	end
	return true
end

-- A lab keeps every non-Razi input and only the system cards up to its own tier.
local function assign_labs()
	local labs = data.raw.lab or {}
	if not labs["thermodynamics-lab"] then
		M.native["kr-advanced-lab"] = 3
	end
	for name, tier in pairs(M.native) do
		local lab = labs[name]
		if lab and lab.inputs then
			local fresh, seen = {}, {}
			for _, input in ipairs(lab.inputs) do
				local level = M.rank[input]
				if not level or level <= tier then add(fresh, input, seen) end
			end
			for _, card in ipairs(cards) do
				if M.rank[card] <= tier and tool(card) then
					add(fresh, card, seen)
				end
			end
			lab.inputs = fresh
		end
	end
end

-- Every technology that costs a system card must be researchable in some lab that accepts
-- ALL of its packs. If none does, give the cards to the nearest native lab that already
-- accepts all the non-Razi packs (preferring the card's tier and above).
local function restore_science()
	local labs = data.raw.lab or {}
	local names = {}
	for name in pairs(data.raw.technology or {}) do names[#names + 1] = name end
	table.sort(names)
	for _, tech_name in ipairs(names) do
		local tech = data.raw.technology[tech_name]
		local unit = tech.unit
		if tech.enabled ~= false and not tech.hidden
			and unit and unit.ingredients and #unit.ingredients > 0 then
			local all, own, other = {}, {}, {}
			local tier = 1
			for _, part in ipairs(unit.ingredients) do
				---@cast part table
				local name = part.name or part[1]
				if name then
					all[#all + 1] = name
					if M.rank[name] then
						own[#own + 1] = name
						tier = math.max(tier, M.rank[name])
					else
						other[#other + 1] = name
					end
				end
			end
			if #own > 0 then
				local satisfied = false
				for _, lab in pairs(labs) do
					if accepts(lab, all) then satisfied = true break end
				end
				if not satisfied then
					local ordered = {}
					for level = tier, 5 do ordered[#ordered + 1] = level end
					for level = tier - 1, 1, -1 do ordered[#ordered + 1] = level end
					local selection
					for _, level in ipairs(ordered) do
						for _, name in ipairs(fallback_labs) do
							if M.native[name] == level and accepts(labs[name], other) then
								selection = labs[name]
								break
							end
						end
						if selection then break end
					end
					if selection then
						local seen = {}
						for _, name in ipairs(selection.inputs) do seen[name] = true end
						for _, name in ipairs(own) do add(selection.inputs, name, seen) end
						log("Razi science: " .. tech_name .. " needs cards that no lab took, widened "
							.. selection.name)
					else
						log("Razi science: no installed lab accepts all native packs for " .. tech_name)
					end
				end
			end
		end
	end
end

function M.data_final_fixes()
	assign_labs()
	restore_science()
end

return M
