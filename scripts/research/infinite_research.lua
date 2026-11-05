-- Infinite research changes inputs after eight levels, never the original
-- technology identifier. That lets existing saves retain their research.
local M = {}
local PREFIX = "razi-system-infinite-"
local EARLY_LEVELS = 8
local cards = {
  ["calidus-tech-card"] = true, ["solaris-tech-card"] = true,
  ["nyxaris-tech-card"] = true, ["vibrant-tech-card"] = true,
  ["vespera-tech-card"] = true, ["beetlejuice-tech-card"] = true,
  ["umbra-tech-card"] = true, ["deep-space-tech-card"] = true
}
local function ready(force, continuation)
  for _, entry in ipairs(continuation.research_unit_ingredients or {}) do
    local name = entry.name or entry[1]
    if cards[name] then
      local recipe = force.recipes[name]
      if not (recipe and recipe.enabled) then return false end
    end
  end
  -- The prototype has already checked that one actual lab accepts the
  -- combined ingredients, including untouched third-party research data.
  return true
end
local function transfer_queue(force, original, continuation)
  local queue = force.research_queue
  local next_queue, changed = {}, false
  for _, research in ipairs(queue or {}) do
    local name = type(research) == "string" and research or research.name
    if name == original then
      name = continuation
      changed = true
    end
    next_queue[#next_queue + 1] = name
  end
  return changed and next_queue or nil
end
function M.sync_force(force)
  if not (force and force.technologies and force.recipes) then return end
  local research = force.technologies
  for name, continuation in pairs(research) do
    if name:sub(1, #PREFIX) == PREFIX and name:sub(-6) == "-cards" then
      local original_name = name:sub(#PREFIX + 1, -7)
      local original = research[original_name]
      if original then
        local first = tonumber(original_name:match("%-(%d+)$")) or 1
        local cutoff = first + EARLY_LEVELS
        local already_continued = continuation.level > 1
        local can_switch = already_continued or ready(force, continuation)
        if can_switch and original.level >= cutoff then
          -- Capture the queue before disabling the source technology.
          local queue = transfer_queue(force, original_name, name)
          local active = force.current_research
          local progress = active and active.name == original_name
            and force.research_progress or nil
          if original.level > cutoff then
            local extra = original.level - cutoff
            -- Writing 'level' applies the completed technology effects.
            -- Subtract from the native tier before crediting the same levels
            -- on the continuation so old saves do not double their bonuses.
            original.level = cutoff
            -- Force merges may already have continuation progress from
            -- another player force. Preserve the higher level, never sum
            -- the same bonuses twice.
            continuation.level = math.max(continuation.level, 1 + extra)
            if force.reset_technology_effects then
              force.reset_technology_effects()
            end
          end
          continuation.enabled = true
          original.enabled = false
          if queue then
            force.research_queue = queue
            if progress and force.current_research
              and force.current_research.name == name then
              force.research_progress = progress
            end
          end
        elseif not already_continued then
          -- Keep the native path open until all required cards are craftable.
          continuation.enabled = false
        else
          -- A completed transition is permanent, even if later mod changes
          -- remove a card recipe. Never grant the same native levels twice.
          original.enabled = false
          continuation.enabled = true
        end
      end
    end
  end
end
function M.sync_all()
  if not game or not game.forces then return end
  for _, force in pairs(game.forces) do M.sync_force(force) end
end
return M
