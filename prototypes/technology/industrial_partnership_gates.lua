-- Interplanetary partnerships become milestones for the next system frontier.
local M = {}
local mode = require("prototypes.compat.interdependence_mode")
local Graph = require("__razi_lib__/lib/technology_graph")
local optional = require("prototypes.system.optional_worlds")

M.phases = {
	-- One cross-system workshop before the middle stars.
	{
		gates = { "vibrant-discovery", "vespera-discovery" },
		count = 1,
		candidates = {
			{ name = "razi-bio-rare-metal-casting" },
		},
	},
	-- One applied project from each middle branch before the outer stars: Paracelsin's coils on
	-- Panglia optics, and the catapult corridors of Muria, Rubia and Aquilo.
	{
		gates = { "beetlejuice-discovery", "umbra-discovery" },
		count = 2,
		candidates = {
			{ name = "razi-network-bond-paracelsin-coils", source = "planet-discovery-paracelsin" },
			{ name = "razi-orbital-catapult", source = "planet-discovery-rubia" },
		},
	},
}

local function technologies()
	return data.raw.technology or {}
end

local function active(name)
	local node = technologies()[name]
	return node and node.hidden ~= true and node.enabled ~= false
end

local function depends_on(name, ancestor)
	return Graph.reaches(technologies(), name, ancestor)
end

local function optional_requirements(candidate)
	local locations, packs = {}, {}
	for _, world in ipairs(optional.worlds or {}) do
		for _, location in ipairs(world.locations or {}) do
			locations[location] = true
		end
		for _, pack in ipairs(world.packs or {}) do
			packs[pack] = true
		end
	end

	local techs = technologies()
	local pending, visited = { candidate }, {}
	while #pending > 0 do
		local name = pending[#pending]
		pending[#pending] = nil
		if not visited[name] then
			visited[name] = true
			local node = techs[name]
			if node then
				for _, effect in ipairs(node.effects or {}) do
					local location = effect.type == "unlock-space-location" and effect.space_location
					if location and locations[location] then
						return "requires optional world " .. location
					end
				end
				for _, ingredient in ipairs((node.unit or {}).ingredients or {}) do
					local pack = ingredient.name or ingredient[1]
					if packs[pack] then
						return "uses optional science pack " .. pack
					end
				end
				for _, parent in ipairs(node.prerequisites or {}) do
					if not visited[parent] then
						pending[#pending + 1] = parent
					end
				end
			end
		end
	end
end

local function note(message)
	if log then
		log("[Razi/partnerships] " .. message)
	end
end

local function eligible(candidate, phase)
	local node = technologies()[candidate.name]
	if not (active(candidate.name) and node.unit and node.unit.ingredients and #node.unit.ingredients > 0) then
		return false
	end

	local optional_reason = optional_requirements(candidate.name)
	if optional_reason then
		note("skip " .. candidate.name .. ": " .. optional_reason)
		return false
	end

	for _, gate in ipairs(phase.gates) do
		if not active(gate) or depends_on(candidate.name, gate) then
			return false
		end
	end

	if candidate.source and not depends_on(candidate.name, candidate.source) then
		return false
	end

	-- Never attach missing, hidden or disabled upstream research to a gate.
	for _, parent in ipairs(node.prerequisites or {}) do
		if not active(parent) then
			return false
		end
	end
	return true
end

local function remove_link(gate, candidate)
	local node = technologies()[gate]
	local prerequisites = node and node.prerequisites
	if not prerequisites then
		return
	end
	for index = #prerequisites, 1, -1 do
		if prerequisites[index] == candidate then
			table.remove(prerequisites, index)
			return
		end
	end
end

local function link(candidate, phase)
	local added = {}
	local links = 0
	for _, gate in ipairs(phase.gates) do
		if depends_on(gate, candidate.name) then
			links = links + 1
		elseif Graph.add_prerequisite(technologies(), gate, candidate.name) then
			added[#added + 1] = gate
			links = links + 1
		else
			for _, previous_gate in ipairs(added) do
				remove_link(previous_gate, candidate.name)
			end
			return false, gate
		end
	end
	return true, links
end

function M.data_final_fixes()
	if not mode.enabled() then
		return
	end

	for phase_index, phase in ipairs(M.phases) do
		local count, links = 0, 0
		for _, candidate in ipairs(phase.candidates) do
			if count >= phase.count then
				break
			end
			if eligible(candidate, phase) then
				local linked, result = link(candidate, phase)
				if linked then
					count = count + 1
					links = links + result
				else
					note("skip " .. candidate.name .. ": could not add prerequisite to " .. result)
				end
			end
		end
		note("phase " .. phase_index .. ": " .. links .. " gate links")
	end
end

return M
