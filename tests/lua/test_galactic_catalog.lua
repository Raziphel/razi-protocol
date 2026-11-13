-- Canonical location IDs must map to one Atlas system only.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local catalog=require("lib.galactic_catalog")

local expected={
  ["planet-dea-dia"]="nyxaris",
  ferrum="beetlejuice",
  ["bellicos-orbit"]="aegis",
  ["black-hole-approach"]="deep-space",
  sol="deep-space",
  skewer_shattered_planet="deep-space",
  skewer_lost_beyond="deep-space"
}
for name,group in pairs(expected) do
  check(catalog.system(name)==group,
    name.." should belong to "..group..", got "..catalog.system(name))
end
for _,name in ipairs({"dea-dia","planet-ferrum","near-bellicos-orbit",
  "bellicos-near-orbit","near_bellicos_orbit"}) do
  check(catalog.system(name)=="unassigned",
    name.." is not a canonical space location")
end

print("Galactic catalog canonical location IDs passed")
