-- Research a 2.x save has already passed but that 3.0 now asks for.
-- Run once by migrations/3.0.0.lua when a 2.x save first loads with 3.x.
-- Nothing is taken away: only technologies that are not researched yet are granted.
local M = {}

local SKIPPED_FORCES = {enemy = true, neutral = true}

-- The research that needs the transceiver chain to be complete.
local SINGULARITY_THEORY = "razi-singularity-theory"
-- New ancestors of that research: a save that has the research has passed them.
local SINGULARITY_ANCESTORS = {"vespera-discovery", "umbra-discovery", "razi-outer-frontier-mastery"}

-- Asteroid belt surveys. A world is "behind" a belt when it cannot be reached from the home
-- planet without passing through the locations the survey unlocks.
local HOME = "nauvis"
local BELT_SURVEYS = {"space-discovery-asteroid-belt", "razi-umbra-belt-survey"}

local function unlocked_locations(technology)
	local locations = {}
	for _, effect in pairs(technology.effects or {}) do
		if effect.type == "unlock-space-location" and effect.space_location then
			locations[effect.space_location] = true
		end
	end
	return locations
end

-- Locations in the connection graph reached from the home planet, never passing through `closed`.
local function reachable(neighbours, closed)
	local reached, queue = {[HOME] = true}, {HOME}
	local head = 1
	while queue[head] do
		local current = queue[head]
		head = head + 1
		for _, other in ipairs(neighbours[current] or {}) do
			if not closed[other] and not reached[other] then
				reached[other] = true
				queue[#queue + 1] = other
			end
		end
	end
	return reached
end

-- Locations behind a belt: cut off from the home planet while the belt locations are closed, but
-- reachable once they are open. A place that has no route to home at all is not behind anything.
local function cut_off_by(belt)
	local neighbours = {}
	local function link(a, b)
		neighbours[a] = neighbours[a] or {}
		neighbours[a][#neighbours[a] + 1] = b
	end
	for _, connection in pairs(prototypes.space_connection) do
		local from, to = connection.from.name, connection.to.name
		link(from, to)
		link(to, from)
	end

	local closed = reachable(neighbours, belt)
	local open = reachable(neighbours, {})
	local cut_off = {}
	for location in pairs(open) do
		if not closed[location] and not belt[location] then
			cut_off[location] = true
		end
	end
	return cut_off
end

-- Survey name -> names of the technologies that unlock a world behind that survey's belt.
local function surveys_and_gates()
	local result = {}
	if not prototypes.space_location[HOME] then
		return result
	end
	for _, survey in ipairs(BELT_SURVEYS) do
		local prototype = prototypes.technology[survey]
		if prototype then
			local cut_off = cut_off_by(unlocked_locations(prototype))
			local gates = {}
			for name, other in pairs(prototypes.technology) do
				for location in pairs(unlocked_locations(other)) do
					if cut_off[location] then
						gates[#gates + 1] = name
						break
					end
				end
			end
			table.sort(gates)
			result[#result + 1] = {survey = survey, gates = gates}
		end
	end
	return result
end

local function has_research(force)
	for _, technology in pairs(force.technologies) do
		if technology.researched then
			return true
		end
	end
	return false
end

local function grant(force, name, granted)
	local technology = force.technologies[name]
	if technology and not technology.researched then
		technology.researched = true
		granted[#granted + 1] = name
	end
end

local function any_researched(force, names)
	for _, name in ipairs(names) do
		local technology = force.technologies[name]
		if technology and technology.researched then
			return true
		end
	end
	return false
end

function M.run()
	local surveys = surveys_and_gates()
	for _, force in pairs(game.forces) do
		if not SKIPPED_FORCES[force.name] and has_research(force) then
			local granted = {}

			-- A save that went through the whole chain has passed these gates.
			local theory = force.technologies[SINGULARITY_THEORY]
			if theory and theory.researched then
				for _, name in ipairs(SINGULARITY_ANCESTORS) do
					grant(force, name, granted)
				end
			end

			-- A discovered world behind a belt means the belt has been crossed.
			for _, entry in ipairs(surveys) do
				if any_researched(force, entry.gates) then
					grant(force, entry.survey, granted)
				end
			end

			if #granted > 0 then
				log("[Razi Protocol/migration] " .. force.name .. ": " .. table.concat(granted, ", "))
			end
		end
	end
end

return M
