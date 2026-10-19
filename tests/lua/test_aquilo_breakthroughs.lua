-- Isolated data-final-fixes fixture, executable with a Lua interpreter.
package.path = "./?.lua;./?/init.lua;" .. package.path
local M = require("prototypes.technology.aquilo_breakthroughs")
local function check(ok, message) if not ok then error(message, 2) end end
local function node(parents)
  return {
    prerequisites = parents or {},
    unit = {count = 2000, ingredients = {{"cryogenic-science-pack", 1}}},
    effects = {{type = "unlock-recipe", recipe = "original-recipe"}}
  }
end
local function fixture()
  local t = {
    ["foundation"] = node({"cryogenic-science-pack"}),
    ["fusion-reactor"] = node({"cryogenic-science-pack"}),
    ["legendary-quality"] = node({"epic-quality"}),
    ["cryogenic-science-pack"] = node(),
    ["epic-quality"] = node(),
    ["planet-discovery-paracelsin"] = node(),
    ["planet-discovery-maraxsis"] = node(),
    ["planet-discovery-cubium"] = node(),
    ["planet-discovery-tenebris"] = node(),
    ["razi-outer-frontier-mastery"] = node({
      "planet-discovery-frozeta", "planet-discovery-vesta",
      "linox-technology_planet-discovery-linox"
    }),
    ["planet-discovery-frozeta"] = node(),
    ["planet-discovery-vesta"] = node(),
    ["linox-technology_planet-discovery-linox"] = node(),
    ["rocket-silo"] = node()
  }
  return {technology = t}
end
local function has(list, name)
  for _, value in ipairs(list or {}) do if value == name then return true end end
  return false
end
local raw = fixture()
rawset(_G, "data", {raw = raw})
rawset(_G, "settings", {startup = {
  ["razi-stage-aquilo-breakthroughs"] = {value = true}
}})
M.data_final_fixes()
check(has(raw.technology.foundation.prerequisites, "planet-discovery-maraxsis")
  and has(raw.technology.foundation.prerequisites, "planet-discovery-paracelsin"),
  "Foundation should await both mid-frontier worlds")
check(has(raw.technology["fusion-reactor"].prerequisites, "planet-discovery-cubium")
  and has(raw.technology["fusion-reactor"].prerequisites, "planet-discovery-tenebris"),
  "Fusion should await both first outer-world branches")
check(has(raw.technology["legendary-quality"].prerequisites,
  "razi-outer-frontier-mastery"),
  "Legendary quality should await outer-frontier mastery")
check(#raw.technology["fusion-reactor"].unit.ingredients == 1
  and #raw.technology["fusion-reactor"].effects == 1,
  "Must preserve original fusion science and recipe effects")
check(#raw.technology["rocket-silo"].prerequisites == 0,
  "Must not change bootstrap technology")
local count = #raw.technology.foundation.prerequisites
M.data_final_fixes()
check(#raw.technology.foundation.prerequisites == count,
  "Stage pass must be idempotent")
local cycle = fixture()
cycle.technology["planet-discovery-cubium"].prerequisites = {"fusion-reactor"}
local before = #cycle.technology["fusion-reactor"].prerequisites
check(not M.apply(cycle, M.rules[2]),
  "A world requiring fusion cannot be a prerequisite for fusion")
check(#cycle.technology["fusion-reactor"].prerequisites == before,
  "A skipped cycle must not leave a partial gate")
local missing = fixture()
missing.technology["planet-discovery-maraxsis"] = nil
check(not M.apply(missing, M.rules[1]),
  "A missing planetary research must preserve native foundation")
check(#missing.technology.foundation.prerequisites == 1,
  "Missing planet must not add the other prerequisite")
local disabled = fixture()
disabled.technology["legendary-quality"].enabled = false
check(not M.apply(disabled, M.rules[3]), "Disabled quality stays disabled")
local legacy = fixture()
data.raw = legacy
settings.startup["razi-stage-aquilo-breakthroughs"].value = false
M.data_final_fixes()
check(#legacy.technology.foundation.prerequisites == 1 and
  #legacy.technology["fusion-reactor"].prerequisites == 1 and
  #legacy.technology["legendary-quality"].prerequisites == 1,
  "Legacy setting must preserve source unlock timing")
print("Aquilo staged upgrades, cycle safety, source ownership and opt-out passed")
