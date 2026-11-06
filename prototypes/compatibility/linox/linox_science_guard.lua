-- Linox is a late Beetlejuice destination.
-- Its hard-mode science cannot be required to discover Linox itself.
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

-- Use a pack accepted by an installed lab if the late Linox pack
-- was a technology's entire science requirement.
local function first_early_science()
  for _, pack in ipairs({"calidus-tech-card", "space-science-pack"}) do
    if (data.raw.tool and data.raw.tool[pack])
      or (data.raw.item and data.raw.item[pack]) then
      for _, lab in pairs(data.raw.lab or {}) do
        for _, input in ipairs(lab.inputs or {}) do
          if input==pack then return pack end
        end
      end
    end
  end
  return nil
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

  local fallback = first_early_science()
  for name in pairs(required_before_arrival) do
    local t = technology(name)
    if t and t.unit and t.unit.ingredients then
      local kept, removed = {}, false
      for _, ingredient in ipairs(t.unit.ingredients) do
        if (ingredient.name or ingredient[1]) == late_science then
          removed = true
        else
          kept[#kept+1] = ingredient
        end
      end
      if removed then
        if #kept == 0 and fallback then
          kept[1] = {fallback, 1}
        end
        -- Without an obtainable fallback, don't produce an invalid
        -- zero-ingredient research definition. The dump audit flags it.
        if #kept > 0 then t.unit.ingredients = kept end
      end
    end
  end
end

return compat
