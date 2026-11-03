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


print("test_mod_fixes_krastorio2: ok")
