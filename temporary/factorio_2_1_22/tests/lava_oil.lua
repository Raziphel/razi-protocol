package.path = "./?.lua;./?/init.lua;" .. package.path
local module = require("temporary.factorio_2_1_22.tile_effects")
local function check(ok, reason) if not ok then error(reason, 2) end end
local function legacy(variation, old)
  return {water = {shader_variation = variation, textures = old,
    texture_variations_columns = 1, secondary_texture_variations_rows = 2,
    animation_speed = 1.5, foam_color = {59, 30, 9}}}
end
local function tex(name, width, height)
  return {filename = name, width = width or 512, height = height or 512}
end
local effects = {
  lava = {water = {shader_variation = "lava", noise_textures = {
    {filename = "lava-noise-1.png", size = 512, color_channels = 2},
    {filename = "lava-noise-2.png", size = 512, color_channels = 1}}}},
  ["oil-deep"] = {water = {shader_variation = "oil", noise_textures = {
    {filename = "oil-noise.png", size = 512, color_channels = 3},
    {filename = "oil-gradient.png", width = 512, height = 32, color_channels = 3}}}},
  ["cubium-lava"] = legacy("lava", {tex("cubium-old-noise.png"),
    tex("__cubium__/graphics/terrain/cubium/lava-textures/lava.png")}),
  ["cubium-lava-2"] = legacy("lava", {tex("cubium-old-noise.png"),
    tex("__cubium__/graphics/terrain/cubium/lava-textures/coastal-lava.png")}),
  ["other-oil"] = legacy("oil", {
    tex("old-noise"),
    tex("custom-oil-atlas.png", 2048, 1024),
    tex("old-gradient", 512, 32),
    tex("custom-oil-spec.png", 2048, 1024)}),
  ["bad-oil-atlas-size"] = legacy("oil", {
    tex("old-noise"), tex("atlas-2048.png", 2048, 1024),
    tex("oil-gradient.png", 512, 32), tex("spec-512.png", 512, 512)}),
  ["water-source"] = legacy("water", {tex("mod-water-noise.png")}),
  ["already-modern"] = {water = {shader_variation = "lava",
    noise_textures = {{filename = "a"}, {filename = "b"}}}},
  ["unknown-shader"] = legacy("lava", {tex("a"), tex("b"), tex("c")}),
}
rawset(_G, "mods", {base = "2.1.22", cubium = "1.0.32"})
rawset(_G, "data", {raw = {["tile-effect"] = effects}})
check(module.data_final_fixes() == 4, "Migrate both Cubium lava and oil/water")
for _, name in ipairs({"cubium-lava", "cubium-lava-2"}) do
  local water = effects[name].water
  check(water.textures == nil and #water.noise_textures == 2,
    "Cubium lava must have two noise textures and no legacy textures")
  check(water.noise_textures[1].filename == "lava-noise-1.png" and
    water.noise_textures[2].filename == "lava-noise-2.png",
    "Use the Factorio 2.1 lava noise pair")
  check(water.noise_textures[1].color_channels == 2 and
    water.noise_textures[2].color_channels == 1,
    "Keep the required noise color channel formats")
  check(water.image_textures[1].filename:find("__cubium__", 1, true),
    "Keep Cubium artwork instead of replacing it with vanilla graphics")
  check(water.image_textures[1].width == nil,
    "The image atlas must not use legacy texture dimensions")
  check(water.animation_speed == 1.5 and water.foam_color[1] == 59,
    "Keep source effect animation and styling")
  check(water.texture_variations_columns == nil,
    "Remove outdated texture variation declarations")
end
check(effects["other-oil"].water.noise_textures[2].filename == "oil-gradient.png"
  and #effects["other-oil"].water.image_textures == 2,
  "Oil requires two noise images and must preserve both art atlases")
check(effects["other-oil"].water.image_textures[1].filename ==
  "custom-oil-atlas.png" and
  effects["other-oil"].water.image_textures[2].filename ==
  "custom-oil-spec.png", "2.1 artwork must be legacy slots 2 and 4")
check(effects["bad-oil-atlas-size"].water.textures ~= nil,
  "Do not migrate oil when artwork dimensions do not match")
check(effects["water-source"].water.noise_textures[1].filename ==
  "mod-water-noise.png", "Ordinary water keeps its own noise texture")
check(effects["already-modern"].water.noise_textures[1].filename == "a"
  and effects["unknown-shader"].water.textures ~= nil,
  "Leave modern or unknown effects untouched")
check(module.data_final_fixes() == 0, "Repair should be idempotent")
local no_donor = {["cubium-lava"] = legacy("lava", {tex("old"), tex("atlas")})}
rawset(_G, "data", {raw = {["tile-effect"] = no_donor}})
check(module.data_final_fixes() == 0 and no_donor["cubium-lava"].water.textures,
  "Do not guess noise data if no vanilla reference exists")
print("Factorio 2.1.22 lava, oil and water compatibility passed")
