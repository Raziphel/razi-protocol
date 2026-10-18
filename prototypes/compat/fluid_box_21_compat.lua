-- TEMPORARY Factorio 2.1.22 compatibility bridge.
-- Wube removed FluidBox.minimum_temperature / maximum_temperature.
-- Keep source mods intact while they migrate to machine-level input limits.
-- TODO: remove this bridge once all required planet mods support 2.1.22.
local M = {}

local function requires_bridge()
  local version = mods and mods["base"]
  if type(version) ~= "string" then return false end
  local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)")
  major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
  return major and (major > 2 or
    (major == 2 and (minor > 1 or (minor == 1 and patch >= 22))))
end

-- Temperatures above a fluid's own limit are invalid as input constraints.
local function allowed_temperature(value, box)
  if type(value) ~= "number" or type(box.filter) ~= "string" then
    return value
  end
  local fluid = data.raw.fluid and data.raw.fluid[box.filter]
  local limit = fluid and fluid.max_temperature
  return type(limit) == "number" and math.min(value, limit) or value
end

local function migrate_box(box, owner, minimum_key, maximum_key)
  if type(box) ~= "table" then return 0 end
  local minimum = box.minimum_temperature
  local maximum = box.maximum_temperature
  if minimum == nil and maximum == nil then return 0 end

  -- Never overwrite a limit already explicitly set via the new API.
  if owner and minimum_key and minimum ~= nil and owner[minimum_key] == nil then
    owner[minimum_key] = allowed_temperature(minimum, box)
  end
  if owner and maximum_key and maximum ~= nil and owner[maximum_key] == nil then
    owner[maximum_key] = allowed_temperature(maximum, box)
  end

  box.minimum_temperature = nil
  box.maximum_temperature = nil
  return 1
end

-- Only these machine types accept the new generic input-temperature fields.
local input_box_by_type = {
  ["boiler"] = "fluid_box",
  ["generator"] = "fluid_box",
  ["fusion-generator"] = "input_fluid_box",
  ["fusion-reactor"] = "input_fluid_box",
  ["mining-drill"] = "input_fluid_box",
}

function M.data_final_fixes()
  if not requires_bridge() then return 0 end

  local repaired = 0
  for prototype_type, prototypes in pairs(data.raw) do
    if type(prototypes) == "table" then
      for _, prototype in pairs(prototypes) do
        if type(prototype) == "table" then
          local input_key = input_box_by_type[prototype_type]
          local input_box = input_key and prototype[input_key]

          -- Preserve real input constraints for generators, boilers, drills,
          -- and fusion machines; this also covers Corrundum's red-steam-engine.
          repaired = repaired + migrate_box(input_box, prototype,
            "minimum_input_temperature", "maximum_input_temperature")

          -- Other direct fluid boxes have no equivalent machine-level input
          -- constraint; only strip the fields removed from FluidBox itself.
          for _, key in ipairs({"fluid_box", "input_fluid_box",
                                "output_fluid_box"}) do
            if key ~= input_key then
              repaired = repaired + migrate_box(prototype[key])
            end
          end

          -- Thrusters have separate temperature bounds for both fluids.
          if prototype_type == "thruster" then
            repaired = repaired + migrate_box(prototype.fuel_fluid_box,
              prototype, "minimum_fuel_temperature",
              "maximum_fuel_temperature")
            repaired = repaired + migrate_box(prototype.oxidizer_fluid_box,
              prototype, "minimum_oxidizer_temperature",
              "maximum_oxidizer_temperature")
          else
            repaired = repaired + migrate_box(prototype.fuel_fluid_box)
            repaired = repaired + migrate_box(prototype.oxidizer_fluid_box)
          end

          -- Crafting machines can contain several ordinary fluid boxes.
          if type(prototype.fluid_boxes) == "table" then
            for _, box in pairs(prototype.fluid_boxes) do
              repaired = repaired + migrate_box(box)
            end
          end

          local energy_source = prototype.energy_source
          if type(energy_source) == "table" and
              energy_source.type == "fluid" then
            repaired = repaired + migrate_box(energy_source.fluid_box,
              energy_source, "minimum_input_temperature",
              "maximum_input_temperature")
            repaired = repaired + migrate_box(energy_source.output_fluid_box)

            -- 2.1.22 changed the old zero-means-unlimited convention.
            if energy_source.maximum_temperature == 0 then
              energy_source.maximum_temperature = nil
            end
          end
        end
      end
    end
  end

  if repaired > 0 and type(log) == "function" then
    log("[Razi Protocol/2.1.22] Repaired " .. repaired ..
      " obsolete FluidBox temperature declarations")
  end
  return repaired
end

return M
