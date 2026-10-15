local cleaner=require("prototypes.cleanup")
local cleaned=cleaner.clean()
if type(log)=="function" then
  log("[Razi Lava Compat] Removed "..cleaned.." legacy lava aliases")
end
