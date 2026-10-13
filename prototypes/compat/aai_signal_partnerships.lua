-- Connect existing AAI cross-planet circuits to Razi's advanced
-- factory research. AAI continues to own all transmitters, channels and
-- circuit behavior; Razi never copies its code or changes its prototypes.
local M={}
local mode=require("prototypes.compat.interdependence_mode")

-- Use the native source technology if present. AAI forks historically
-- rename the research; candidates are deliberately narrow.
M.candidates={
  "aai-signal-transmission",
  "signal-transmission",
  "aai-signal-transmission-technology"
}
local function active(node)
  return node and node.enabled~=false and node.hidden~=true
end
function M.source_technology(technology)
  if not technology then return nil end
  for _,name in ipairs(M.candidates) do
    if active(technology[name]) then return name end
  end
  -- One cheap fallback scan at data-stage/control GUI open for variants.
  -- Do not accidentally select unrelated radio, air-purifier or combat
  -- signals. Only technology that unlocks a signal transmitter counts.
  local matches={}
  for name,node in pairs(technology) do
    if type(name)=="string" and name:find("signal-transmission",1,true)
      and active(node) then
      for _,effect in pairs(node.effects or {}) do
        local recipe=effect.type=="unlock-recipe" and effect.recipe
        if type(recipe)=="string"
          and recipe:find("signal-transmitter",1,true) then
          matches[#matches+1]=name
          break
        end
      end
    end
  end
  table.sort(matches)
  return matches[1]
end
local function reaches(technologies,start,target,visited)
  if start==target then return true end
  local t=technologies[start]
  if not t then return false end
  visited=visited or {}
  if visited[start] then return false end
  visited[start]=true
  for _,parent in ipairs(t.prerequisites or {}) do
    if reaches(technologies,parent,target,visited) then return true end
  end
  return false
end
M.targets={
  "razi-network-precision-matrix",
  "razi-network-panglia-optic-bond"
}
function M.data_final_fixes()
  if not mode.enabled() or not (mods and mods["aai-signal-transmission"]) then
    return
  end
  local technologies=data and data.raw and data.raw.technology or {}
  local source=M.source_technology(technologies)
  local native=source and technologies[source]
  -- Require the real research, not a fabricated substitute for it.
  if not (native and native.unit and native.unit.ingredients
    and #native.unit.ingredients>0) then return end
  -- The communication network is an early logistics technology.
  -- If a different mod puts it beyond the outer chapters, don't pull it
  -- backwards as a requirement for the earlier precision network.
  for _,future in ipairs({
    "beetlejuice-discovery","umbra-discovery","razi-outer-frontier-mastery"
  }) do
    if reaches(technologies,source,future) then return end
  end
  for _,name in ipairs(M.targets) do
    local target=technologies[name]
    if active(target) and not reaches(technologies,source,name)
      and not reaches(technologies,name,source) then
      -- This is Razi-owned optional advanced research, never native AAI
      -- research, planet discovery, launch, the existing freight fleet,
      -- or a first-arrival science pack.
      target.prerequisites=target.prerequisites or {}
      target.prerequisites[#target.prerequisites+1]=source
    end
  end
end
return M
