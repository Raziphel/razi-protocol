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

function remove_prerequisites_if_exists(technology_name, prerequisites_to_remove)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology or not technology.prerequisites then
		return
	end

	local remove_lookup = {}
	for _, prerequisite in ipairs(prerequisites_to_remove or {}) do
		remove_lookup[prerequisite] = true
	end

	for index = #technology.prerequisites, 1, -1 do
		if remove_lookup[technology.prerequisites[index]] then
			table.remove(technology.prerequisites, index)
		end
	end
end

function science_pack_exists(name)
	return data.raw.tool and data.raw.tool[name] ~= nil
end

function add_science_pack_if_exists(ingredients, science_pack)
	if science_pack_exists(science_pack) then
		table.insert(ingredients, {science_pack, 1})
		return true
	end

	return false
end

function add_unique_science_pack_if_exists(ingredients, science_pack)
	if not science_pack_exists(science_pack) then
		return false
	end

	for _, ingredient in ipairs(ingredients) do
		if ingredient[1] == science_pack then
			return false
		end
	end

	table.insert(ingredients, {science_pack, 1})
	return true
end

function add_existing_science_packs(ingredients, science_packs)
	for _, science_pack in ipairs(science_packs or {}) do
		add_unique_science_pack_if_exists(ingredients, science_pack)
	end
end

function add_first_existing_science_pack(ingredients, science_packs)
	for _, science_pack in ipairs(science_packs or {}) do
		if add_science_pack_if_exists(ingredients, science_pack) then
			return true
		end
	end

	return false
end

function build_integrated_science_ingredients(options)
	options = options or {}

	local ingredients = {}

	add_existing_science_packs(ingredients, options.primary_science_packs)
	add_first_existing_science_pack(ingredients, options.first_available_science_packs)
	add_existing_science_packs(ingredients, options.extra_science_packs)

	if #ingredients == 0 and options.fallback_science_packs then
		for _, science_pack in ipairs(options.fallback_science_packs) do
			table.insert(ingredients, {science_pack, 1})
		end
	end

	return ingredients
end

function set_technology_unit_ingredients_if_exists(technology_name, ingredients)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology or not technology.unit or not ingredients or #ingredients == 0 then
		return
	end

	technology.unit.ingredients = ingredients
end
