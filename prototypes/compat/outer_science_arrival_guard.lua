-- Some planets' native hard-mode science rewrites assume their original
-- positions in Space Age. Razi places Crucible and Vesta much farther out.
-- Prevent their exclusive sciences from being required by their own landing
-- discovery or by the prerequisite chain leading to that discovery.
local guard = {}

local families = {
  {
    mod = "planet-crucible",
    arrival = "planet-discovery-crucible",
    earlier = {"planet-discovery-aquilo", "planet-discovery-rubia",
      "beetlejuice-discovery", "umbra-discovery"},
    science = {"planet-crucible-science-pack", "kr-high-pressure-tech-card"}
  },
  {
    mod = "skewer_planet_vesta",
    arrival = "planet-discovery-vesta",
    earlier = {"planet-discovery-aquilo", "planet-discovery-rubia",
      "beetlejuice-discovery", "umbra-discovery"},
    science = {"gas-manipulation-science-pack"}
  }
}

local function tech(name)
  return data.raw.technology and data.raw.technology[name]
end

local function collect_prearrival(name, result, seen)
  if seen[name] or not tech(name) then return end
  seen[name] = true
  result[name] = true
  for _, prerequisite in ipairs(tech(name).prerequisites or {}) do
    collect_prearrival(prerequisite, result, seen)
  end
end

local function usable_fallback()
  for _, science in ipairs({"calidus-tech-card", "space-science-pack"}) do
    if data.raw.tool and data.raw.tool[science] then
      for _, lab in pairs(data.raw.lab or {}) do
        for _, input in ipairs(lab.inputs or {}) do
          if input == science then return science end
        end
      end
    end
  end
end

local function without_late_science(technology, exclusive, fallback)
  local ingredients = technology.unit and technology.unit.ingredients
  if not ingredients then return end
  local kept, removed = {}, false
  for _, ingredient in ipairs(ingredients) do
    local name = ingredient.name or ingredient[1]
    if exclusive[name] then
      removed = true
    else
      kept[#kept + 1] = ingredient
    end
  end
  if not removed then return end
  -- Do not create an invalid technology with an empty research list.
  if #kept == 0 then
    if not fallback then return end
    kept[1] = {fallback, 1}
  end
  technology.unit.ingredients = kept
end

function guard.data_final_fixes()
  if not (mods and mods["Krastorio2-spaced-out"]) then return end
  local fallback = usable_fallback()
  for _, family in ipairs(families) do
    if mods[family.mod] and tech(family.arrival) then
      local exclusive = {}
      for _, science in ipairs(family.science) do
        if (data.raw.tool and data.raw.tool[science])
          or (data.raw.item and data.raw.item[science]) then
          exclusive[science] = true
        end
      end
      if next(exclusive) then
        local ancestors = {}
        local seen = {}
        collect_prearrival(family.arrival, ancestors, seen)
        -- Early parallel destinations can be discovered without being a
        -- formal prerequisite ancestor of this specific planet.
        for _, early in ipairs(family.earlier or {}) do
          collect_prearrival(early, ancestors, seen)
        end
        for name in pairs(ancestors) do
          without_late_science(tech(name), exclusive, fallback)
        end
      end
    end
  end
end

return guard
