-- Preserve native progression while placing two specialized mod technologies
-- in the appropriate Razi research chapter. No new recipes, new sciences,
-- or technology costs. All links are guarded against prerequisite cycles.
local M={}
local function tech(name) return (data.raw.technology or {})[name] end
local function ancestor(start,wanted,seen)
  if start==wanted then return true end
  local t=tech(start)
  if not t then return false end
  seen=seen or {}
  if seen[start] then return false end
  seen[start]=true
  for _,parent in ipairs(t.prerequisites or {}) do
    if ancestor(parent,wanted,seen) then return true end
  end
  return false
end
local function safe_link(name,prereq)
  local node,required=tech(name),tech(prereq)
  if not (node and required) or node.enabled==false or node.hidden
    or ancestor(prereq,name) then return false end
  if not ancestor(name,prereq) then
    node.prerequisites=node.prerequisites or {}
    node.prerequisites[#node.prerequisites+1]=prereq
  end
  return true
end

-- upgraded-rocket-turrets 2.1.1 names its content upgraded-rocket-mk<n>
-- (items, recipes) and upgraded-rocket-<n> (technologies): the word "turret"
-- appears nowhere, so the generic match below never saw it.
local function source_tier(value)
  local tier=tonumber(value:match("^upgraded%-rocket%-mk(%d)$")
    or value:match("^upgraded%-rocket%-(%d)$"))
  if tier and tier>=1 and tier<=4 then return tier end
  return nil
end

-- Identify only rocket-turret MK upgrades unlocked by the actual installed
-- source's effects. Do not assume a guessed technology identifier.
local function turret_mk(name,node)
  if node.hidden or node.enabled==false then return nil end
  local pieces={name}
  for _,effect in ipairs(node.effects or {}) do
    if effect.type=="unlock-recipe" and effect.recipe then
      pieces[#pieces+1]=effect.recipe
    end
  end
  for _,value in ipairs(pieces) do
    local exact=source_tier(value)
    if exact then return exact end
  end
  for _,value in ipairs(pieces) do
    local normalized=value:lower():gsub("[^%a%d]","")
    if normalized:find("rocket",1,true)
      and normalized:find("turret",1,true) then
      for tier=1,4 do
        if normalized:find("mk"..tier,1,true)
          or normalized:find("mark"..tier,1,true) then
          return tier
        end
      end
    end
  end
  return nil
end

function M.data_final_fixes()
  -- Source tech uses platform and space science already; anchoring to the
  -- research milestone does not require visiting a second star to trade.
  if mods and mods["planet-express"] then
    safe_link("interplanetary-trade-logistics","space-science-pack")
  end
  if not (mods and mods["upgraded-rocket-turrets"]) then return end
  local stage={
    "planet-discovery-vulcanus",
    "planet-discovery-fulgora",
    "planet-discovery-aquilo",
    "planet-discovery-aquilo"
  }
  local keys={}
  for name in pairs(data.raw.technology or {}) do keys[#keys+1]=name end
  table.sort(keys)
  for _,name in ipairs(keys) do
    local node=tech(name)
    local tier=turret_mk(name,node)
    if tier then safe_link(name,stage[tier]) end
  end
end

-- Exposed for pure Lua fixture tests; never called from control stage.
M.safe_link=safe_link
M.turret_mk=turret_mk
return M
