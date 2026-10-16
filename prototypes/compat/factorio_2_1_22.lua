local factorio_2_1_22 = {}

-- Temporary: Factorio 2.1.22 removed two prototype fields that several
-- required mods still set, and the game refuses to load with them.
--
-- 1. FluidBox minimum_temperature and maximum_temperature. The limits moved
--    to the machine (minimum_input_temperature and maximum_input_temperature
--    of generators, boilers, fusion generators and reactors, mining drills
--    and fluid energy sources; the fuel and oxidizer temperatures of
--    thrusters). Krastorio 2 2.1.4 moved its steam turbine limit the same way.
--    Still set by Krastorio2-spaced-out 2.0.17 (kr-advanced-steam-turbine),
--    corrundum (red-steam-engine), linox (neodymium permanent magnet
--    generator), panglia_planet (energy roots) and planetaris-hyarion
--    (refraction generator).
-- 2. WaterTileEffectParameters textures and texture_variations_*. 2.1.22
--    splits textures into noise_textures and image_textures; the vanilla
--    tiles take new noise files for lava and oil. The noise set comes from a
--    vanilla effect of the same shader variation, the mod's other textures
--    become image_textures. Still old in planetaris-tellus, cubium,
--    skewer_planet_vesta and panglia_planet.
--
-- Only on 2.1.22 and newer, where the old fields no longer work, and only on
-- prototypes that still have them: once a mod is fixed upstream this does
-- nothing for it. Remove the module when all the mods above are fixed.
-- Also on 2.1.22: a fluid energy source with maximum_temperature = 0 meant
-- "no limit" and now means 0 degrees; nil is the new "no limit".

local function log_change(text)
	log("[Razi Protocol/factorio-2.1.22] " .. text)
end

local function version_at_least(version, wanted)
	local parts = {}
	for number in string.gmatch(version or "", "%d+") do
		parts[#parts + 1] = tonumber(number)
	end
	for index, number in ipairs(wanted) do
		local own = parts[index] or 0
		if own ~= number then
			return own > number
		end
	end

	return true
end

-- The fluid a box takes, by its filter.
local function filter_fluid(box)
	return box.filter and data.raw.fluid and data.raw.fluid[box.filter]
end

-- Moves the temperature limits of a fluid box onto the prototype that owns it.
-- target is the table that takes the new fields, names the {minimum, maximum}
-- field names there (nil: the fields have no replacement and are dropped).
-- The box value wins over a value already on the target: on 2.1.21 the box
-- limit was the one the game used (Krastorio2-spaced-out sets 165 on the box
-- of kr-advanced-steam-turbine, Krastorio 2 2.1.4 sets 950 on the machine).
-- A minimum at or below the default temperature of the filtered fluid limits
-- nothing, and 2.1.22 refuses it on the machine, so it is dropped.
local function move_limits(label, box, target, names)
	if type(box) ~= "table" then
		return
	end

	for index, field in ipairs({"minimum_temperature", "maximum_temperature"}) do
		local value = box[field]
		if value ~= nil then
			box[field] = nil
			local new_field = names and names[index]
			local fluid = filter_fluid(box)
			local no_limit = field == "minimum_temperature" and fluid and value <= (fluid.default_temperature or 15)
			if new_field and not no_limit then
				local before = target[new_field]
				target[new_field] = value
				log_change(label .. ": fluid box " .. field .. " " .. value .. " -> " .. new_field
					.. (before ~= nil and before ~= value and (" (was " .. before .. ")") or ""))
			else
				log_change(label .. ": fluid box " .. field .. " " .. value .. " dropped"
					.. (no_limit and (", at or below the default temperature of " .. box.filter) or ""))
			end
		end
	end
end

local input_names = {"minimum_input_temperature", "maximum_input_temperature"}

-- prototype type -> {fluid box field, names of the limits on the prototype}
local machine_boxes = {
	["generator"] = {{"fluid_box", input_names}},
	["boiler"] = {{"fluid_box", input_names}},
	["fusion-generator"] = {{"input_fluid_box", input_names}},
	["fusion-reactor"] = {{"input_fluid_box", input_names}},
	["mining-drill"] = {{"input_fluid_box", input_names}},
	["thruster"] = {
		{"fuel_fluid_box", {"minimum_fuel_temperature", "maximum_fuel_temperature"}},
		{"oxidizer_fluid_box", {"minimum_oxidizer_temperature", "maximum_oxidizer_temperature"}}
	}
}

local other_box_fields = {"fluid_box", "input_fluid_box", "output_fluid_box", "fuel_fluid_box", "oxidizer_fluid_box"}

local function fix_fluid_boxes()
	for type_name, prototypes in pairs(data.raw) do
		for name, prototype in pairs(prototypes) do
			if type(prototype) == "table" then
				local label = type_name .. "/" .. name
				for _, entry in ipairs(machine_boxes[type_name] or {}) do
					move_limits(label, prototype[entry[1]], prototype, entry[2])
				end
				for _, field in ipairs(other_box_fields) do
					move_limits(label, prototype[field], prototype, nil)
				end
				for _, box in ipairs(type(prototype.fluid_boxes) == "table" and prototype.fluid_boxes or {}) do
					move_limits(label, box, prototype, nil)
				end

				local source = prototype.energy_source
				if type(source) == "table" and source.type == "fluid" then
					move_limits(label .. " energy source", source.fluid_box, source, input_names)
					if source.maximum_temperature == 0 then
						source.maximum_temperature = nil
						log_change(label .. ": fluid energy source maximum_temperature 0 -> nil (no limit)")
					end
				end
			end
		end
	end
end

local function variation_of(water)
	return water.shader_variation or "water"
end

local function is_noise_file(texture)
	local file = string.lower(texture.filename or "")
	return file:find("noise", 1, true) ~= nil or file:find("gradient", 1, true) ~= nil
end

local function fix_water_effects()
	local effects = data.raw["tile-effect"] or {}

	local noise_by_variation = {}
	for _, effect in pairs(effects) do
		-- table: the API library of the check predates 2.1.22 and has no noise_textures yet
		local water = effect.water --[[@as table]]
		if type(water) == "table" and water.noise_textures and not noise_by_variation[variation_of(water)] then
			noise_by_variation[variation_of(water)] = water.noise_textures
		end
	end

	for name, effect in pairs(effects) do
		-- table: the API library of the check predates 2.1.22 and has no noise_textures yet
		local water = effect.water --[[@as table]]
		if type(water) == "table" and water.textures and not water.noise_textures then
			local old = water.textures
			local noise = noise_by_variation[variation_of(water)]
			if noise then
				water.noise_textures = table.deepcopy(noise)
			elseif old[1] then
				water.noise_textures = {table.deepcopy(old[1])}
				water.noise_textures[1].size = water.noise_textures[1].size or 512
			end

			local images = {}
			for index = 2, #old do
				if not is_noise_file(old[index]) then
					images[#images + 1] = table.deepcopy(old[index])
				end
			end
			water.image_textures = #images > 0 and images or nil

			water.textures = nil
			water.texture_variations_rows = nil
			water.texture_variations_columns = nil
			water.secondary_texture_variations_rows = nil
			water.secondary_texture_variations_columns = nil
			log_change("tile-effect/" .. name .. ": water textures -> noise_textures (" .. variation_of(water) .. ") and image_textures")
		end
	end
end

function factorio_2_1_22.data_final_fixes()
	if not version_at_least(mods["base"], {2, 1, 22}) then
		return
	end

	fix_fluid_boxes()
	fix_water_effects()
end

return factorio_2_1_22
