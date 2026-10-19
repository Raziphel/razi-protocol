-- Aquilo's vanilla endgame research arrives too early in a seven-system
-- campaign. Keep Aquilo science, survival infrastructure and native recipes.
-- Spread ONLY its three high-impact optional research rewards further out.
-- No item bans, off-world surface scripts, new laboratories or force resets.
local M = {}

local rules = {
  {tech = "foundation", parents = {
    "planet-discovery-paracelsin", "planet-discovery-maraxsis"
  }},
  {tech = "fusion-reactor", parents = {
    "planet-discovery-cubium", "planet-discovery-tenebris"
  }},
  {tech = "legendary-quality", parents = {
    "razi-outer-frontier-mastery"
  }}
}
M.rules = rules

local function active(node)
  return node and node.enabled ~= false and node.hidden ~= true
end

-- A candidate parent that already depends on the target would create a
-- research cycle. Use the final loaded technology graph, not assumed order.
local function reaches(techs, source, target, visited)
  if source == target then return true end
  local node = techs[source]
  if not node then return false end
  visited = visited or {}
  if visited[source] then return false end
  visited[source] = true
  for _, parent in ipairs(node.prerequisites or {}) do
    if reaches(techs, parent, target, visited) then return true end
  end
  return false
end

function M.apply(raw, rule)
  local techs = raw.technology or {}
  local target = techs[rule.tech]
  if not active(target) then return false, "absent-or-disabled-target" end

  -- Validate the WHOLE rule first. Never attach only one of the two
  -- complementary planetary milestones or strand a research prerequisite.
  for _, parent in ipairs(rule.parents) do
    if not active(techs[parent]) then
      return false, "absent-or-disabled-parent:" .. parent
    end
    if reaches(techs, parent, rule.tech) then
      return false, "research-cycle:" .. parent
    end
  end

  target.prerequisites = target.prerequisites or {}
  local present = {}
  for _, parent in ipairs(target.prerequisites) do present[parent] = true end
  for _, parent in ipairs(rule.parents) do
    if not present[parent] and not reaches(techs, rule.tech, parent) then
      target.prerequisites[#target.prerequisites + 1] = parent
      present[parent] = true
    end
  end
  -- Deliberately preserve existing tech effects, science ingredients,
  -- cost, quality tiers, source recipes and placement restrictions.
  return true, "staged"
end

function M.data_final_fixes()
  local option = settings and settings.startup
    and settings.startup["razi-stage-aquilo-breakthroughs"]
  if option and option.value == false then return end
  local raw = data and data.raw
  if not raw then return end
  for _, rule in ipairs(rules) do
    local _, reason = M.apply(raw, rule)
    if type(log) == "function" then
      log("[Razi Protocol/Aquilo progression] " .. rule.tech .. ": " .. reason)
    end
  end
end

return M
