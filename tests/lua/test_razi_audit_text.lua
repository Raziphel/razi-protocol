---@diagnostic disable: param-type-mismatch, need-check-nil
-- The audit commands print localisable tables whose keys are defined in the locale.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local keys={}
local section
for line in assert(io.open("locale/en/razi_audit.cfg","r")):lines() do
  local head=line:match("^%[([^%]]+)%]%s*$")
  if head then section=head
  elseif section and line:match("^[^#;%s][^=]*=") then
    keys[section.."."..line:match("^([^=]+)=")]=true
  end
end

local printed
local function printer()
  return {print=function(message) printed[#printed+1]=message end}
end
-- Every printed message is a table of a razi-audit key; nested tables are checked too.
local function check_localised(value,where)
  check(type(value)=="table","Plain text printed by "..where)
  local key=value[1]
  check(type(key)=="string" and key:match("^razi%-audit%.") and keys[key],
    where..": key missing in razi_audit.cfg: "..tostring(key))
  for index=2,#value do
    if type(value[index])=="table" then check_localised(value[index],where) end
  end
end
local function check_all(where)
  check(#printed>0,where.." printed nothing")
  for _,message in ipairs(printed) do check_localised(message,where) end
end

local defs=require("prototypes.technology.convergence")
local audit=require("scripts.razi_convergence_audit")
local guard=require("scripts.razi_victory_guard")
local registry={item={},recipe={},entity={}}
rawset(_G,"prototypes",registry)
rawset(_G,"storage",{})
rawset(_G,"remote",{interfaces={},call=function() end})

-- /razi-audit: a force with no cargo prototypes and no research reports blockers and notes.
local force={name="Audited",index=9,technologies={},recipes={}}
local admin=setmetatable({admin=true,force=force},{__index=printer()})
local guest=setmetatable({admin=false,force=force},{__index=printer()})
local players={[1]=admin,[2]=guest}
rawset(_G,"game",{forces={player=force},get_player=function(index) return players[index] end,
  print=function(message) printed[#printed+1]=message end})

printed={}
audit.command{player_index=1}
check_all("/razi-audit")
local blockers=0
for _,message in ipairs(printed) do
  if message[1]=="razi-audit.blocker" then blockers=blockers+1 end
end
check(blockers>=#defs.shipments,"Missing cargo should be listed as blockers")
printed={}
audit.command{player_index=2}
check(#printed==1 and printed[1][1]=="razi-audit.admin-only","Non-admins get one localised refusal")
printed={}
audit.command{}
check_all("/razi-audit from the console")

-- /razi-victory-audit
printed={}
guard.command{player_index=1}
check_all("/razi-victory-audit")
printed={}
guard.command{player_index=2}
check(#printed==1 and printed[1][1]=="razi-audit.admin-only","Non-admins get one localised refusal")
-- A state with an error text uses its own key.
rawset(_G,"remote",{interfaces={["kr-intergalactic-transceiver"]={set_is_victory=true,get_is_victory=true}},
  call=function() error("boom") end})
printed={}
guard.command{}
check_all("/razi-victory-audit with a failing interface")
local errored=false
for _,message in ipairs(printed) do
  if message[1]=="razi-audit.victory-error" then errored=true end
end
check(errored,"A failing getter is printed with the error key")
for _,state in ipairs({"absent","unsupported","unverified","error","disabled","enabled","unmanaged"}) do
  check(keys["razi-audit.state-"..state],"Missing state key "..state)
end
print("Audit commands: localised output, admin refusal and locale keys passed")
