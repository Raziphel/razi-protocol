function deleteRoute(name)
	if not data.raw["space-connection"] then
		return
	end

	if data.raw["space-connection"][name] then
		data.raw["space-connection"][name] = nil
	end
end

function deleteAllRoutes()
	if not data.raw["space-connection"] then
		return
	end

	for connection_name, _ in pairs(data.raw["space-connection"]) do
		data.raw["space-connection"][connection_name] = nil
	end
end

function deleteAllRoutesExceptLocations(keep_locations)
	if not data.raw["space-connection"] then
		return
	end

	local keep_lookup = {}

	for _, location_name in pairs(keep_locations or {}) do
		keep_lookup[location_name] = true
	end

	for connection_name, connection in pairs(data.raw["space-connection"]) do
		local from_name = connection.from
		local to_name = connection.to

		local keep_route =
			(from_name and keep_lookup[from_name]) or
			(to_name and keep_lookup[to_name])

		if not keep_route then
			data.raw["space-connection"][connection_name] = nil
		end
	end
end

function technology_exists(name)
	return data.raw.technology and data.raw.technology[name] ~= nil
end

function set_prerequisites_if_exists(technology_name, prerequisites)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if technology then
		technology.prerequisites = prerequisites
	end
end

function set_first_existing_prerequisite(technology_name, candidate_prerequisites)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology then
		return
	end

	for _, prerequisite in ipairs(candidate_prerequisites or {}) do
		if technology_exists(prerequisite) then
			technology.prerequisites = {prerequisite}
			return
		end
	end
end

function add_first_existing_prerequisite(technology_name, candidate_prerequisites)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology then
		return
	end

	for _, prerequisite in ipairs(candidate_prerequisites) do
		if technology_exists(prerequisite) then
			technology.prerequisites = technology.prerequisites or {}
			table.insert(technology.prerequisites, prerequisite)
			return
		end
	end
end

function add_existing_prerequisites(technology_name, candidate_prerequisites)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology then
		return
	end

	local existing_prerequisites = {}
	technology.prerequisites = technology.prerequisites or {}
	for _, prerequisite in ipairs(technology.prerequisites) do
		existing_prerequisites[prerequisite] = true
	end

	for _, prerequisite in ipairs(candidate_prerequisites or {}) do
		if technology_exists(prerequisite) and not existing_prerequisites[prerequisite] then
			table.insert(technology.prerequisites, prerequisite)
			existing_prerequisites[prerequisite] = true
		end
	end
end
