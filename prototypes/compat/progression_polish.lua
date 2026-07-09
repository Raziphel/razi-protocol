local progression_polish = {}

local function technology(name)
	return data.raw.technology and data.raw.technology[name]
end

local function recipe(name)
	return data.raw.recipe and data.raw.recipe[name]
end

local function recipe_exists(name)
	return recipe(name) ~= nil
end

local function science_pack_exists(name)
	return data.raw.tool and data.raw.tool[name] ~= nil
end

local function technology_exists(name)
	return technology(name) ~= nil
end

local function add_prerequisite(tech, prerequisite)
	if not tech or not technology_exists(prerequisite) then
		return
	end

	tech.prerequisites = tech.prerequisites or {}
	for _, existing in ipairs(tech.prerequisites) do
		if existing == prerequisite then
			return
		end
	end

	table.insert(tech.prerequisites, prerequisite)
end

local function set_order_if_present(technology_name, order)
	local target_technology = technology(technology_name)
	if target_technology then
		target_technology.order = order
	end
end

local function set_hidden_flags(prototype)
	if not prototype then
		return
	end

	prototype.hidden = true
	prototype.hidden_in_factoriopedia = true
end

local function remove_prerequisite(tech, prerequisite)
	if not tech or not tech.prerequisites then
		return
	end

	for index = #tech.prerequisites, 1, -1 do
		if tech.prerequisites[index] == prerequisite then
			table.remove(tech.prerequisites, index)
		end
	end
end

local function set_recipe_enabled_state(target_recipe, enabled)
	if not target_recipe then
		return
	end

	target_recipe.enabled = enabled
	for _, variant in ipairs({target_recipe.normal, target_recipe.expensive}) do
		if variant then
			variant.enabled = enabled
		end
	end
end

local function science_ingredients(science_packs)
	local ingredients = {}

	for _, science_pack in ipairs(science_packs) do
		if science_pack_exists(science_pack) then
			table.insert(ingredients, {science_pack, 1})
		end
	end

	return ingredients
end

local function ingredient_name(ingredient)
	return ingredient and (ingredient.name or ingredient[1])
end

local function recipe_has_ingredient(recipe_name, ingredient_to_find)
	local target_recipe = recipe(recipe_name)
	if not target_recipe or not target_recipe.ingredients then
		return false
	end

	for _, ingredient in ipairs(target_recipe.ingredients) do
		if ingredient_name(ingredient) == ingredient_to_find then
			return true
		end
	end

	return false
end

local function remove_recipe_ingredient(recipe_name, ingredient_to_remove)
	local target_recipe = recipe(recipe_name)
	if not target_recipe or not target_recipe.ingredients then
		return
	end

	for index = #target_recipe.ingredients, 1, -1 do
		if ingredient_name(target_recipe.ingredients[index]) == ingredient_to_remove then
			table.remove(target_recipe.ingredients, index)
		end
	end
end

