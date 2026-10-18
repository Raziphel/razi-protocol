-- TEMPORARY Factorio 2.1.22 texture compatibility bridge.
-- Legacy planet mods supply water.textures, but the 2.1 API requires separate
-- noise_textures and image_textures. Preserve native mod atlases and use
-- vanilla lava/oil noise pairs for Cubium and other affected effects.
local M = {}

local function requires_bridge()
  if not mods then return false end
  local version = mods["base"]
  if type(version) ~= "string" then return false end
  local major, minor, patch = version:match("^(%d+)%.(%d+)%.(%d+)")
  major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
  return major and (major > 2 or
    (major == 2 and (minor > 1 or (minor == 1 and patch >= 22))))
end

local function migrate_water(effect)
  local water = effect and effect.water
  if type(water) ~= "table" or
      water.shader_variation ~= "wetland-water" then return false end

  local legacy = water.textures
  if type(legacy) ~= "table" then return false end
  local noise, image = legacy[1], legacy[2]
  if type(noise) ~= "table" or type(image) ~= "table" or
      type(noise.filename) ~= "string" or
      type(image.filename) ~= "string" then return false end
  -- Only convert the known two-texture wetland format. Leave any other
  -- legacy arrangement alone rather than guess which images are noise.
  if legacy[3] ~= nil then return false end

  if water.noise_textures == nil then
    -- The noise texture is a single 512x512 image in the source format.
    water.noise_textures = {{
      filename = noise.filename,
      size = 512
    }}
  end
  if water.image_textures == nil then
    -- An image texture is the full source atlas; 2.1 derives tile counts
    -- from actual image dimensions instead of the old variations fields.
    water.image_textures = {{ filename = image.filename }}
  end

  -- Clear only after both replacement fields have been populated.
  if not (water.noise_textures[1] and water.image_textures[1]) then
    return false
  end
  water.textures = nil
  water.texture_variations_rows = nil
  water.texture_variations_columns = nil
  water.secondary_texture_variations_rows = nil
  water.secondary_texture_variations_columns = nil
  return true
end


-- Lava and oil must use TWO specialized noise textures in Factorio 2.1.
-- Their old single legacy noise file cannot meet the new channel layout.
-- Copy a validated vanilla noise pair, and retain the mod's own art atlas.
local function copy_texture(texture)
  if type(texture) ~= "table" or type(texture.filename) ~= "string" then
    return nil
  end
  local result = {}
  for key, value in pairs(texture) do result[key] = value end
  return result
end

local function donor_noise(effects, name)
  local effect = effects[name]
  local water = effect and effect.water
  local textures = water and water.noise_textures
  if type(textures) ~= "table" or #textures ~= 2 then return nil end
  local a, b = copy_texture(textures[1]), copy_texture(textures[2])
  return a and b and {a, b} or nil
end

local function image_texture(texture)
  if type(texture) ~= "table" or type(texture.filename) ~= "string" then
    return nil
  end
  -- The atlas dimensions are inferred from the image on the new API.
  return {filename = texture.filename}
end

local function migrate_other(effect, effects)
  local water = effect and effect.water
  local old = water and water.textures
  if type(old) ~= "table" then return false end
  local variation = water.shader_variation or "water"
  local noise, images

  if variation == "lava" and #old == 2 then
    noise = water.noise_textures or donor_noise(effects, "lava")
    local atlas = image_texture(old[2])
    images = atlas and {atlas}
  elseif variation == "oil" and #old == 4 then
    noise = water.noise_textures or donor_noise(effects, "oil-deep")
    local atlas, spec = image_texture(old[3]), image_texture(old[4])
    images = atlas and spec and {atlas, spec}
  elseif variation == "water" and #old == 1 then
    local tex = copy_texture(old[1])
    if tex and not tex.size and not tex.width and not tex.height then
      tex.size = 512
    end
    noise = water.noise_textures or (tex and {tex})
    images = {}
  else
    return false  -- Leave unfamiliar formats untouched, never guess.
  end

  if type(noise) ~= "table" or not images or
      ((variation == "lava" or variation == "oil") and #noise ~= 2) or
      (variation == "water" and #noise ~= 1) then return false end

  water.noise_textures = water.noise_textures or noise
  if water.image_textures == nil and #images > 0 then
    water.image_textures = images
  end
  water.textures = nil
  water.texture_variations_rows = nil
  water.texture_variations_columns = nil
  water.secondary_texture_variations_rows = nil
  water.secondary_texture_variations_columns = nil
  return true
end

function M.data_final_fixes()
  if not requires_bridge() then return 0 end
  local fixed = 0
  local effects = data.raw["tile-effect"] or {}
  for name, effect in pairs(effects) do
    if migrate_water(effect) or migrate_other(effect, effects) then
      fixed = fixed + 1
      if type(log) == "function" then
        log("[Razi Protocol/2.1.22] Migrated legacy tile effect: " .. name)
      end
    end
  end
  return fixed
end

return M
