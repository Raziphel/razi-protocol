-- The transceiver is the gateway INTO Deep Space, not victory.
-- The final challenge belongs to the post-edge campaign.
local M={}
local chain={
 {"razi-singularity-theory",900,1},
 {"razi-singularity-test-fire",1400,2},
 {"razi-stable-intergalactic-singularity",2100,3}
}
local cards={"calidus-tech-card","solaris-tech-card","nyxaris-tech-card",
 "vibrant-tech-card","vespera-tech-card","beetlejuice-tech-card",
 "umbra-tech-card"}
local function tech(name) return (data.raw.technology or {})[name] end
local function reachable(start,wanted,visited)
 if start==wanted then return true end
 local node=tech(start)
 if not node then return false end
 visited=visited or {}
 if visited[start] then return false end
 visited[start]=true
 for _,parent in ipairs(node.prerequisites or {}) do
  if reachable(parent,wanted,visited) then return true end
 end
 return false
end
local function pre_edge_science(multi)
 local packs={}
 for _,name in ipairs(cards) do
  if (data.raw.tool or {})[name] then
   packs[#packs+1]={name,(name=="beetlejuice-tech-card"
    or name=="umbra-tech-card") and multi or 1}
  end
 end
 return packs
end
function M.data_final_fixes()
 local edge=tech("stellar-discovery-solar-system-edge")
 local signal=tech("razi-intergalactic-transceiver-signal")
 local stable=tech("razi-stable-intergalactic-singularity")
 if not (edge and signal and stable
  and tech("razi-outer-frontier-mastery")) then return end
 -- The old final research used Promethium and singularity science that
 -- may come from beyond the edge. Use all SEVEN pre-edge system cards,
 -- retaining outer card multipliers and the real K2SO transceiver build.
 -- Never alter the source transceiver entity or recipe.
 for _,entry in ipairs(chain) do
  local node=tech(entry[1])
  if node then
   node.research_trigger=nil
   node.unit={count=entry[2],time=60,
    ingredients=pre_edge_science(entry[3])}
  end
 end
 local theory=tech("razi-singularity-theory")
 if theory then
  local filtered={}
  for _,parent in ipairs(theory.prerequisites or {}) do
   -- The original K2SO transceiver research is an endgame research
   -- whose unlock recipe Razi already moved to Stable Singularity.
   -- Keeping it as a prerequisite can deadlock the earlier gate.
   if parent~="kr-intergalactic-transceiver"
     and not reachable(parent,"stellar-discovery-solar-system-edge") then
    filtered[#filtered+1]=parent
   end
  end
  local owns=false
  for _,parent in ipairs(filtered) do
   if parent=="razi-outer-frontier-mastery" then owns=true end
  end
  if not owns then
   filtered[#filtered+1]="razi-outer-frontier-mastery"
  end
  theory.prerequisites=filtered
 end
 -- Check the complete, modified chain before creating the one-way edge.
 -- If another mod moves it behind the edge, preserving the old entry
 -- requirement is preferable to a technology cycle.
 if reachable("razi-intergalactic-transceiver-signal",
    "stellar-discovery-solar-system-edge") then
  if log then log("Razi: transceiver cannot gate Deep Space; source research already depends on the edge") end
  return
 end
 edge.prerequisites=edge.prerequisites or {}
 local found=false
 for _,name in ipairs(edge.prerequisites) do
  if name=="razi-intergalactic-transceiver-signal" then
   found=true break
  end
 end
 if not found then
  edge.prerequisites[#edge.prerequisites+1]=
   "razi-intergalactic-transceiver-signal"
 end
end
return M
