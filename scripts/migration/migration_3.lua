-- A 2.x save receives the technologies that open routes to its unlocked planets, because 3.x
-- routes pass through new systems.
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

local function route_technologies(force, already_granted)
	local locations = prototypes.space_location or {}
	if not locations[HOME] then
		return {}
	end

	local explicitly_open = {}
	for name in pairs(locations) do
		explicitly_open[name] = name == HOME
			or (force.is_space_location_unlocked and force.is_space_location_unlocked(name))
	end

	local opening_technologies, technology_locations = {}, {}
	for name, technology in pairs(prototypes.technology or {}) do
		if not technology.hidden then
			local unlocked = unlocked_locations(technology)
			for location in pairs(unlocked) do
				opening_technologies[location] = opening_technologies[location] or {}
				opening_technologies[location][#opening_technologies[location] + 1] = name
				technology_locations[name] = technology_locations[name] or {}
				technology_locations[name][location] = true
			end
		end
	end
	for _, names in pairs(opening_technologies) do
		table.sort(names)
	end

	local granted = {}
	for _, name in ipairs(already_granted or {}) do
		granted[name] = true
	end

	local function is_open(location)
		if explicitly_open[location] then
			return true
		end
		for _, name in ipairs(opening_technologies[location] or {}) do
			local technology = force.technologies[name]
			if granted[name] or (technology and technology.researched) then
				return true
			end
		end
		return false
	end

	local neighbours = {}
	for name, location in pairs(locations) do
		if not location.hidden and (is_open(name) or #(opening_technologies[name] or {}) > 0) then
			neighbours[name] = {}
		end
	end
	for _, connection in pairs(prototypes.space_connection or {}) do
		if not connection.hidden then
			local from = connection.from and connection.from.name
			local to = connection.to and connection.to.name
			if neighbours[from] and neighbours[to] then
				neighbours[from][#neighbours[from] + 1] = to
				neighbours[to][#neighbours[to] + 1] = from
			end
		end
	end
	for _, names in pairs(neighbours) do
		table.sort(names)
	end

	local function route_less(first, second)
		if first.closed ~= second.closed then
			return first.closed < second.closed
		end
		if first.steps ~= second.steps then
			return first.steps < second.steps
		end
		for index = 1, #first.path do
			if first.path[index] ~= second.path[index] then
				return first.path[index] < second.path[index]
			end
		end
		return false
	end

	local function shortest_path(target)
		local best = {[HOME] = {closed = 0, steps = 0, path = {HOME}}}
		local pending, settled = {[HOME] = true}, {}
		while next(pending) do
			---@type string|nil
			local current
			---@type {closed: integer, steps: integer, path: string[]}|nil
			local current_route
			for name in pairs(pending) do
				if not current_route or route_less(best[name], current_route) then
					current, current_route = name, best[name]
				end
			end
			if not current or not current_route then
				break
			end
			pending[current] = nil
			if current == target then
				return current_route.path
			end
			settled[current] = true

			for _, other in ipairs(neighbours[current] or {}) do
				if not settled[other] then
					---@type string[]
					local path = {}
					for index, name in ipairs(current_route.path) do
						path[index] = name
					end
					path[#path + 1] = other
					local candidate = {
						closed = current_route.closed + (is_open(other) and 0 or 1),
						steps = current_route.steps + 1,
						path = path
					}
					if not best[other] or route_less(candidate, best[other]) then
						best[other] = candidate
						pending[other] = true
					end
				end
			end
		end
	end

	local targets = {}
	for name, location in pairs(locations) do
		if name ~= HOME and not location.hidden and explicitly_open[name] then
			targets[#targets + 1] = name
		end
	end
	table.sort(targets)

	local result = {}
	for _, target in ipairs(targets) do
		local path = shortest_path(target)
		if path then
			for _, location in ipairs(path) do
				if not is_open(location) then
					local selected, selected_count
					for _, name in ipairs(opening_technologies[location] or {}) do
						local technology = force.technologies[name]
						if technology and not technology.researched and not granted[name] then
							local count = 0
							for _, path_location in ipairs(path) do
								if not is_open(path_location) and technology_locations[name][path_location] then
									count = count + 1
								end
							end
							if count > 0 and (not selected_count or count > selected_count
								or (count == selected_count and name < selected)) then
								selected, selected_count = name, count
							end
						end
					end
					if not selected then
						break
					end
					granted[selected] = true
					result[#result + 1] = selected
				end
			end
		end
	end
	return result
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

			for _, name in ipairs(route_technologies(force, granted)) do
				grant(force, name, granted)
			end

			if #granted > 0 then
				log("[Razi Protocol/migration] " .. force.name .. ": " .. table.concat(granted, ", "))
			end
		end
	end
end

return M
