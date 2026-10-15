local M={}
function M.data_final_fixes()
  if not (mods and mods["a-razi-lava-compat"]) then return 0 end
  local cleaner=require("__a-razi-lava-compat__/prototypes/cleanup")
  local count=cleaner.clean()
  if type(log)=="function" then
    log("[Razi Protocol/lava] Final cleanup of "..count..
      " temporary lava texture compatibility aliases")
  end
  return count
end
return M
