-- Guard Nulla 1.0.2's radio-interference helper in DATA UPDATES, before
-- its final-fixes script dereferences a missing K2SO electric furnace.
local M={}
local wrapped=setmetatable({},{__mode="k"})
local function protect(lib)
  if type(lib)~="table" or wrapped[lib]
    or type(lib.add_radio_interference_energy)~="function" then return false end
  local original=lib.add_radio_interference_energy
  lib.add_radio_interference_energy=function(prototype,amount)
    if type(prototype)~="table" then return end
    return original(prototype,amount)
  end
  wrapped[lib]=true
  return true
end
function M.data_updates()
  if not (mods and mods["nulla"]) then return false end
  local installed=false
  -- The source uses require("lib") from its own namespace; the original
  -- module may already be cached from its data pass.
  for key,value in pairs(package.loaded or {}) do
    if type(key)=="string"
      and (key=="lib" or key:find("nulla",1,true)) then
      installed=protect(value) or installed
    end
  end
  local ok,source=pcall(require,"__nulla__.lib")
  if ok then installed=protect(source) or installed end
  if type(log)=="function" then
    log("[Razi Protocol/Nulla] Nil-prototype shim "..
      (installed and "ready" or "unavailable: upstream fix required"))
  end
  return installed
end
return M
