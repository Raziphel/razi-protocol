local prototype_identity = {}

local function raw(type_name, name)
	return data.raw[type_name] and data.raw[type_name][name]
end

local function set_energy_source_limit(entity, key, value)
	if entity and entity.energy_source then
		entity.energy_source[key] = value
	end
end

local function polish_solar()
	local tiny_solar = raw("solar-panel", "tiny-solar-panel")
	if tiny_solar then
		tiny_solar.production = "7.5kW"
		tiny_solar.max_health = math.max(tiny_solar.max_health or 0, 30)
	end
end

local function polish_accumulators()
	local big_accumulator = raw("accumulator", "big-accumulator")
	if big_accumulator then
		set_energy_source_limit(big_accumulator, "buffer_capacity", "40MJ")
		set_energy_source_limit(big_accumulator, "input_flow_limit", "1.5MW")
		set_energy_source_limit(big_accumulator, "output_flow_limit", "1.5MW")
	end
end

local function polish_inserters()
	local long_stack = raw("inserter", "long-stack-inserter")
	if long_stack then
		long_stack.rotation_speed = long_stack.rotation_speed and long_stack.rotation_speed * 0.95
		long_stack.extension_speed = long_stack.extension_speed and long_stack.extension_speed * 1.20
	end

	local rubia_bulk = raw("inserter", "rubia-long-bulk-inserter")
	if rubia_bulk then
		rubia_bulk.energy_per_movement = "8kJ"
		rubia_bulk.energy_per_rotation = "8kJ"
		rubia_bulk.allow_custom_vectors = true
	end

	local rubia_stack = raw("inserter", "rubia-long-stack-inserter")
	if rubia_stack then
		rubia_stack.energy_per_movement = "12kJ"
		rubia_stack.energy_per_rotation = "12kJ"
		rubia_stack.allow_custom_vectors = true
	end
end

local function polish_cubium_dream_logistics()
	local dream_recipes = {
		"express-transport-belt-dream",
		"express-underground-belt-dream",
		"express-splitter-dream",
		"turbo-transport-belt-dream",
		"turbo-underground-belt-dream",
		"turbo-splitter-dream"
	}

	for _, recipe_name in pairs(dream_recipes) do
		local recipe = raw("recipe", recipe_name)
		if recipe then
			recipe.energy_required = math.max(recipe.energy_required or 1, 4)
			recipe.allow_quality = true
		end
	end
end

function prototype_identity.data_final_fixes()
	polish_solar()
	polish_accumulators()
	polish_inserters()
	polish_cubium_dream_logistics()
end

return prototype_identity
