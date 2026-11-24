local M = {}
local Science = require("__razi_lib__/lib/science")

-- 248k's stage roots use these family prefixes (248k-Redux/prototypes/248k_techs.lua:933,1888,3148).
local stages = {
	{
		prefix = "fi_",
		card = "solaris-tech-card",
		gate = "planet-discovery-castra",
	},
	{
		prefix = "fu_",
		card = "vibrant-tech-card",
		gate = "planet-discovery-ribbonia",
	},
	{
		prefix = "gr_",
		card = "deep-space-tech-card",
		gate = "razi-singularity-theory",
	},
}

local function technologies()
	return data.raw.technology or {}
end

local function ancestor(start, wanted, seen)
	if start == wanted then
		return true
	end

	local technology = technologies()[start]
	if not technology then
		return false
	end

	seen = seen or {}
	if seen[start] then
		return false
	end
	seen[start] = true

	for _, prerequisite in ipairs(technology.prerequisites or {}) do
		if ancestor(prerequisite, wanted, seen) then
			return true
		end
	end

	return false
end

local function has_stage_prerequisite(technology, prefix)
	for _, prerequisite in ipairs(technology.prerequisites or {}) do
		if prerequisite:sub(1, #prefix) == prefix then
			return true
		end
	end

	return false
end

local function has_ingredient(ingredients, name)
	for _, ingredient in ipairs(ingredients or {}) do
		if (ingredient.name or ingredient[1]) == name then
			return true
		end
	end

	return false
end

local function add_gate(technology_name, gate_name)
	local technology = technologies()[technology_name]
	local gate = technologies()[gate_name]
	if not (technology and gate) or technology_name == gate_name
		or ancestor(gate_name, technology_name) or ancestor(technology_name, gate_name) then
		return false
	end

	technology.prerequisites = technology.prerequisites or {}
	technology.prerequisites[#technology.prerequisites + 1] = gate_name
	return true
end

local function note(message)
	if log then
		log("razi-protocol: 248k: " .. message)
	end
end

local function process_stage(stage)
	local tools = data.raw.tool or {}
	local techs = technologies()

	if not tools[stage.card] then
		note(stage.prefix .. " stage left as is, no " .. stage.card)
		return
	end
	if not techs[stage.gate] then
		note(stage.prefix .. " stage left as is, no " .. stage.gate)
		return
	end

	local names = {}
	for name, technology in pairs(techs) do
		if name:sub(1, #stage.prefix) == stage.prefix
			and not technology.hidden and technology.enabled ~= false then
			names[#names + 1] = name
		end
	end
	table.sort(names)

	local with_card = 0
	local new_gates = {}
	for _, name in ipairs(names) do
		local technology = techs[name]
		if technology.unit then
			technology.unit.ingredients = technology.unit.ingredients or {}
			Science.add_pack(technology.unit.ingredients, stage.card, 1)
			if has_ingredient(technology.unit.ingredients, stage.card) then
				with_card = with_card + 1
			end
		end

		if not has_stage_prerequisite(technology, stage.prefix)
			and add_gate(name, stage.gate) then
			new_gates[#new_gates + 1] = name
		end
	end

	local gate_list = #new_gates > 0 and table.concat(new_gates, ", ") or "none"
	note(stage.prefix .. " stage uses " .. stage.card .. ": " .. with_card
		.. " technologies with card; new gates: " .. gate_list)
end

function M.data_final_fixes()
	if not (mods and mods["248k-Redux"]) then
		return
	end

	for _, stage in ipairs(stages) do
		process_stage(stage)
	end
end

return M
