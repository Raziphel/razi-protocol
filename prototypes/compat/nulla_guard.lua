-- Guard Nulla 1.0.2's radio-interference helpers in DATA UPDATES, before
-- its final-fixes script dereferences a missing K2SO electric furnace
-- (lib.lua:67) and before add_radio_interference replaces the whole
-- emissions_per_second of an entity (lib.lua:47-55), which drops the other
-- pollutants it had (Tellus' pollen of its roboports and beacons).
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
  local add=lib.add_radio_interference
  if type(add)=="function" then
    lib.add_radio_interference=function(prototype,amount)
      if type(prototype)~="table" then return end
      local emissions=prototype.emissions_per_second
      if type(emissions)=="table" and next(emissions)~=nil
        and emissions.radio_interference==nil then
        emissions.radio_interference=amount
        if type(log)=="function" then
          log("[Razi Protocol/Nulla] Kept the other emissions of "..
            tostring(prototype.name))
        end
        return
      end
      return add(prototype,amount)
    end
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
  local ok,source=pcall(require,"__nulla__/lib")
  if ok then installed=protect(source) or installed end
  if type(log)=="function" then
    log("[Razi Protocol/Nulla] Nil-prototype shim "..
      (installed and "ready" or "unavailable: upstream fix required"))
  end
  return installed
end
return M
