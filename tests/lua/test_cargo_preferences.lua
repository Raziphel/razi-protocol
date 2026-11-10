-- Cargo tab preferences accept only the two supported page IDs.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message)
  if not ok then error(message,2) end
end

storage={}
package.loaded["scripts.journal.api"]={}
package.loaded["lib.story"]={visible=function() return false end}
package.loaded["scripts.journal.projects"]={valid=function(value)
  return value=="platform"
end}
local preferences=require("scripts.journal.preferences")
local value=preferences(1)
check(value.cargo_tab=="overview","new players open the Overview tab")
value.cargo_tab="freight"
check(preferences(1).cargo_tab=="freight","Freight is a saved tab")
value.cargo_tab="other"
check(preferences(1).cargo_tab=="overview","unknown tabs normalize to Overview")
value.cargo_tab=false
check(preferences(1).cargo_tab=="overview","non-string tabs normalize to Overview")

print("test_cargo_preferences: ok")
