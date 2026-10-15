package.path = "./?.lua;./?/init.lua;" .. package.path
local M = require("prototypes.compat.heat_inserter_research")
local function check(condition, message)
  if not condition then error(message, 2) end
end
local function run(technologies)
  rawset(_G, "data", {raw = {technology = technologies}})
  return M.data_final_fixes()
end
local linox = "linox-technology_neodymium-permanent-magnet-inserter"
local heat = "heat-linox-building_neodymium-bulk-inserter"

local techs = {
  ["bulk-heat-inserter"] = {hidden = true, prerequisites = {"nuclear-power"}},
  ["bulk-inserter"] = {prerequisites = {"fast-inserter"}},
  [linox] = {prerequisites = {"linox-technology_neodymium-permanent-magnet"}},
  [heat] = {prerequisites = {"bulk-heat-inserter", linox}, unit = {count = 1500}},
  ["other-research"] = {prerequisites = {"bulk-inserter"}},
  ["hidden-variant"] = {hidden = true, prerequisites = {"bulk-heat-inserter"}},
  ["disabled-variant"] = {enabled = false, prerequisites = {"bulk-heat-inserter"}}
}
check(run(techs) == 1, "Only one visible descendant should be repaired")
local parents = techs[heat].prerequisites
check(#parents == 2 and parents[1] == linox and parents[2] == "bulk-inserter",
  "Restore native bulk tier while retaining Linox's late-game gate")
check(techs[heat].unit.count == 1500, "Science cost must remain untouched")
check(techs["other-research"].prerequisites[1] == "bulk-inserter",
  "Unrelated research must remain untouched")
check(techs["hidden-variant"].prerequisites[1] == "bulk-heat-inserter",
  "Do not rewrite intentionally hidden technologies")
check(techs["disabled-variant"].prerequisites[1] == "bulk-heat-inserter",
  "Do not rewrite disabled technologies")
check(run(techs) == 0, "Repair must be idempotent")

local generated = {
  ["bulk-heat-inserter"] = {hidden = true},
  ["bulk-inserter"] = {},
  [linox] = {},
  [heat] = {prerequisites = {"bulk-heat-inserter"}}
}
check(run(generated) == 1, "Orphaned generated research should be fixed")
check(#generated[heat].prerequisites == 2
  and generated[heat].prerequisites[1] == "bulk-inserter"
  and generated[heat].prerequisites[2] == linox,
  "Generated variant must require both normal bulk and native Linox progression")

local unavailable_native = {
  ["bulk-heat-inserter"] = {enabled = false},
  ["bulk-inserter"] = {hidden = true},
  [linox] = {},
  [heat] = {prerequisites = {"bulk-heat-inserter"}}
}
check(run(unavailable_native) == 1
  and #unavailable_native[heat].prerequisites == 1
  and unavailable_native[heat].prerequisites[1] == linox,
  "Never replace a hidden prerequisite with another hidden prerequisite")

local visible_native = {
  ["bulk-heat-inserter"] = {},
  [heat] = {prerequisites = {"bulk-heat-inserter"}}
}
check(run(visible_native) == 0
  and visible_native[heat].prerequisites[1] == "bulk-heat-inserter",
  "Leave the original chain intact when the heat technology is available")

local cyclic = {
  ["bulk-heat-inserter"] = {hidden = true},
  ["bulk-inserter"] = {prerequisites = {heat}},
  [linox] = {},
  [heat] = {prerequisites = {"bulk-heat-inserter"}}
}
check(run(cyclic) == 1
  and #cyclic[heat].prerequisites == 1
  and cyclic[heat].prerequisites[1] == linox,
  "Do not introduce a technology prerequisite cycle")
print("Heat/Neodymium bulk-inserter research compatibility passed")
