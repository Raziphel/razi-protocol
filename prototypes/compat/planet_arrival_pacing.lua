-- Final optional-world research pacing. Never create or overwrite native planets or recipes.
local M = {}
local function tech(name)
  return (data.raw.technology or {})[name]
end
local function reaches(start, target, seen)
  if start == target then return true end
  seen = seen or {}
  if seen[start] then return false end
  seen[start] = true
  for _, parent in ipairs((tech(start) or {}).prerequisites or {}) do
    if reaches(parent, target, seen) then return true end
  end
  return false
end
local function gate(name, parent)
  local t = tech(name)
  if not (t and tech(parent)) or name == parent
    or reaches(parent, name) then return false end
  t.prerequisites = t.prerequisites or {}
  for _, candidate in ipairs(t.prerequisites) do
    if candidate == parent or reaches(candidate, parent) then return true end
  end
  t.prerequisites[#t.prerequisites + 1] = parent
  return true
end
local function remove_parent(name, parent)
  local t = tech(name)
  if not t then return end
  local result = {}
  for _, value in ipairs(t.prerequisites or {}) do
    if value ~= parent then result[#result+1] = value end
  end
  t.prerequisites = result
end
local function discovering(world)
  local result = {}
  for name, t in pairs(data.raw.technology or {}) do
    for _, effect in ipairs(t.effects or {}) do
      if effect.type == "unlock-space-location" and effect.space_location == world then
        result[#result+1] = name
        break
      end
    end
  end
  table.sort(result)
  return result
end
local function adjust_balack_science(name)
  local t = tech(name)
  if not t or not (t.unit and t.unit.ingredients) then return false end
  if not ((data.raw.tool or {})["cryogenic-science-pack"]
    or (data.raw.item or {})["cryogenic-science-pack"]) then return false end
  local found, result, seen = false, {}, {}
  for _, item in ipairs(t.unit.ingredients) do
    local id = item.name or item[1]
    local amount = item.amount or item[2] or 1
    if id == "promethium-science-pack" then
      id = "cryogenic-science-pack"
      found = true
    end
    if not seen[id] then
      local ingredient = {id, amount}
      result[#result+1] = ingredient
      seen[id] = ingredient
    elseif id == "cryogenic-science-pack" then
      seen[id][2] = math.max(seen[id][2], amount)
    end
  end
  if found then t.unit.ingredients = result end
  return found
end
function M.data_final_fixes()
  if not (mods and mods["Krastorio2-spaced-out"]) then return end
  -- Post-Aquilo Balack should not require post-finale Promethium.
  if (data.raw.planet or {})["bm-balack"] then
    for _, name in ipairs(discovering("bm-balack")) do
      adjust_balack_science(name)
      remove_parent(name, "promethium-science-pack")
      gate(name, "planet-discovery-aquilo")
    end
  end
  -- Aegis needs BOTH first-frontier sectors; deep Bellicos stays tier three.
  if mods["bellicos-and-aegis"] then
    remove_parent("discovery-aegis-outer", "stellar-discovery-solar-system-edge")
    remove_parent("discovery-aegis-outer", "vespera-discovery")
    gate("discovery-aegis-outer", "solaris-discovery")
    gate("discovery-aegis-outer", "nyxaris-discovery")
    -- The old Calidus-side stargate prototype is now the twin-frontier
    -- entry. Grant its native location in the source Aegis survey, without
    -- inventing an unlock technology or bypassing Bellicos interior research.
    local survey=tech("discovery-aegis-outer")
    if survey and (data.raw["space-location"] or {})["calidus-bellicos-stargate-calidus"] then
      local found=false
      survey.effects=survey.effects or {}
      for _,effect in ipairs(survey.effects) do
        if effect.type=="unlock-space-location"
          and effect.space_location=="calidus-bellicos-stargate-calidus" then
          found=true
          break
        end
      end
      if not found then
        survey.effects[#survey.effects+1]={type="unlock-space-location",
          space_location="calidus-bellicos-stargate-calidus",
          use_icon_overlay_constant=true}
      end
    end
    for _, name in ipairs({"discovery-aegis-inner", "discovery-bellicos"}) do
      if tech(name) then gate(name, "beetlejuice-discovery") end
    end
    for _, world in ipairs({"aegis-inner-edge", "point-warden"}) do
      for _, name in ipairs(discovering(world)) do
        if name ~= "discovery-aegis-outer" then gate(name, "beetlejuice-discovery") end
      end
    end
  end
  -- Shchierbin sits on the exterior side of Vibrant's hazardous belt.
  if (data.raw.planet or {}).shchierbin then
    for _, name in ipairs(discovering("shchierbin")) do
      gate(name, "planet-discovery-paracelsin")
    end
  end
end
return M
