-- Razi Convergence is the ONLY intended campaign victory.
-- Keep official source controls enabled for the lifetime of the save, but
-- never alter a mod's actual machines, routes, research or boss mechanics.
-- Factorio does not provide a universal API that intercepts an arbitrary
-- mod's game.set_game_state call. Unsupported winners are diagnosed, not
-- monkey-patched or guessed at.
local M={}
local supported={
  "space_finish_script",          -- Native Space Age outer-system victory
  "kr-intergalactic-transceiver", -- Krastorio 2 charged transceiver
  "silo_script"                   -- Older rocket / satellite victories
}
M.supported=supported

local failed_once={}
local function log_once(key,message)
  if failed_once[key] then return end
  failed_once[key]=true
  if type(log)=="function" then
    log("[Razi Protocol/victory] "..message)
  end
end
local function available(interface)
  return remote and remote.interfaces and remote.call
    and remote.interfaces[interface]
end
local function methods(interface)
  if interface=="kr-intergalactic-transceiver" then
    return "set_is_victory","get_is_victory",false
  end
  return "set_no_victory","get_no_victory",true
end
local function check(interface)
  local api=available(interface)
  if not api then return {interface=interface,state="absent"} end
  local setter,getter,desired=methods(interface)
  if not api[setter] then
    return {interface=interface,state="unsupported"}
  end
  if not api[getter] then
    return {interface=interface,state="unverified"}
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  local ok,value=pcall(remote.call,interface,getter)
  if not ok then
    return {interface=interface,state="error",error=tostring(value)}
  end
  return {interface=interface,state=value==desired
    and "disabled" or "enabled"}
end

-- Read-only list for /razi-victory-audit and tests. No hidden setters.
-- Any EXTRA opt-out interface is a compatibility candidate, not blanket
-- permission to change a source mod whose API may have other semantics.
function M.inspect()
  local results={}
  local known={}
  for _,interface in ipairs(supported) do
    known[interface]=true
    results[#results+1]=check(interface)
  end
  local extra={}
  for name,api in pairs(remote and remote.interfaces or {}) do
    if not known[name] and type(name)=="string" and
      api and api.set_no_victory then
      extra[#extra+1]=name
    end
  end
  table.sort(extra)
  for _,name in ipairs(extra) do
    results[#results+1]={interface=name,state="unmanaged"}
  end
  return results
end

-- Idempotent for source mods with a getter, best effort for older
-- Space Age builds lacking one. Keep a retry on failures.
function M.enforce()
  if not (remote and remote.interfaces and remote.call) then return 0 end
  local changed=0
  for _,interface in ipairs(supported) do
    local api=available(interface)
    local setter,getter,desired=methods(interface)
    if api and api[setter] then
      local already_disabled=false
      if api[getter] then
        ---@diagnostic disable-next-line: param-type-mismatch
        local ok,value=pcall(remote.call,interface,getter)
        already_disabled=ok and value==desired
        if not ok then
          log_once(interface..":getter",
            "Cannot read "..interface.." victory state: "..tostring(value))
        end
      end
      if not already_disabled then
        ---@diagnostic disable-next-line: param-type-mismatch
        local ok,err=pcall(remote.call,interface,setter,desired)
        if ok then
          changed=changed+1
          failed_once[interface..":setter"]=nil
        else
          log_once(interface..":setter",
            "Cannot suppress "..interface..": "..tostring(err))
        end
      end
    elseif api then
      log_once(interface..":unsupported",
        "Source interface "..interface..
        " has no supported victory setter")
    elseif interface=="kr-intergalactic-transceiver" then
      log_once(interface..":absent",
        "Source interface "..interface..
        " is absent; external victory is NOT verified suppressed")
    end
  end
  return changed
end

-- The first load can contain an already-ended save. Never retroactively
-- undo those endings, including saves imported from before Razi Protocol.
-- This marker must be made on init/config change, not on the first victory
-- event. We only repair NEW unexpected victories after the guard starts.
function M.prepare()
  if not (storage and game) then return end
  storage.razi_victory_guard=storage.razi_victory_guard or {
    inherited_finished=(game.finished==true
      or game.finished_but_continuing==true),
    stray_finishes=0
  }
end
local function convergence_won()
  for _,record in pairs(storage and storage.razi_convergence or {}) do
    if record.victory then return true end
  end
  return false
end

-- Defensive recovery for unsupported mods which invoke game.set_game_state
-- directly instead of providing a remote no-victory switch. This can run
-- only when simulation resumes; it cannot reliably prevent a victory popup
-- that pauses the game. Do NOT claim it is a universal veto.
function M.recover_unexpected()
  local state=storage and storage.razi_victory_guard
  if not (state and game) then return false end
  if state.inherited_finished or convergence_won() then return false end
  if not (game.finished or game.finished_but_continuing) then return false end
  game.reset_game_state()
  state.stray_finishes=(state.stray_finishes or 0)+1
  log_once("stray-finish",
    "Recovered a non-Convergence victory. A source mod called the native game state API without a supported opt-out.")
  return true
end
function M.recoveries()
  local state=storage and storage.razi_victory_guard
  return state and state.stray_finishes or 0
end
return M
