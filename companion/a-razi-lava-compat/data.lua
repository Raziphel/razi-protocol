-- Factorio 2.1 lava uses water.image_textures[1].
-- Older planet data.lua files index lava.water.textures[2].
-- This small companion loads before these independent source mods.
local bridged=0
for _,effect in pairs(data.raw["tile-effect"] or {}) do
  local water=effect.water
  if type(water)=="table" and water.shader_variation=="lava"
    and type(water.image_textures)=="table"
    and type(water.image_textures[1])=="table"
    and water.textures==nil then
    -- Keep BOTH references on the original image table so util.merge
    -- and table.deepcopy retain recolors made by legacy source mods.
    water.textures={
      [1]=water.image_textures[1],
      [2]=water.image_textures[1]
    }
    bridged=bridged+1
  end
end
if type(log)=="function" then
  log("[Razi Lava Compat] Prepared "..bridged.." legacy lava aliases")
end
