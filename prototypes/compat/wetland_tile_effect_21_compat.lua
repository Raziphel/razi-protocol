-- TEMPORARY compatibility for Planetaris: Tellus on Factorio 2.1.22+.
-- Factorio split WaterTileEffectParameters.textures into noise_textures
-- (EffectTexture) and image_textures (EffectArrayTexture). Tellus 1.1.15
-- still supplies the former for Gleba-style wetland-water tile effects.
-- Preserve the source texture filenames and water appearance until updated.
local M = {}

local function requires_bridge()
  if not (mods and mods["planetaris-tellus"]) then return false end
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

function M.data_final_fixes()
  if not requires_bridge() then return 0 end
  local fixed = 0
  for name, effect in pairs(data.raw["tile-effect"] or {}) do
    if migrate_water(effect) then
      fixed = fixed + 1
      if type(log) == "function" then
        log("[Razi Protocol/2.1.22] Migrated legacy wetland tile effect: " .. name)
      end
    end
  end
  return fixed
end

return M
