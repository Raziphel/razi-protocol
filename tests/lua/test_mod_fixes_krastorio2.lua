---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(value, message)
  if not value then error(message, 2) end
end
local logs = {}
rawset(_G, "log", function(message) logs[#logs + 1] = message end)
local function logged(text)
  local count = 0
  for _, line in ipairs(logs) do
    if line:find(text, 1, true) then count = count + 1 end
  end
  return count
end

---@return any
local function fresh()
  logs = {}
  local raw = {}
  rawset(_G, "data", {raw = raw})
  return raw
end

local fixes = require("prototypes.compat.mod_fixes")

-- Nothing of Krastorio 2 is installed: every repair is quiet and does not fail.
---@type any
local raw = fresh()
fixes.data_final_fixes()
check(#logs == 0, "A repair logged without its prototypes")
check(next(raw) == nil, "A repair created a prototype type")
raw = fresh()
raw.recipe = {}
raw.technology = {}
raw.roboport = {}
raw.loader = {}
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- loader_insert_limits
raw = fresh()
raw.loader = {
  ["kr-loader"] = {type = "loader"},
  ["kr-fast-loader"] = {type = "loader", respect_insert_limits = false},
  ["kr-done"] = {type = "loader", respect_insert_limits = true},
}
raw["loader-1x1"] = {["hidden-loader"] = {type = "loader-1x1"}}
fixes.data_final_fixes()
check(raw.loader["kr-loader"].respect_insert_limits == true, "A loader without the flag was not changed")
check(raw.loader["kr-fast-loader"].respect_insert_limits == true, "A loader with the flag off was not changed")
check(raw["loader-1x1"]["hidden-loader"].respect_insert_limits == true, "loader-1x1 was not changed")
check(logged("respects the insertion limit") == 3, "Expected one line for each of the three changed loaders, got " .. logged("respects the insertion limit"))
check(logs[1]:find("^razi%-protocol: "), "The line does not start with the mod name")

-- roboport_mode_names
raw = fresh()
local function roboport(name, localised_name, localised_description)
  return {type = "roboport", name = name, localised_name = localised_name, localised_description = localised_description,
    logistics_radius = 25, construction_radius = 55}
end
local function variant(name, mode)
  return {type = "roboport", name = name .. "-" .. mode .. "-mode",
    localised_name = {"entity-name.kr-" .. mode .. "-roboport", {"entity-name." .. name}},
    localised_description = {"entity-description." .. name},
    logistics_radius = mode == "construction" and 0 or 31, construction_radius = mode == "construction" and 69 or 0}
end
raw.roboport = {}
for _, name in ipairs({"roboport", "bio-roboport"}) do
  raw.roboport[name] = roboport(name)
  for _, mode in ipairs({"logistic", "construction"}) do
    raw.roboport[name .. "-" .. mode .. "-mode"] = variant(name, mode)
  end
end
raw.roboport["bio-roboport"].localised_name = {"", "Bioluminescent ", "x"}
raw.roboport["bio-roboport"].localised_description = {"entity-description.bio"}
raw.roboport["custom-roboport"] = roboport("custom-roboport", {"entity-name.shown"})
raw.roboport["custom-roboport-logistic-mode"] = variant("custom-roboport", "logistic")
raw.roboport["custom-roboport-logistic-mode"].localised_name = {"entity-name.chosen-by-the-mod"}
raw.roboport["custom-roboport-logistic-mode"].localised_description = {"entity-description.chosen-by-the-mod"}
fixes.data_final_fixes()
---@type any
local named = raw.roboport["bio-roboport-logistic-mode"]
check(named.localised_name[1] == "entity-name.kr-logistic-roboport" and named.localised_name[2][1] == "",
  "The mode did not take the shown name of its roboport")
check(raw.roboport["bio-roboport-construction-mode"].localised_description[1] == "entity-description.bio",
  "The mode did not take the description of its roboport")
---@type any
local plain = raw.roboport["roboport-logistic-mode"]
check(plain.localised_name[2][1] == "entity-name.roboport", "A roboport without a name was renamed")
check(plain.localised_description[1] == "?" and plain.localised_description[2][1] == "entity-description.roboport"
  and plain.localised_description[3] == "", "A roboport without a description key did not fall back to nothing")
check(raw.roboport["custom-roboport-logistic-mode"].localised_name[1] == "entity-name.chosen-by-the-mod",
  "A name that the source mod did not write was changed")
check(raw.roboport["custom-roboport-logistic-mode"].localised_description[1] == "entity-description.chosen-by-the-mod",
  "A description that the source mod did not write was changed")
check(logged("takes the shown name and description") == 4, "Expected a line for each of the four modes, got "
  .. logged("takes the shown name and description"))
logs = {}
fixes.data_final_fixes()
check(logged("takes the shown name and description") == 0, "The repeated run touched the modes again")

-- void_crushing
local function recipe(categories, ingredients)
  local list = {}
  for _, ingredient in ipairs(ingredients) do
    list[#list + 1] = {type = ingredient.type or "item", name = ingredient.name, amount = 1}
  end
  return {categories = categories, ingredients = list}
end
raw = fresh()
raw.recipe = {
  ["kr-crush-bones"] = recipe({"kr-crushing"}, {{name = "bones"}}),
  ["kr-void-bones"] = recipe({"kr-void-crushing"}, {{name = "bones"}}),
  ["salvage-ice"] = recipe({"kr-crushing"}, {{name = "rocket-chunk"}, {name = "ice"}}),
  ["kr-void-ice"] = recipe({"kr-void-crushing"}, {{name = "ice"}}),
  ["kr-crush-water"] = recipe({"kr-crushing"}, {{name = "water", type = "fluid"}}),
  ["kr-void-water"] = recipe({"kr-void-crushing"}, {{name = "water"}}),
  ["kr-void-slag"] = recipe({"kr-void-crushing"}, {{name = "slag"}}),
}
raw.technology = {
  ["kr-tech"] = {effects = {
    {type = "unlock-recipe", recipe = "kr-void-bones"},
    {type = "unlock-recipe", recipe = "kr-void-ice"},
    {type = "unlock-recipe", recipe = "kr-void-bones"},
  }},
  ["no-effects"] = {},
}
fixes.data_final_fixes()
check(raw.recipe["kr-void-bones"] == nil, "The void recipe of a crushed item stayed")
check(raw.recipe["kr-crush-bones"] ~= nil, "The real crushing recipe was removed")
check(raw.recipe["kr-void-ice"] ~= nil, "The void recipe of an item crushed only among several ingredients was removed")
check(raw.recipe["kr-void-slag"] ~= nil, "The void recipe of an item without a crushing recipe was removed")
check(raw.recipe["kr-void-water"] ~= nil, "A fluid ingredient counted as crushed")
---@type any
local tech_effects = raw.technology["kr-tech"].effects
check(#tech_effects == 1 and tech_effects[1].recipe == "kr-void-ice", "The effects of the removed recipe stayed")
check(logged("removed void crushing recipe kr-void-bones") == 1 and logged("removed void crushing recipe") == 1,
  "Expected one line for the removed recipe")
-- piercing_shotgun
local function shell(projectile)
  return {["piercing-shotgun-shell"] = {ammo_type = {action = {
    {action_delivery = {type = "projectile", projectile = "shotgun-pellet"}},
    {action_delivery = {type = "projectile", projectile = projectile}},
  }}}}
end
raw = fresh()
raw.ammo = shell("shotgun-pellet")
raw.projectile = {["piercing-shotgun-pellet"] = {}}
fixes.data_final_fixes()
---@type any
local actions = raw.ammo["piercing-shotgun-shell"].ammo_type.action
check(actions[1].action_delivery.projectile == "piercing-shotgun-pellet" and actions[2].action_delivery.projectile == "piercing-shotgun-pellet",
  "The shell still fires plain pellets")
check(logged("fires piercing-shotgun-pellet") == 2, "Expected a line for each changed action")
raw = fresh()
raw.ammo = shell("custom-pellet")
raw.projectile = {["piercing-shotgun-pellet"] = {}}
fixes.data_final_fixes()
check(raw.ammo["piercing-shotgun-shell"].ammo_type.action[2].action_delivery.projectile == "custom-pellet",
  "A projectile the source mod did not write was changed")
raw = fresh()
raw.ammo = shell("shotgun-pellet")
raw.projectile = {}
fixes.data_final_fixes()
check(raw.ammo["piercing-shotgun-shell"].ammo_type.action[1].action_delivery.projectile == "shotgun-pellet" and #logs == 0,
  "The shell was changed although the piercing pellet does not exist")

-- construction_roboport
raw = fresh()
raw.roboport = {
  ["roboport-construction-mode"] = {logistics_radius = 0, construction_radius = 55},
  ["big-roboport-construction-mode"] = {construction_radius = 100},
  ["spare-roboport-construction-mode"] = {logistics_radius = 4, construction_radius = 55},
  ["idle-roboport-construction-mode"] = {logistics_radius = 0, construction_radius = 0},
  ["roboport-logistic-mode"] = {logistics_radius = 0, construction_radius = 55},
}
fixes.data_final_fixes()
check(raw.roboport["roboport-construction-mode"].logistics_radius == 1, "A construction roboport kept the zero radius")
check(raw.roboport["big-roboport-construction-mode"].logistics_radius == 1, "A missing radius counts as zero")
check(raw.roboport["spare-roboport-construction-mode"].logistics_radius == 4, "A changed radius was overwritten")
check(raw.roboport["idle-roboport-construction-mode"].logistics_radius == 0, "A roboport that does not build was changed")
check(raw.roboport["roboport-logistic-mode"].logistics_radius == 0, "A logistic mode was changed")
check(logged("has logistics_radius = 1") == 2, "Expected two changed construction roboports")


print("test_mod_fixes_krastorio2: ok")
