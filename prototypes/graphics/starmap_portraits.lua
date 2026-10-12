-- Reuse the original stellar coronas as native UI sprites.
-- No extra PNGs or independent map drawables are needed.
local definitions = {"solaris", "nyxaris", "vibrant", "beetlejuice"}
local sprites = {}
for _, id in ipairs(definitions) do
  sprites[#sprites + 1] = {
    type = "sprite",
    name = "razi-system-portrait-" .. id,
    filename = "__razi-protocol__/graphics/starmap/" .. id .. "-corona.png",
    size = 256,
    scale = 0.5,
    priority = "medium",
    flags = {"gui-icon"}
  }
end
data:extend(sprites)
