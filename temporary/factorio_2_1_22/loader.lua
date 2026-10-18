-- Removable entry point for the temporary 2.1.22 compatibility patches.
local M = {}
local function applies()
  local v = mods and mods.base
  if type(v) ~= "string" then return false end
  local a,b,c = v:match("^(%d+)%.(%d+)%.(%d+)")
  a,b,c=tonumber(a),tonumber(b),tonumber(c)
  return a and (a > 2 or (a == 2 and (b > 1 or (b == 1 and c >= 22))))
end
function M.data_final_fixes()
  if not applies() then return 0 end
  local fluid=require("temporary.factorio_2_1_22.fluid_boxes").data_final_fixes()
  local tile=require("temporary.factorio_2_1_22.tile_effects").data_final_fixes()
  local unresolved=require("temporary.factorio_2_1_22.audit").scan()
  if type(log)=="function" then
    log("[Razi Protocol/2.1.22 temporary] fluid=" .. fluid ..
      ", tile=" .. tile .. ", unresolved=" .. unresolved)
  end
  return fluid+tile
end
return M
