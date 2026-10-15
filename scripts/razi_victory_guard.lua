-- The Convergence final delivery is Razi Protocol's ONLY real win.
-- These are documented/known remote interfaces; no speculative calls into
-- unsupported source mods. Never reset an already-finished save on loading.
local M = {}
local supported = {
  "space_finish_script",          -- Space Age: Solar System Edge
  "kr-intergalactic-transceiver", -- K2SO: activated transceiver
  "silo_script"                   -- Legacy rocket/satellite victory, if present
}
M.supported=supported
local failed_once={}
function M.enforce()
  if not (remote and remote.interfaces and remote.call) then return 0 end
  local changed=0
  for _,interface in ipairs(supported) do
    local api=remote.interfaces[interface]
    if api and api.set_no_victory then
      local already_disabled=false
      if api.get_no_victory then
        local ok,state=pcall(remote.call,interface,"get_no_victory")
        already_disabled=ok and state==true
      end
      if not already_disabled then
        local ok,err=pcall(remote.call,interface,"set_no_victory",true)
        if ok then
          changed=changed+1
          failed_once[interface]=nil
        elseif not failed_once[interface] then
          failed_once[interface]=true
          if type(log)=="function" then
            log("[Razi Protocol/victory] Cannot suppress "..interface..
              ": "..tostring(err))
          end
        end
      end
    end
  end
  return changed
end
return M
