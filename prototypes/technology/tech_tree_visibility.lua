-- Which research stays visible with Factorio's essential-tech filter.
-- Only the display flags change here.
local M={}
-- These rows are purely a visual sort order for our own milestones.
-- The base game still owns research connections and technology icons.
-- Keep native discoveries on their original research branches.
M.chapter_groups={
  {key="a[first-frontier]",techs={"solaris-discovery","nyxaris-discovery"}},
  {key="b[middle-frontier]",techs={"vibrant-discovery","vespera-discovery",
    "space-discovery-asteroid-belt"}},
  {key="c[outer-frontier]",techs={"beetlejuice-discovery","umbra-discovery",
    "razi-umbra-belt-survey","razi-outer-frontier-mastery"}},
  {key="d[deep-space]",techs={"razi-singularity-theory",
    "razi-singularity-test-fire","razi-stable-intergalactic-singularity",
    "razi-intergalactic-transceiver-signal"}},
  {key="e[convergence]",techs={"razi-convergence-commission",
    "razi-convergence-synchronization","razi-convergence-ignition"}}
}
local chapters={}
for _,group in ipairs(M.chapter_groups) do
  for _,name in ipairs(group.techs) do
    chapters[#chapters+1]=name
  end
end
M.chapters=chapters
-- Show all native world-discovery research in the essential-tech filter.
-- Unlike the Razi-owned chapters, do NOT rename or reorder source nodes.
-- This keeps a massive modpack navigable without hiding native branches.
local unification=require("prototypes.technology.planetary_unification")
local tracked={}
for _,world in ipairs(unification.worlds) do tracked[world]=true end
local function native_discovery(node)
  for _,effect in ipairs(node.effects or {}) do
    if effect.type=="unlock-space-location"
      and tracked[effect.space_location] then return true end
  end
  return false
end
function M.data_final_fixes()
  local techs=data.raw.technology or {}
  for _,group in ipairs(M.chapter_groups) do
    for index,name in ipairs(group.techs) do
      local t=techs[name]
      if t and not t.hidden and t.enabled~=false then
        t.essential=true
        -- Only Razi-owned milestones; no changes to native prerequisites.
        t.order=string.format("f[razi-campaign]-%s-%02d",group.key,index)
      end
    end
  end
  for _,node in pairs(techs) do
    if not node.hidden and node.enabled~=false
      and native_discovery(node) then
      node.essential=true
    end
  end
end
return M
