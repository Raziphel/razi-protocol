-- Heat Inserter can generate heat-powered variants of Linox's neodymium arms.
-- When another compatibility pass hides the base bulk-heat-inserter research,
-- those visible variants inherit an impossible prerequisite. PlanetsLib warns
-- about this, but globally unlinking hidden research would affect other mods.
local M = {}
local hidden_heat_bulk = "bulk-heat-inserter"
local native_bulk = "bulk-inserter"
local linox_neodymium = "linox-technology_neodymium-permanent-magnet-inserter"

local function available(node)
  return node and node.hidden ~= true and node.enabled ~= false
end

local function reaches(technologies, from, goal, seen)
  if from == goal then return true end
  if seen[from] then return false end
  seen[from] = true
  local tech = technologies[from]
  for _, parent in ipairs(tech and tech.prerequisites or {}) do
    if reaches(technologies, parent, goal, seen) then return true end
  end
  return false
end

local function is_neodymium_upgrade(name, technology)
  if name:find("neodymium", 1, true) then return true end
  for _, effect in ipairs(technology.effects or {}) do
    if effect.type == "unlock-recipe" and type(effect.recipe) == "string"
      and effect.recipe:find("neodymium", 1, true) then
      return true
    end
  end
  return false
end

function M.data_final_fixes()
  local technologies = data.raw.technology or {}
  local hidden = technologies[hidden_heat_bulk]
  -- Only repair an observed, unavailable prerequisite. Never alter the
  -- normal Heat Inserter tree if its bulk research can still be completed.
  if not hidden or available(hidden) then return 0 end

  local repaired = 0
  for name, technology in pairs(technologies) do
    if available(technology) and name ~= hidden_heat_bulk then
      local parents, present, had_hidden_parent = {}, {}, false
      for _, parent in ipairs(technology.prerequisites or {}) do
        if parent == hidden_heat_bulk then
          had_hidden_parent = true
        elseif not present[parent] then
          present[parent] = true
          parents[#parents + 1] = parent
        end
      end

      if had_hidden_parent then
        local function add_safe_parent(candidate)
          if candidate == name or present[candidate]
            or not available(technologies[candidate])
            or reaches(technologies, candidate, name, {}) then return end
          -- Don't add a redundant direct arrow if a retained parent already
          -- guarantees this tier of research through another visible route.
          for _, parent in ipairs(parents) do
            if reaches(technologies, parent, candidate, {}) then return end
          end
          parents[#parents + 1] = candidate
          present[candidate] = true
        end

        -- Replace the hidden heat-bulk gate with its native bulk tier.
        add_safe_parent(native_bulk)
        -- Never turn a late Linox enhancement into early Nauvis research.
        if is_neodymium_upgrade(name, technology) then
          add_safe_parent(linox_neodymium)
        end
        technology.prerequisites = parents
        repaired = repaired + 1
      end
    end
  end
  if repaired > 0 and type(log) == "function" then
    log("[Razi Protocol] Repaired " .. repaired ..
      " visible research prerequisite(s) inherited from hidden bulk-heat-inserter")
  end
  return repaired
end

return M
