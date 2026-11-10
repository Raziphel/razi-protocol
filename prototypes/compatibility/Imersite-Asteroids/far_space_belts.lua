-- Imersite asteroids also fall on the routes and bodies of far space.

local far_space_belts = {}

local function spawn_definition_key(definition)
	return (definition.type or "asteroid") .. ":" .. tostring(definition.asteroid)
end

local function append_spawn_definitions(target, definitions)
	if not target or not definitions then
		return
	end

	target.asteroid_spawn_definitions = target.asteroid_spawn_definitions or {}

	local existing = {}
	for _, definition in ipairs(target.asteroid_spawn_definitions) do
		existing[spawn_definition_key(definition)] = true
	end

	for _, definition in ipairs(definitions) do
		local key = spawn_definition_key(definition)
		if not existing[key] then
			table.insert(target.asteroid_spawn_definitions, table.deepcopy(definition))
			existing[key] = true
		end
	end
end


function far_space_belts.data_final_fixes()
	if not mods["Imersite-Asteroids"] then
		return
	end

	local ok, imersite_asteroids = pcall(require, "__Imersite-Asteroids__.imersite-asteroids-spawn-definitions")
	if not ok then
		return
	end

	local inner_belt = imersite_asteroids.spawn_definitions(imersite_asteroids.inner_imersite_asteroid_belt)
	local outer_belt = imersite_asteroids.spawn_definitions(imersite_asteroids.outer_imersite_asteroid_belt)
	local local_orbit = imersite_asteroids.spawn_definitions(imersite_asteroids.inner_planet_asteroids, 0.4)

	-- The source mod only seeds Fulgora and a few vanilla lanes. In this pack,
	-- Imersite belongs in the ugly late-space routes too.
	for _, connection_name in ipairs({
		"sye-beetlejuice-cubium",
		"cubium-vesta",
		"vesta-secretas",
		"secretas-frozeta",
		"sye-beetlejuice-tenebris",
		"tenebris-crucible-orbit",
		"crucible-orbit-vesta",
		"frozeta-solar-system-edge"
	}) do
		append_spawn_definitions(data.raw["space-connection"] and data.raw["space-connection"][connection_name], inner_belt)
	end

	for _, connection_name in ipairs({
		"solar-system-edge-nexus",
		"solar-system-edge-black-hole-approach",
		"black-hole-approach-black-hole",
		"nexus-oort-cloud",
		"oort-cloud-sol"
	}) do
		append_spawn_definitions(data.raw["space-connection"] and data.raw["space-connection"][connection_name], outer_belt)
	end

	for _, planet_name in ipairs({"cubium", "vesta", "aquilo", "frozeta", "nexus"}) do
		append_spawn_definitions(data.raw.planet and data.raw.planet[planet_name], local_orbit)
	end

	for _, location_name in ipairs({"secretas", "solar-system-edge", "oort-cloud", "black-hole-approach"}) do
		append_spawn_definitions(data.raw["space-location"] and data.raw["space-location"][location_name], local_orbit)
	end
end

return far_space_belts
