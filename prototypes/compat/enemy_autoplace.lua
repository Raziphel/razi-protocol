local enemy_autoplace = {}
local difficulty=require("scripts.razi_difficulty_presets")

function enemy_autoplace.enabled()
	local setting = settings
		and settings.startup
		and settings.startup["razi-enable-enemy-routing"]

	return not setting or setting.value ~= false
end

function enemy_autoplace.disable_vanilla_enemies_on_planet(planet_name)
  -- Retained for existing integrations. All custom enemies are now additive:
  -- do not wipe Nauvis nests on their native worlds, or the Nexus mix.
  -- Spawning variants are isolated by the final ecology pass instead.
  return false
end

function enemy_autoplace.existing_tiles(tile_names)
	local tiles = {}
	for _, tile_name in pairs(tile_names or {}) do
		if data.raw.tile and data.raw.tile[tile_name] then
			table.insert(tiles, tile_name)
		end
	end

	return tiles
end

function enemy_autoplace.entity_exists(entity_type, entity_name)
	return data.raw[entity_type] and data.raw[entity_type][entity_name]
end

-- Factorio 2.1 requires a probability expression whenever an entity has
-- an autoplace table. Some enemy packs use ordinary nests to spawn their
-- units, and deliberately do not define natural placement for new nests.
function enemy_autoplace.has_valid_autoplace(entity)
	local autoplace = entity and entity.autoplace
	return type(autoplace) == "table"
		and autoplace.probability_expression ~= nil
end

-- This check runs after the last Razi prototype pass too. If an older
-- third-party fork leaves a partial autoplace behind, drop *only* the
-- malformed placement definition and its planet map-gen references.
-- Never delete the spawner prototype or its result_units.
function enemy_autoplace.remove_invalid_autoplace(entity_type, entity_name)
	local entity = enemy_autoplace.entity_exists(entity_type, entity_name)
	if not entity or enemy_autoplace.has_valid_autoplace(entity) then
		return false
	end
	entity.autoplace = nil
	for _, planet in pairs(data.raw.planet or {}) do
		local place = planet.map_gen_settings
			and planet.map_gen_settings.autoplace_settings
		local entries = place and place.entity and place.entity.settings
		if entries then
			entries[entity_name] = nil
		end
	end
	return true
end

function enemy_autoplace.repair_optional_enemy_autoplace()
	if mods and (mods["ArmouredBiters21Compat"] or mods["ArmouredBiters"]) then
		enemy_autoplace.remove_invalid_autoplace("unit-spawner", "armoured-biter-spawner")
	end
	if mods and mods["Electric_flying_enemies"] then
		for _, entity_name in ipairs({
			"flying-electric-unit-spawner", "walker-electric-unit-spawner",
			"fulgoran-enemy-spawner", "fulgoran-replicator",
			"fulgoran-unit-replicator", "electric-flying-enemy-spawner",
			"electric-flying-enemies-spawner", "electric-enemy-spawner",
			"unit-replicator"
		}) do
			enemy_autoplace.remove_invalid_autoplace("unit-spawner", entity_name)
		end
	end
end

function enemy_autoplace.enemy_entity_exists(entity_name)
	return
		(data.raw["unit-spawner"] and data.raw["unit-spawner"][entity_name]) or
		(data.raw.turret and data.raw.turret[entity_name])
end

function enemy_autoplace.restrict_entity_to_tiles(entity_type, entity_name, tile_names)
	if not enemy_autoplace.enabled() then
		return
	end

	local entity = enemy_autoplace.entity_exists(entity_type, entity_name)
	if entity and entity.autoplace then
		entity.autoplace.tile_restriction = tile_names
	end
end

function enemy_autoplace.remove_entities_from_planet(planet_name, entity_names, control_name)
	if not enemy_autoplace.enabled() then
		return
	end

	local planet = data.raw.planet and data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return
	end

	if control_name and map_gen_settings.autoplace_controls then
		map_gen_settings.autoplace_controls[control_name] = nil
	end

	local entity_settings = map_gen_settings.autoplace_settings
		and map_gen_settings.autoplace_settings.entity
		and map_gen_settings.autoplace_settings.entity.settings

	if not entity_settings then
		return
	end

	for _, entity_name in pairs(entity_names or {}) do
		entity_settings[entity_name] = nil
	end
end

function enemy_autoplace.pressure(planet_name)
  local mode=difficulty.effective("razi-enemy-pressure","normal")
  local scales={light=.62,normal=1,aggressive=1.28,overrun=1.52}
  local multiplier=scales[mode] or 1
  if planet_name=="nexus" then
    local nexus=difficulty.effective("razi-nexus-hostility","normal")
    multiplier=multiplier*({normal=1,hard=1.30,apocalypse=1.70})[nexus]
  end
  return math.min(multiplier,2.5) -- World-gen density, not per-tick AI.
end

function enemy_autoplace.prepare_custom_enemy_planet(planet_name, control_name)
	if not enemy_autoplace.enabled() then
		return nil
	end

	local planet = data.raw.planet and data.raw.planet[planet_name]
	local map_gen_settings = planet and planet.map_gen_settings
	if not map_gen_settings then
		return nil
	end

	planet.pollutant_type = planet.pollutant_type or "pollution"
	enemy_autoplace.disable_vanilla_enemies_on_planet(planet_name)

	map_gen_settings.autoplace_controls = map_gen_settings.autoplace_controls or {}
	-- Never overwrite an already configured source-mod control when adding
	-- another enemy family to the same planet.
	if not map_gen_settings.autoplace_controls[control_name] then
		map_gen_settings.autoplace_controls[control_name] = {
			frequency = enemy_autoplace.pressure(planet_name),
			size = 1,
			richness = 1
		}
	end

	map_gen_settings.autoplace_settings = map_gen_settings.autoplace_settings or {}
	map_gen_settings.autoplace_settings.entity = map_gen_settings.autoplace_settings.entity or {}
	map_gen_settings.autoplace_settings.entity.settings = map_gen_settings.autoplace_settings.entity.settings or {}

	return map_gen_settings.autoplace_settings.entity.settings
end

function enemy_autoplace.add_entities_to_planet(planet_name, entity_names, control_name, entity_exists)
	if not enemy_autoplace.enabled() then
		return
	end

	-- Never suppress vanilla enemies unless at least one custom enemy really
	-- exists. Some optional packs change prototype names between releases.
	entity_exists = entity_exists or enemy_autoplace.enemy_entity_exists
	local available = {}
	for _, entity_name in pairs(entity_names or {}) do
		-- A prototype's mere existence does not make it naturally
		-- placeable; an incomplete autoplace will crash data loading.
		if enemy_autoplace.has_valid_autoplace(entity_exists(entity_name)) then
			available[#available + 1] = entity_name
		end
	end
	if #available == 0 then
		return
	end

	local entity_settings = enemy_autoplace.prepare_custom_enemy_planet(planet_name, control_name)
	if not entity_settings then
		return
	end
	for _, entity_name in ipairs(available) do
		entity_settings[entity_name] = {}
	end
end

return enemy_autoplace
