-- High-signal research tree view for a large Factorio 2.1 modpack.
-- "Show only essential technologies" now keeps the actual Razi chapter
-- milestones visible. Technology costs, research triggers, unlock effects
-- and the original planet-mod technology tree are NOT changed here.
local M={}
local chapters={
  "solaris-discovery","nyxaris-discovery",
  "vibrant-discovery","vespera-discovery",
  "beetlejuice-discovery","umbra-discovery",
  "razi-vespera-belt-survey","razi-umbra-belt-survey",
  "razi-outer-frontier-mastery",
  "razi-singularity-theory","razi-singularity-test-fire",
  "razi-stable-intergalactic-singularity",
  "razi-intergalactic-transceiver-signal"
}
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
  for index,name in ipairs(chapters) do
    local t=techs[name]
    if t and not t.hidden and t.enabled~=false then
      t.essential=true
      -- Only reorder Razi-owned campaign nodes, not other mods' techs.
      t.order=string.format("f[razi-campaign]-%02d",index)
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
