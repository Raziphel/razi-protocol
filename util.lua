local Prototype = require("__razi_lib__/lib/prototype")
local Technology = require("__razi_lib__/lib/technology")

function deleteRoute(name)
	if not data.raw["space-connection"] then
		return
	end

	if data.raw["space-connection"][name] then
		data.raw["space-connection"][name] = nil
	end
end

function deleteRoutesBetween(location_a, location_b)
	if not data.raw["space-connection"] then
		return
	end

	for connection_name, connection in pairs(data.raw["space-connection"]) do
		local from_name = connection and connection.from
		local to_name = connection and connection.to
		local matches_pair =
			(from_name == location_a and to_name == location_b) or
			(from_name == location_b and to_name == location_a)

		if matches_pair then
			data.raw["space-connection"][connection_name] = nil
		end
	end
end

function technology_exists(name)
	return Prototype.exists("technology", name)
end

function set_prerequisites_if_exists(technology_name, prerequisites)
	local technology = Technology.optional(technology_name)
	if technology then
		technology:set_prerequisites(prerequisites)
	end
end

function set_first_existing_prerequisite(technology_name, candidate_prerequisites)
	local technology = Technology.optional(technology_name)
	if not technology then
		return
	end

	for _, prerequisite in ipairs(candidate_prerequisites or {}) do
		if technology_exists(prerequisite) then
			technology:set_prerequisites({prerequisite})
			return
		end
	end
end

function add_first_existing_prerequisite(technology_name, candidate_prerequisites)
	local technology = Technology.optional(technology_name)
	if not technology then
		return
	end

	for _, prerequisite in ipairs(candidate_prerequisites or {}) do
		if technology_exists(prerequisite) then
			technology:add_prerequisite(prerequisite)
			return
		end
	end
end

function add_existing_prerequisites(technology_name, candidate_prerequisites)
	local technology = Technology.optional(technology_name)
	if not technology then
		return
	end

	for _, prerequisite in ipairs(candidate_prerequisites or {}) do
		if technology_exists(prerequisite) then
			technology:add_prerequisite(prerequisite)
		end
	end
end

function remove_prerequisites_if_exists(technology_name, prerequisites_to_remove)
	local technology = Technology.optional(technology_name)
	if not technology or not technology._prototype.prerequisites then
		return
	end

	for _, prerequisite in ipairs(prerequisites_to_remove or {}) do
		technology:remove_prerequisite(prerequisite)
	end
end

function science_pack_exists(name)
	return Prototype.exists("tool", name) or Prototype.exists("item", name)
end

local protected_lab_science_pack_lookup = {
	["interstellar-science-pack"] = true,
	["advanced-space-science-pack"] = true,
	["cerysian-science-pack"] = true,
	["aerospace-science-pack"] = true
}

function science_pack_is_lab_protected(name)
	return protected_lab_science_pack_lookup[name] == true
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
	local technology = Technology.optional(technology_name)
	if not technology or not technology._prototype.unit or not ingredients or #ingredients == 0 then
		return
	end

	technology:set_packs(ingredients)
end
