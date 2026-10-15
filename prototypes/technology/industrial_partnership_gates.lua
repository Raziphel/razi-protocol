-- Turn a small number of real factories into research milestones for
-- future destinations. Do not force every bonus recipe on a player.
local M={}
local mode=require("prototypes.compat.interdependence_mode")
local Graph=require("__razi_lib__/lib/technology_graph")
M.phases={
  -- One earlier cross-system workshop is enough to reach the middle stars.
  {gates={"vibrant-discovery","vespera-discovery"},count=1,
    candidates={
      "razi-first-frontier-relay-components",
      "razi-galactic-vulcanus-bioptic-casting",
      "razi-frontier-moshine-biometal-silicon",
      "razi-bio-rare-metal-casting"
    }},
  -- The outer tier asks for an applied project from each middle branch.
  -- A missing or unsafe source suppresses only its own requirement.
  {gates={"beetlejuice-discovery","umbra-discovery"},count=2,
    sources={"planet-discovery-paracelsin","planet-discovery-rubia"},
    candidates={
      "razi-middle-paracelsin-shielded-coils",
      "razi-middle-rubia-conductive-frames"
    }}
}
local function tech(name) return (data.raw.technology or {})[name] end
local function active(name)
  local node=tech(name)
  return node and node.hidden~=true and node.enabled~=false
end
local function depends_on(name,ancestor)
  return Graph.reaches(data.raw.technology or {},name,ancestor)
end
local function eligible(candidate,phase)
  local node=tech(candidate)
  if not (active(candidate) and node.unit and node.unit.ingredients
    and #node.unit.ingredients>0) then return false end
  -- The prototype must be a reachable predecessor of BOTH parallel stars,
  -- and its native producers must not have been moved behind either gate.
  for _,gate in ipairs(phase.gates) do
    if not active(gate) or depends_on(candidate,gate) then return false end
  end
  for _,source in ipairs(phase.sources or {}) do
    if not depends_on(candidate,source) then return false end
  end
  -- Never attach hidden/disabled/missing upstream research to a gate.
  for _,parent in ipairs(node.prerequisites or {}) do
    if not active(parent) then return false end
  end
  return true
end
function M.data_final_fixes()
  if not mode.enabled() then return end
  for _,phase in ipairs(M.phases) do
    local count=0
    for _,candidate in ipairs(phase.candidates) do
      if count>=phase.count then break end
      if eligible(candidate,phase) then
        local safe=true
        for _,gate in ipairs(phase.gates) do
          if depends_on(candidate,gate) then safe=false break end
        end
        if safe then
          for _,gate in ipairs(phase.gates) do
            Graph.add_prerequisite(data.raw.technology or {},gate,candidate)
          end
          count=count+1
        end
      end
    end
  end
end
return M
