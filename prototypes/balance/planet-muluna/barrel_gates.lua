-- Muluna moves the fill and empty barrel recipes of every fluid into the trigger technology "fluid-barreling", which is
-- done as soon as one barrel is crafted (planet-muluna/data-final-fixes.lua:89-132). With about a hundred barrelable
-- fluids in this mod set, one barrel opens the barrels of all of them, including fluids the force cannot produce for a
-- long time. The author declined to change it (planet-muluna issue #485). So this is a balance decision of this mod.
--
-- Each pair of barrel recipes moves to the technologies that make the fluid available instead:
--   * technologies unlocking a recipe that produces the fluid;
--   * technologies unlocking a planet whose map generation places a tile or a resource yielding the fluid (offshore
--     pumps and pumpjacks);
--   * technologies unlocking a boiler whose output is the fluid.
-- A fluid with a source that needs no technology (water and crude oil on Nauvis) or with no technology-gated source at all
-- keeps its original unlock, so the trigger technology still covers the fluids of the starting planet.
--
-- A technology that already requires another technology unlocking the barrels gets nothing from them but a line in its
-- effects, so it is skipped. Byproducts are not skipped as such: on Corrundum and in Krastorio's enriched ores they are
-- the first source of the fluid.
--
-- The target technologies are not forced to require fluid-handling: a couple of early Krastorio technologies
-- (kr-fluids-chemistry) produce fluids before it, and adding the prerequisite would push them behind logistic science.
-- The barrel recipe then shows up a little before the empty barrel does, which is harmless.
--
-- Pelagos' titanium barrels (technology "titanium-barrels") are left alone: their unlock would have to require both that
-- technology and the fluid's one, which a single unlock effect cannot express.
--
-- Runs after razi-resource-loops, which hides technologies left with no effects (recrystallization of Corrundum when the
-- level is strict); hidden technologies are never chosen, because barrels moved there could not be researched.
local barrel_gates = {}

function barrel_gates.data_final_fixes()
	if mods["planet-muluna"] == nil then
		return
	end
	local option = settings.startup["razi-muluna-barrel-gates"]
	if option ~= nil and option.value == false then
		return
	end

	local technologies = data.raw.technology or {}
	local recipes = data.raw.recipe or {}
	local subgroups = data.raw["item-subgroup"] or {}

	local source_technologies = { "fluid-barreling", "fluid-handling" }

	-- Fluids whose barrels go to fixed technologies. Hot fluoroketone is the
	-- coolant output of recipes whose technologies do not require cryogenic-plant
	-- (Krastorio's quantum science packs, dry ice, the plasma recipes). Those
	-- recipes run on cold fluoroketone or fusion plasma, which come out of the
	-- fluoroketone loop that cryogenic-plant starts.
	local fixed_gates = {
		["fluoroketone-hot"] = { "cryogenic-plant" },
	}


	-- The one fluid a recipe moves, or nil when it has none or several.
	local function recipe_fluid(recipe)
		local fluid_name

		for _, entries in ipairs({ recipe.ingredients or {}, recipe.results or {} }) do
			for _, entry in ipairs(entries) do
				if entry.type == "fluid" then
					if fluid_name and fluid_name ~= entry.name then
						return nil
					end
					fluid_name = entry.name
				end
			end
		end

		return fluid_name
	end

	-- Base names its generated recipes "<fluid>-barrel" and "empty-<fluid>-barrel",
	-- but the fluid inside may differ from the name: K2SO points its
	-- kr-nitric-acid-barrel recipes at the base nitric-acid fluid. So the fluid is
	-- read from the recipe itself.
	local function barrel_fluid(recipe_name)
		local recipe = recipes[recipe_name]
		if recipe and recipe_name:find("%-barrel$") then
			return recipe_fluid(recipe)
		end
	end

	local function add_to_set(sets, key, value)
		sets[key] = sets[key] or {}
		sets[key][value] = true
	end

	local function merge_set(target, source)
		for key in pairs(source or {}) do
			target[key] = true
		end
	end

	-- recipe name -> set of technologies unlocking it,
	-- planet name -> set of technologies unlocking it.
	-- Hidden technologies are left out.
	local recipe_unlocks = {}
	local location_unlocks = {}
	for technology_name, technology in pairs(technologies) do
		for _, effect in ipairs(not technology.hidden and technology.effects or {}) do
			if effect.type == "unlock-recipe" and effect.recipe then
				add_to_set(recipe_unlocks, effect.recipe, technology_name)
			elseif effect.type == "unlock-space-location" and effect.space_location then
				add_to_set(location_unlocks, effect.space_location, technology_name)
			end
		end
	end

	-- Recipes that only move a fluid between a container and a pipe: base's own
	-- barrel subgroups, the filled-barrel subgroup (where the gas-ballon unpacking
	-- recipes sit), Barreling group 2's item group (which also collects pallets,
	-- IBCs and tanks of other mods) and any "empty-*" recipe as a fallback for mods
	-- that load after this one.
	local container_subgroups = { ["fill-barrel"] = true, ["empty-barrel"] = true, ["barrel"] = true }

	local function is_container_recipe(recipe_name, recipe)
		if recipe_name:find("^empty%-") or container_subgroups[recipe.subgroup] then
			return true
		end

		local subgroup = recipe.subgroup and subgroups[recipe.subgroup]
		return subgroup ~= nil and subgroup.group == "barreling"
	end

	-- fluid name -> set of technologies unlocking a recipe that produces it,
	-- item name -> set of recipe names producing it.
	local producer_technologies = {}
	local item_producers = {}
	for recipe_name, recipe in pairs(recipes) do
		for _, result in ipairs(recipe.results or {}) do
			if result.type == "fluid" and result.name then
				if not is_container_recipe(recipe_name, recipe) then
					producer_technologies[result.name] = producer_technologies[result.name] or {}
					merge_set(producer_technologies[result.name], recipe_unlocks[recipe_name])
				end
			elseif result.name then
				add_to_set(item_producers, result.name, recipe_name)
			end
		end
	end

	-- Natural sources. sources[fluid] = { free = true } when some source needs no
	-- technology, otherwise { technologies = set }.
	local sources = {}

	local function fluid_source(fluid_name)
		sources[fluid_name] = sources[fluid_name] or { technologies = {} }
		return sources[fluid_name]
	end

	local function add_location_source(fluid_name, location_name)
		local source = fluid_source(fluid_name)
		if location_unlocks[location_name] then
			merge_set(source.technologies, location_unlocks[location_name])
		else
			source.free = true
		end
	end

	local function placed_by_planet(planet, kind, name)
		local settings = planet.map_gen_settings and planet.map_gen_settings.autoplace_settings
		settings = settings and settings[kind] and settings[kind].settings
		return settings ~= nil and settings[name] ~= nil
	end

	-- A tile or resource placed by no planet's map generation is placed by script,
	-- which cannot be attributed to a technology; treat it as available.
	local function add_placed_source(fluid_name, kind, name)
		local placed = false
		for planet_name, planet in pairs(data.raw.planet or {}) do
			if placed_by_planet(planet, kind, name) then
				placed = true
				add_location_source(fluid_name, planet_name)
			end
		end

		if not placed then
			fluid_source(fluid_name).free = true
		end
	end

	for tile_name, tile in pairs(data.raw.tile or {}) do
		if tile.fluid then
			add_placed_source(tile.fluid, "tile", tile_name)
		end
	end

	for resource_name, resource in pairs(data.raw.resource or {}) do
		local minable = resource.minable or {}
		for _, result in ipairs(minable.results or {}) do
			if result.type == "fluid" and result.name then
				add_placed_source(result.name, "entity", resource_name)
			end
		end
	end

	-- An entity is available with the recipes of the items that place it.
	local function add_entity_source(fluid_name, entity_name)
		local source = fluid_source(fluid_name)
		local placeable = false

		for item_type in pairs(defines.prototypes.item) do
			for _, item in pairs(data.raw[item_type] or {}) do
				if item.place_result == entity_name then
					for recipe_name in pairs(item_producers[item.name] or {}) do
						placeable = true
						if recipe_unlocks[recipe_name] then
							merge_set(source.technologies, recipe_unlocks[recipe_name])
						elseif recipes[recipe_name].enabled ~= false then
							source.free = true
						end
					end
				end
			end
		end

		if not placeable then
			source.free = true
		end
	end

	for boiler_name, boiler in pairs(data.raw.boiler or {}) do
		local output = boiler.output_fluid_box and boiler.output_fluid_box.filter
		if output then
			add_entity_source(output, boiler_name)
		end
	end

	-- Returns the set of technologies that should unlock the fluid's barrels, or nil
	-- when the barrels have to stay where they are.
	local function gate_technologies(fluid_name)
		local fixed = {}
		for _, technology_name in ipairs(fixed_gates[fluid_name] or {}) do
			if technologies[technology_name] then
				fixed[technology_name] = true
			end
		end

		if next(fixed) ~= nil then
			return fixed
		end

		local source = sources[fluid_name]
		if source and source.free then
			return nil
		end

		local result = {}
		merge_set(result, producer_technologies[fluid_name])
		merge_set(result, source and source.technologies)

		if next(result) == nil then
			return nil
		end

		return result
	end

	local function add_unlock(technology_name, recipe_name)
		local technology = technologies[technology_name]
		if not technology then
			return
		end

		technology.effects = technology.effects or {}
		for _, effect in ipairs(technology.effects) do
			if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
				return
			end
		end

		table.insert(technology.effects, { type = "unlock-recipe", recipe = recipe_name })
	end

	-- technology name -> set of its transitive prerequisites.
	local ancestor_sets = {}

	local function ancestors(technology_name)
		local result = ancestor_sets[technology_name]
		if result then
			return result
		end

		result = {}
		ancestor_sets[technology_name] = result

		local technology = technologies[technology_name]
		for _, prerequisite in ipairs(technology and technology.prerequisites or {}) do
			result[prerequisite] = true
			merge_set(result, ancestors(prerequisite))
		end

		return result
	end

	local is_source = {}
	for _, source_name in ipairs(source_technologies) do
		is_source[source_name] = true
	end

	-- The targets that do not require another technology unlocking the recipe,
	-- whether another target or one that unlocked it before this fix.
	local function without_redundant(targets, recipe_name)
		local unlockers = {}
		merge_set(unlockers, targets)
		for technology_name in pairs(recipe_unlocks[recipe_name] or {}) do
			if not is_source[technology_name] then
				unlockers[technology_name] = true
			end
		end

		local result = {}
		for technology_name in pairs(targets) do
			local required = ancestors(technology_name)
			local redundant = false

			for unlocker in pairs(unlockers) do
				if required[unlocker] then
					redundant = true
					break
				end
			end

			if not redundant then
				result[technology_name] = true
			end
		end

		return result
	end

	local moved = {}
	local kept = {}

	for _, source_name in ipairs(source_technologies) do
		local technology = technologies[source_name]
		---@type data.Modifier[]
		local effects = technology and technology.effects or {}

		for index = #effects, 1, -1 do
			local effect = effects[index]
			local fluid_name = effect.type == "unlock-recipe" and barrel_fluid(effect.recipe)

			if fluid_name then
				local targets = gate_technologies(fluid_name)

				if targets then
					targets = without_redundant(targets, effect.recipe)

					-- The source technology may itself unlock a producer; keep the effect then.
					if targets[source_name] then
						targets[source_name] = nil
					else
						table.remove(effects, index)
					end

					for target_name in pairs(targets) do
						add_unlock(target_name, effect.recipe)
					end

					moved[fluid_name] = targets
				else
					kept[fluid_name] = source_name
				end
			end
		end
	end

	local function sorted_keys(set)
		local keys = {}
		for key in pairs(set) do
			table.insert(keys, key)
		end
		table.sort(keys)

		return keys
	end

	for _, fluid_name in ipairs(sorted_keys(moved)) do
		log("razi-protocol: barrels of " .. fluid_name .. " unlocked by: "
			.. table.concat(sorted_keys(moved[fluid_name]), ", "))
	end

	log("razi-protocol: barrel gates: moved the barrels of " .. #sorted_keys(moved)
		.. " fluids, kept " .. #sorted_keys(kept) .. " (" .. table.concat(sorted_keys(kept), ", ") .. ")")
end

return barrel_gates
