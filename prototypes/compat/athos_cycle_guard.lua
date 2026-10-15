-- Preserve Athos's native research except for demonstrable source-owned
-- prerequisite cycles. Never break unrelated K2SO or Razi prerequisites.
local M={}
local function owned(name)
  local n=type(name)=="string" and name:lower() or ""
  return n:find("athos",1,true)~=nil
    or n:find("particulate",1,true)~=nil
end
M.owned=owned
local function find_cycle(techs)
  local state,stack,at={},{},{}
  local keys={}
  for key in pairs(techs) do keys[#keys+1]=key end
  table.sort(keys)
  local function visit(name)
    state[name]=1
    stack[#stack+1]=name
    at[name]=#stack
    for _,parent in ipairs(techs[name].prerequisites or {}) do
      if techs[parent] then
        if state[parent]==1 then
          local cycle={}
          for i=at[parent],#stack do cycle[#cycle+1]=stack[i] end
          return cycle
        elseif not state[parent] then
          local cycle=visit(parent)
          if cycle then return cycle end
        end
      end
    end
    state[name]=2
    at[name]=nil
    stack[#stack]=nil
  end
  for _,name in ipairs(keys) do
    if not state[name] then
      local cycle=visit(name)
      if cycle then return cycle end
    end
  end
end
M.find_cycle=find_cycle
function M.repair()
  if not (mods and mods["PlanetAthos"]) then return 0 end
  local techs=(data.raw or {}).technology or {}
  local fixed=0
  for _=1,64 do
    local cycle=find_cycle(techs)
    if not cycle then break end
    local in_cycle={}
    for _,name in ipairs(cycle) do in_cycle[name]=true end
    local chosen,index
    for _,name in ipairs(cycle) do
      if owned(name) then
        for i,parent in ipairs(techs[name].prerequisites or {}) do
          if in_cycle[parent] then
            chosen={name,parent}
            index=i
            break
          end
        end
      end
      if chosen then break end
    end
    if not chosen then
      if type(log)=="function" then
        log("[Razi Protocol/Athos] Unrelated cycle left unchanged: "..
          table.concat(cycle," -> "))
      end
      break
    end
    table.remove(techs[chosen[1]].prerequisites,index)
    fixed=fixed+1
    if type(log)=="function" then
      log("[Razi Protocol/Athos] Pruned cyclic source prerequisite "..
        chosen[1].." -> "..chosen[2])
    end
  end
  return fixed
end
return M
