-- Preserve Athos's native research except for demonstrable source-owned
-- prerequisite cycles. Never break unrelated K2SO or Razi prerequisites.
local M={}
local function owned(name)
  local n=type(name)=="string" and name:lower() or ""
  return n:find("athos",1,true)~=nil
    or n:find("particulate",1,true)~=nil
end
M.owned=owned
local Graph=require("__razi_lib__/lib/technology_graph")
local find_cycle=Graph.find_cycle
M.find_cycle=find_cycle

-- PlanetAthos 1.1.3 enumerates all descendants recursively in
-- data-updates.lua. The full 2.1.83 pack contains two PRE-EXISTING
-- cross-mod loops. These exact edges contradict the intended reachability
-- of their destination worlds; verify every witness is in the actual
-- reported cycle before modifying anything.
local bootstrap_repairs={
  {
    child="space-platform-thruster",parent="space-science-pack",
    witnesses={"planet-discovery-muluna","muluna-alice-propellant",
      "thruster-fuel","thruster-oxidizer"},
    why="Muluna must be reachable by thruster before Muluna-gated Space Science"
  },
  {
    child="nyxaris-discovery",parent="lithium-processing",
    witnesses={"planet-discovery-aquilo","vibrant-discovery"},
    why="Nyxaris must be reachable before the later Aquilo lithium industry"
  }
}
M.bootstrap_repairs=bootstrap_repairs
local function known_bootstrap_edge(techs,in_cycle)
  for _,rule in ipairs(bootstrap_repairs) do
    local member=in_cycle[rule.child] and in_cycle[rule.parent]
    if member then
      for _,witness in ipairs(rule.witnesses) do
        if not in_cycle[witness] then member=false break end
      end
    end
    if member then
      for i,parent in ipairs(techs[rule.child].prerequisites or {}) do
        if parent==rule.parent then
          return {rule.child,parent},i,rule.why
        end
      end
    end
  end
end
function M.repair(stage)
  if not (mods and mods["PlanetAthos"]) then return 0 end
  stage=stage or "late"
  ---@type table
  local techs=(data.raw or {}).technology or {}
  local fixed=0
  local examined=0
  local blocked
  for _=1,64 do
    local cycle=find_cycle(techs)
    if cycle then examined=examined+1 end
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
    -- If no Athos source edge exists, permit only the two specific
    -- logged interplanetary bootstrap deadlocks. Never delete an
    -- arbitrary K2SO, Muluna, or unrelated author's tech requirement.
    local reason
    if not chosen then
      chosen,index,reason=known_bootstrap_edge(techs,in_cycle)
    end
    if not chosen then
      blocked=table.concat(cycle," -> ")
      if type(log)=="function" then
        log("[Razi Protocol/Athos]["..stage..
          "] Unrelated cycle left unchanged: "..blocked)
      end
      break
    end
    table.remove(techs[chosen[1]].prerequisites,index)
    fixed=fixed+1
    if type(log)=="function" then
      log("[Razi Protocol/Athos]["..stage..
        "] Pruned verified cyclic prerequisite "..
        chosen[1].." -> "..chosen[2]..
        (reason and " ("..reason..")" or " (Athos-owned)"))
    end
  end
  if type(log)=="function" then
    log("[Razi Protocol/Athos]["..stage.."] Research cycles inspected="..
      examined.." repaired="..fixed..
      (blocked and " unresolved="..blocked or " remaining=none"))
  end
  return fixed
end
return M