local function technology_has_unlock(technology_name, recipe_name)
	local target_technology = technology(technology_name)
	if not target_technology or not target_technology.effects then
		return false
	end

	for _, effect in ipairs(target_technology.effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			return true
		end
	end

	return false
end

local function add_recipe_unlock(technology_name, recipe_name)
	local target_technology = technology(technology_name)
	if not target_technology or not recipe_exists(recipe_name) then
		return
	end

	target_technology.effects = target_technology.effects or {}
	if not technology_has_unlock(technology_name, recipe_name) then
		table.insert(target_technology.effects, {
			type = "unlock-recipe",
			recipe = recipe_name
		})
	end
end

local function remove_recipe_unlock(technology_name, recipe_name)
	local target_technology = technology(technology_name)
	if not target_technology or not target_technology.effects then
		return
	end

	for index = #target_technology.effects, 1, -1 do
		local effect = target_technology.effects[index]
		if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
			table.remove(target_technology.effects, index)
		end
	end
end

local function technology_has_dependents(technology_name)
	for _, target_technology in pairs(data.raw.technology or {}) do
		for _, prerequisite in ipairs(target_technology.prerequisites or {}) do
			if prerequisite == technology_name then
				return true
			end
		end
	end

	return false
end

local function first_existing_technology(names)
	for _, name in ipairs(names) do
		if technology_exists(name) then
			return name
		end
	end

	return nil
end

local function gate_recipe_to_technology(recipe_names, technology_names, stale_unlock_technologies)
	local unlock_technology_name = first_existing_technology(technology_names)
	if not unlock_technology_name then
		return
	end

	for _, recipe_name in ipairs(recipe_names) do
		local target_recipe = recipe(recipe_name)
		if target_recipe then
			set_recipe_enabled_state(target_recipe, false)
			add_recipe_unlock(unlock_technology_name, recipe_name)

			for _, stale_unlock_name in ipairs(stale_unlock_technologies or {}) do
				if stale_unlock_name ~= unlock_technology_name then
					remove_recipe_unlock(stale_unlock_name, recipe_name)
				end
			end
		end
	end
end

local function restore_muluna_green_plastic_gate()
	local green_plastic = technology("muluna-nanofoamed-polymers")
	if not green_plastic then
		return
	end

	-- Muluna wants this after a few planetary breakthroughs. Keep the list
	-- readable, but do not let it become a same-planet early unlock.
	green_plastic.enabled = true
	green_plastic.visible_when_disabled = nil
	green_plastic.prerequisites = {"space-science-pack"}
	add_prerequisite(green_plastic, "planet-discovery-muluna")
	add_prerequisite(green_plastic, "metallurgic-science-pack")
	add_prerequisite(green_plastic, "electromagnetic-science-pack")
	add_prerequisite(green_plastic, "agricultural-science-pack")

	local ingredients = science_ingredients({
		"automation-science-pack",
		"logistic-science-pack",
		"chemical-science-pack",
		"production-science-pack",
		"utility-science-pack",
		"space-science-pack",
		"metallurgic-science-pack",
		"electromagnetic-science-pack",
		"agricultural-science-pack"
	})

	if #ingredients > 0 then
		green_plastic.research_trigger = nil
		green_plastic.unit = {
			count = 1000,
			time = 60,
			ingredients = ingredients
		}
	end

end

local function clarify_long_stack_inserters()
	local rubia_long_stack = technology("rubia-long-stack-inserter")
	if not rubia_long_stack then
		return
	end

	add_prerequisite(rubia_long_stack, "long-stack-inserter")
end

local function move_singularity_card_out_of_early_deep_space()
	-- The black deep-space card is the Nexus/Promethium bridge. K2 singularity
	-- cards should stay in the transceiver finale, not sneak into this earlier
	-- recipe and make the tree look like the ending starts too soon.
	remove_recipe_ingredient("deep-space-tech-card", "kr-singularity-tech-card")
end

local function loosen_matter_research_data_surface()
	local matter_data = recipe("kr-matter-research-data")
	if not matter_data then
		return
	end

	-- K2SO 1.6 moved this onto Aquilo pressure only. Razi moves Aquilo into
	-- the expanded system ladder, so the data recipe needs to follow the broader K2SO
	-- matter route instead of hard-locking one planet.
	matter_data.surface_conditions = nil
end

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

local function add_imersite_to_far_space()
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

local function clean_up_sand_progression()
	local sand_processing = technology("sand-processing")
	if not sand_processing then
		return
	end

	add_prerequisite(sand_processing, "crusher")
	add_prerequisite(sand_processing, "kr-crusher")
	remove_recipe_unlock("sand-processing", "sand")
	remove_recipe_unlock("sand-processing", "kr-sand")

	local glass_processing = technology("glass-processing")
	if glass_processing then
		add_prerequisite(glass_processing, "sand-processing")
	end

	-- If the old AAI-style sand tech no longer owns any visible unlocks and the
	-- rest of the tree does not point at it, hide it instead of leaving a dead
	-- early node cluttering the menu.
	if sand_processing.effects and #sand_processing.effects == 0 and not technology_has_dependents("sand-processing") then
		set_hidden_flags(sand_processing)
	end
end

local function polish_reported_technology_order()
	for technology_name, order in pairs({
		["crusher"] = "a-a[crusher]",
		["sand-processing"] = "a-b[sand-processing]",
		["glass-processing"] = "a-c[glass-processing]",
		["electricity"] = "a-d[electricity]",
		["electronics"] = "a-e[electronics]",
		["logistics"] = "a-f[logistics]",
		["fast-inserter"] = "a-g[fast-inserter]",
		["military"] = "a-h[military]",
		["radar"] = "a-i[radar]",
		["kr-fuel"] = "a-j[fuel-processing]",
		["planet-discovery-cubium"] = "ez-a[cubium]",
		["cube-jelly"] = "ez-b[cube-jelly]",
		["cube-mastery-1"] = "ez-c[cube-mastery-1]",
		["planet-discovery-nexus"] = "fa-a[nexus-discovery]",
		["promethium-882-research"] = "fa-b[promethium-882]",
		["advanced-magnetic-shielding"] = "fa-c[advanced-magnetic-shielding]",
		["advanced-stable-electronic"] = "fa-d[advanced-stable-electronic]",
		["advanced-stronger-armor"] = "fa-e[advanced-stronger-armor]",
		["black-hole-discovery"] = "fz-a[black-hole-discovery]"
	}) do
		set_order_if_present(technology_name, order)
	end
end

local function tighten_reported_unlock_order()
	gate_recipe_to_technology(
		{"kr-sand", "sand"},
		{"crusher", "sand-processing"},
		{"sand-processing"}
	)
	gate_recipe_to_technology(
		{"open-chest-recycling", "2x-open-chest-recycling"},
		{"recycler", "fluid-recycler"},
		{"recycling", "fluid-recycler"}
	)
	gate_recipe_to_technology(
		{"sand-compaction"},
		{"fluid-recycler", "pneumatic-press"},
		{"sand-processing"}
	)
	gate_recipe_to_technology(
		{"void-data-disk", "black-hole-void-data-disk"},
		{"black-hole-discovery"},
		{}
	)
	gate_recipe_to_technology(
		{"nexus-atmospheric-stabilization-process"},
		{"promethium-882-research", "planet-discovery-nexus", "planet-nexus-scanning"},
		{}
	)

	for _, rare_metals_recipe in ipairs({
		"kr-molten-rare-metals-from-lava",
		"kr-molten-rare-metals",
		"kr-molten-enriched-rare-metals",
		"kr-casting-rare-metals"
	}) do
		gate_recipe_to_technology({rare_metals_recipe}, {"kr-fluids-chemistry", "fluid-chemistry"}, {"foundry"})
	end

	local military = technology("military")
	if military and recipe_has_ingredient("slowdown-capsule", "steel-plate") then
		add_prerequisite(military, "steel-processing")
	end

	local captivity = technology("captivity")
	if captivity then
		add_prerequisite(captivity, "gun-turret")
	end

	if technology_exists("carbonic-asteroid-crushing") then
		remove_recipe_unlock("steel-processing", "kr-coke-carbon")
		add_recipe_unlock("carbonic-asteroid-crushing", "kr-coke-carbon")
	end

	local radar = technology("radar")
	if radar then
		add_prerequisite(radar, "electricity")
	end

	local electricity = technology("electricity")
	if electricity then
		remove_prerequisite(electricity, "kr-fuel")
	end

	local fuel_processing = technology("kr-fuel")
	if fuel_processing then
		add_prerequisite(fuel_processing, "electricity")
	end

	local electronics = technology("electronics")
	if electronics then
		add_prerequisite(electronics, "electricity")
		add_recipe_unlock("electronics", "inserter")
		add_recipe_unlock("electronics", "long-handed-inserter")
		add_recipe_unlock("electronics", "kr-loader")
		remove_recipe_unlock("logistics", "long-handed-inserter")
		remove_recipe_unlock("logistics", "kr-loader")
		remove_recipe_unlock("electricity", "inserter")
	end

	local cube_jelly = technology("cube-jelly")
	if cube_jelly then
		add_prerequisite(cube_jelly, "fast-inserter")
	end

	local solaris = technology("solaris-discovery")
	if solaris then
		add_prerequisite(solaris, "metallurgic-science-pack")
		add_prerequisite(solaris, "electromagnetic-science-pack")
		add_prerequisite(solaris, "agricultural-science-pack")
	end

	for _, technology_name in ipairs({"access-to-suns-orbit", "access-to-sun-orbit"}) do
		local orbit_access = technology(technology_name)
		if orbit_access then
			add_prerequisite(orbit_access, "metallurgic-science-pack")
		end
	end

	for _, technology_name in ipairs({"aircraft-energy-shields", "lex-aircraft-energy-shields"}) do
		local aircraft_shields = technology(technology_name)
		if aircraft_shields then
			add_prerequisite(aircraft_shields, "electromagnetic-science-pack")
		end
	end
end

function progression_polish.data_final_fixes()
	restore_muluna_green_plastic_gate()
	clarify_long_stack_inserters()
	move_singularity_card_out_of_early_deep_space()
	loosen_matter_research_data_surface()
	add_imersite_to_far_space()
	clean_up_sand_progression()
	polish_reported_technology_order()
	tighten_reported_unlock_order()
end

return progression_polish
