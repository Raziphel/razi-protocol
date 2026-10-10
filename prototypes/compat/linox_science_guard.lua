-- Linox optional hard mode imports its own science into Aquilo-era research.
-- In Razi, Linox instead sits beyond Cubium in the outer Beetlejuice system.
-- Remove only the science requirement on technologies needed to REACH Linox.
-- Preserve Linox science on research that can be completed after arrival.
local compat = {}

local late_science = "linox-item_linox-science-pack"
local protected_destinations = {
  "beetlejuice-discovery",
  "umbra-discovery",
  "linox-technology_planet-discovery-linox"
}

local function technology(name)
  return data.raw.technology and data.raw.technology[name]
end

local function collect_ancestors(name, collected, visited)
  if visited[name] or not technology(name) then return end
  visited[name] = true
  collected[name] = true
  for _, prerequisite in ipairs(technology(name).prerequisites or {}) do
    collect_ancestors(prerequisite, collected, visited)
  end
end

function compat.data_final_fixes()
  if not (mods and mods["linox"] and mods["Krastorio2-spaced-out"]) then
    return
  end
  if not (data.raw.tool and data.raw.tool[late_science]) then return end

  local required_before_arrival, visited = {}, {}
  for _, destination in ipairs(protected_destinations) do
    collect_ancestors(destination, required_before_arrival, visited)
  end

  for name in pairs(required_before_arrival) do
    local t = technology(name)
    if t and t.unit and t.unit.ingredients then
      for i = #t.unit.ingredients, 1, -1 do
        local ingredient = t.unit.ingredients[i]
        if (ingredient.name or ingredient[1]) == late_science then
          table.remove(t.unit.ingredients, i)
        end
      end
    end
  end
end

return compat
