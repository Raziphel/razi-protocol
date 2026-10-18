package.path = "./?.lua;./?/init.lua;" .. package.path
local M = require("temporary.factorio_2_1_22.tile_effects")
local function check(ok, message)
  if not ok then error(message, 2) end
end

local function legacy_effect()
  return {water = {
    shader_variation = "wetland-water",
    textures = {
      {filename = "__space-age__/graphics/terrain/gleba/watercaustics.png",
       width = 512, height = 512},
      {filename = "__planetaris-tellus__/graphics/terrain/tellus/wetland-dead-skin-shader.png",
       width = 2048, height = 1024}
    },
    texture_variations_rows = 1, texture_variations_columns = 1,
    secondary_texture_variations_rows = 2,
    secondary_texture_variations_columns = 4,
    animation_speed = 1.5,
    animation_scale = {1.5, 1.5},
    lightmap_alpha = 0
  }}
end

local function run(raw, base_version, tellus)
  local loaded = {base = base_version or "2.1.22"}
  if tellus ~= false then loaded["planetaris-tellus"] = "1.1.15" end
  rawset(_G, "mods", loaded)
  rawset(_G, "data", {raw = {["tile-effect"] = raw}})
  return M.data_final_fixes()
end

local blue = legacy_effect()
local cyan = legacy_effect()
cyan.water.textures[2].filename =
  "__planetaris-tellus__/graphics/terrain/tellus/wetland-cyan-slime-shader.png"
local already_fixed = {water = {
  shader_variation = "wetland-water",
  noise_textures = {{filename = "noise.png", size = 512}},
  image_textures = {{filename = "image.png"}}
}}
local wrong_shader = {water = {
  shader_variation = "lava",
  textures = {{filename = "a.png"}, {filename = "b.png"}}
}}
local invalid = {water = {
  shader_variation = "wetland-water",
  textures = {{filename = "a.png"}, {filename = "b.png"}, {filename = "c.png"}}
}}
local raw = {
  ["wetland-blue-slime"] = blue,
  ["wetland-tellus-cyan"] = cyan,
  ["wetland-updated"] = already_fixed,
  ["test-lava"] = wrong_shader,
  ["test-unknown"] = invalid
}
check(run(raw) == 2, "Repair both Tellus legacy wetland tile effects")
check(blue.water.textures == nil and cyan.water.textures == nil,
  "Removed legacy textures property from repaired effects")
check(blue.water.noise_textures[1].filename ==
  "__space-age__/graphics/terrain/gleba/watercaustics.png",
  "Preserve Tellus caustics noise texture")
check(blue.water.image_textures[1].filename ==
  "__planetaris-tellus__/graphics/terrain/tellus/wetland-dead-skin-shader.png",
  "Preserve Tellus wetland atlas rather than borrowing unrelated art")
check(blue.water.noise_textures[1].size == 512 and
  blue.water.image_textures[1].width == nil,
  "Use the new EffectTexture and EffectArrayTexture shape")
check(blue.water.secondary_texture_variations_columns == nil and
  blue.water.texture_variations_rows == nil,
  "Strip 2.1-removed variation fields")
check(blue.water.animation_speed == 1.5 and blue.water.lightmap_alpha == 0,
  "Do not change water animation or lighting")
check(already_fixed.water.image_textures[1].filename == "image.png",
  "Leave modern water prototypes untouched")
check(wrong_shader.water.textures ~= nil and invalid.water.textures ~= nil,
  "Do not guess or alter other shaders or unknown texture counts")
check(run(raw) == 0, "Repair should be idempotent")

local old = {["wetland-blue-slime"] = legacy_effect()}
check(run(old, "2.1.21") == 0 and old["wetland-blue-slime"].water.textures,
  "Do not change legacy fields on older Factorio")
local absent = {["wetland-blue-slime"] = legacy_effect()}
check(run(absent, "2.1.22", false) == 1 and
  absent["wetland-blue-slime"].water.textures == nil,
  "Repair legacy water effects regardless of which mod owns them")
print("Planetaris Tellus wetland tile effect compatibility passed")
