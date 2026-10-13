local Collections = require("__razi_lib__/lib/collections")
local Science = require("__razi_lib__/lib/science")
local SpaceConnection = require("__razi_lib__/lib/space_connection")
local Technology = require("__razi_lib__/lib/technology")

function deleteRoute(name)
	SpaceConnection.remove(name)
end

function deleteRoutesBetween(location_a, location_b)
	SpaceConnection.remove_between(location_a, location_b)
end

function deleteAllRoutes()
	SpaceConnection.remove_all()
end

function deleteAllRoutesExceptLocations(keep_locations)
	SpaceConnection.remove_except_locations(keep_locations)
end

function technology_exists(name)
	return Technology.exists(name)
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

	local prerequisite = Technology.first_existing_name(candidate_prerequisites)
	if prerequisite then technology:set_prerequisites({prerequisite}) end
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
	return Science.exists(name)
end

local protected_lab_science_pack_lookup = {
	["lunar-science-pack"] = true,
	["interstellar-science-pack"] = true,
	["advanced-space-science-pack"] = true,
	["cerysian-science-pack"] = true,
	["aerospace-science-pack"] = true
}

function science_pack_is_lab_protected(name)
	return protected_lab_science_pack_lookup[name] == true
end

function lab_has_science_input(lab, science_pack)
	return Science.lab_has_input(lab, science_pack)
end

function lab_is_protected_unique_science_lab(lab)
	if not (lab and lab.inputs) then
		return false
	end

	for science_pack in pairs(protected_lab_science_pack_lookup) do
		if Science.lab_has_input(lab, science_pack) then
			return true
		end
	end

	return false
end

function add_science_pack_if_exists(ingredients, science_pack)
	return Science.add_pack(ingredients, science_pack)
end

function add_unique_science_pack_if_exists(ingredients, science_pack)
	return Science.add_pack(ingredients, science_pack)
end

function add_existing_science_packs(ingredients, science_packs)
	Science.add_existing(ingredients, science_packs)
end

function add_unique_values(values, new_values)
	for _, value in ipairs(new_values or {}) do
		if value then
			Collections.append_unique(values, value)
		end
	end
end

function collect_technology_science_packs()
	return Science.collect_from_technologies()
end

function collect_recipe_science_packs(recipe_names)
	return Science.collect_from_recipes(recipe_names)
end

function add_first_existing_science_pack(ingredients, science_packs)
	return Science.add_first_existing(ingredients, science_packs) ~= nil
end

function build_integrated_science_ingredients(options)
	return Science.build_ingredients(options)
end

function set_technology_unit_ingredients_if_exists(technology_name, ingredients)
	local technology = Technology.optional(technology_name)
	if technology and technology.unit and ingredients and #ingredients > 0 then
		technology:set_packs(ingredients)
	end
end
