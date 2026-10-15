-- Temporary compatibility aliases must not reach Factorio's
-- final tile-effect prototype validation, including source-mod clones.
local M={}
function M.clean()
  local count=0
  for _,effect in pairs((data.raw or {})["tile-effect"] or {}) do
    local water=effect.water
    if type(water)=="table" and water.shader_variation=="lava"
      and type(water.image_textures)=="table"
      and type(water.textures)=="table" and water.textures[2] then
      local legacy=water.textures[2]
      local image=water.image_textures[1]
      -- Recursive util.merge can copy the old and new images separately.
      -- Preserve source-mod lava recolors before removing legacy fields.
      if type(legacy)=="table" and type(image)=="table"
        and type(legacy.filename)=="string"
        and legacy.filename~=image.filename
        and not legacy.filename:find("^__space%-age__/") then
        image.filename=legacy.filename
      end
      water.textures=nil
      count=count+1
    end
  end
  return count
end
return M
