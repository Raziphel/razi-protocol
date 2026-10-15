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
      water.textures=nil
      count=count+1
    end
  end
  return count
end
return M
