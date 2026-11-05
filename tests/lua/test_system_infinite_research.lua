-- Standalone fixture for the eight-level system-science transition.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function copy(v)
  if type(v) ~= "table" then return v end
  local result = {}
  for k, value in pairs(v) do result[copy(k)] = copy(value) end
  return result
end
table.deepcopy = copy
local function check(ok, message) if not ok then error(message, 2) end end
data = {raw = {technology = {}, tool = {
  ["calidus-tech-card"] = {}, ["solaris-tech-card"] = {}
}, lab = {lab = {inputs = {
  "calidus-tech-card", "solaris-tech-card", "kr-matter-tech-card",
  "research-data", "other-science-pack"
}}}}}
function data:extend(prototypes)
  for _, item in ipairs(prototypes) do self.raw.technology[item.name] = item end
end
local function technology(name, ingredients, extras)
  local node = {type = "technology", name = name, order = "a",
    icon = "icon.png", icon_size = 256, max_level = "infinite",
    upgrade = true, effects = {{type = "change-recipe-productivity",
      recipe = "processing-unit", change = 0.1}},
    prerequisites = {"space-science-pack"},
    unit = {count_formula = "1000*1.5^L", time = 60, ingredients = ingredients}}
  for k, v in pairs(extras or {}) do node[k] = v end
  return node
end
data.raw.technology["processing-unit-productivity"] = technology(
  "processing-unit-productivity", {
    {"automation-science-pack", 1}, {"logistic-science-pack", 1},
    {"kr-matter-tech-card", 2}, {"research-data", 1}
  })
data.raw.technology["physical-projectile-damage-7"] = technology(
  "physical-projectile-damage-7", {
    {"automation-science-pack", 1}, {"space-science-pack", 1}
  }, {unit = {count_formula = "2^(L-7)*1000", time = 30,
    ingredients = {{"automation-science-pack", 1}, {"space-science-pack", 1}}}})
data.raw.technology["late-solaris"] = technology("late-solaris", {
  {"battlefield-science-pack", 2}, {"automation-science-pack", 1}})
data.raw.technology["never-map"] = technology("never-map",
  {{"other-science-pack", 1}})
data.raw.technology["scripted-research"] = technology("scripted-research",
  {{"automation-science-pack", 1}},
  {effects = {{type = "unlock-recipe", recipe = "danger"}}})
data.raw.technology["hidden-research"] = technology("hidden-research",
  {{"automation-science-pack", 1}}, {hidden = true})
local base = require("prototypes.technology.systems.infinite_research")
base.data_final_fixes()
local prefix = base.prefix
local name = prefix .. "processing-unit-productivity-cards"
local native = data.raw.technology["processing-unit-productivity"]
local continued = data.raw.technology[name]
check(continued and continued.enabled == false, "Continuation must start locked")
check(native.max_level == "infinite", "Existing technology and save ID must remain infinite")
check(continued.unit.ingredients[1][1] == "calidus-tech-card"
  and continued.unit.ingredients[2][1] == "kr-matter-tech-card"
  and continued.unit.ingredients[2][2] == 2
  and continued.unit.ingredients[3][1] == "research-data",
  "Composite card must replace only known source packs, preserving special data")
check(continued.unit.count_formula == "1000*1.5^(L+8)",
  "Unnumbered research must preserve the native per-level price")
check(data.raw.technology[prefix .. "physical-projectile-damage-7-cards"].name:sub(-6)
  == "-cards", "Numbered source tech must yield a level-one continuation")
check(data.raw.technology[prefix .. "physical-projectile-damage-7-cards"].unit.count_formula
  == "2^((L+14)-7)*1000", "Numbered upgrade must not reset exponential prices")
check(data.raw.technology[prefix .. "late-solaris-cards"].unit.ingredients[1][1]
  == "solaris-tech-card", "Regional sources must use their own system card")
check(not data.raw.technology[prefix .. "never-map-cards"]
  and not data.raw.technology[prefix .. "scripted-research-cards"]
  and not data.raw.technology[prefix .. "hidden-research-cards"],
  "Unsupported and scripted research must be unchanged")
base.data_final_fixes()
local n = 0
for k in pairs(data.raw.technology) do
  if k:sub(1, #prefix) == prefix then n = n + 1 end
end
check(n == 3, "Final pass must not duplicate the continuations")

local runtime = require("scripts.research.infinite_research")
local native_force = {name = native.name, level = 30, enabled = true}
local continued_force = {name = name, level = 1, enabled = false,
  research_unit_ingredients = {
    {name = "calidus-tech-card"}, {name = "kr-matter-tech-card"},
    {name = "research-data"}
  }}
local other = {name = "other-research"}
local resets = 0
local force = {technologies = {[native.name] = native_force, [name] = continued_force},
  recipes = {["calidus-tech-card"] = {enabled = false}},
  research_queue = {native_force, other},
  current_research = native_force, research_progress = 0.35,
  reset_technology_effects = function() resets = resets + 1 end}
runtime.sync_force(force)
check(native_force.level == 30 and continued_force.enabled == false
  and native_force.enabled == true,
  "No transition may happen before the card recipe is unlocked")
force.recipes["calidus-tech-card"].enabled = true
runtime.sync_force(force)
check(native_force.level == 9 and continued_force.level == 22,
  "Save at native level 30 must carry over all completed levels")
check(not native_force.enabled and continued_force.enabled,
  "Only the consolidated stage should remain researchable")
check(force.research_queue[1] == name and force.research_queue[2] == other.name,
  "Current research queue must point at the new technology")
check(resets == 1, "Existing-save effects must be recalculated once")
-- Merging another force with old level 35 must not add those 26 levels
-- on top of progress already credited on the continuation.
native_force.level = 35
runtime.sync_force(force)
check(native_force.level == 9 and continued_force.level == 27
  and resets == 2, "Merged progress must use the higher reached level")
runtime.sync_force(force)
check(native_force.level == 9 and continued_force.level == 27 and resets == 2,
  "Re-entering the save migration must be idempotent")
-- If the card becomes unavailable before the first continuation level,
-- do not leave an existing world with neither research path enabled.
local starting = {name = native.name, level = 9, enabled = true}
local waiting = {name = name, level = 1, enabled = false,
  research_unit_ingredients = {{name = "calidus-tech-card"}}}
local fresh = {technologies = {[native.name] = starting, [name] = waiting},
  recipes = {["calidus-tech-card"] = {enabled = true}}, research_queue = {}}
runtime.sync_force(fresh)
check(not starting.enabled and waiting.enabled,
  "The first eight native levels should open the system-card continuation")
fresh.recipes["calidus-tech-card"].enabled = false
runtime.sync_force(fresh)
check(starting.enabled and not waiting.enabled,
  "Missing cards must restore the original research until they return")
print("infinite system research: science mapping and existing-save transition passed")
