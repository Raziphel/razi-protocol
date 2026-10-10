-- Razi route hazards: vanilla spawn curves are adjusted, modded entries are not.
local M = {}
local util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")
local presets = {
  starter={"nauvis_fulgora",0.82},
  first_crossing={"nauvis_fulgora",0.99},
  frontier_crosslink={"nauvis_fulgora",1.05},
  industrial={"vulcanus_castra",0.96,"nauvis_fulgora","metallic"},
  industrial_deep={"vulcanus_castra",1.08,"nauvis_fulgora","metallic"},
  biological={"nauvis_gleba",0.97,"nauvis_fulgora","carbonic"},
  biological_deep={"nauvis_gleba",1.10,"nauvis_fulgora","carbonic"},
  middle_crossing={"gleba_aquilo",1.08,"fulgora_aquilo"},
  middle_crosslink={"fulgora_aquilo",1.13},
  electrical={"fulgora_aquilo",1.08,nil,"metallic"},
  chemistry={"fulgora_aquilo",1.14,nil,"oxide"},
  chemistry_deep={"fulgora_aquilo",1.21,nil,"oxide"},
  cryogenic={"gleba_aquilo",1.15,"fulgora_aquilo","oxide"},
  cryogenic_deep={"gleba_aquilo",1.25,"fulgora_aquilo","oxide"},
  outer_crossing={"fulgora_aquilo",1.30},
  outer_crosslink={"gleba_aquilo",1.33,"fulgora_aquilo"},
  outer_industry={"fulgora_aquilo",1.30,nil,"metallic"},
  outer_industry_deep={"fulgora_aquilo",1.39,nil,"metallic"},
  outer_void={"gleba_aquilo",1.34,"fulgora_aquilo","carbonic"},
  outer_void_deep={"gleba_aquilo",1.42,"fulgora_aquilo","carbonic"},
  deep_edge={"aquilo_solar_system_edge",1.40,"gleba_aquilo"}
}
local vanilla = {}
for _, family in ipairs({"metallic","carbonic","oxide","promethium"}) do
  vanilla[family.."-asteroid-chunk"] = family
  for _, size in ipairs({"small","medium","big","huge"}) do
    vanilla[size.."-"..family.."-asteroid"] = family
  end
end
local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, element in pairs(value) do result[key] = copy(element) end
  return result
end
local function adjust(definitions, settings)
  for _, def in ipairs(definitions) do
    local family = vanilla[def.asteroid]
    if family then
      local boost = family == settings[4] and 1.10 or 1
      for _, point in ipairs(def.spawn_points or {}) do
        if type(point.probability) == "number" then
          point.probability = math.max(0, point.probability * settings[2] * boost)
        end
      end
    end
  end
end
local done = setmetatable({}, {__mode="k"})
function M.is_vanilla(def)
  return type(def) == "table" and vanilla[def.asteroid] ~= nil
end
function M.create(profile)
  local p = presets[profile] or presets.starter
  local source = util[p[1]] or (p[3] and util[p[3]]) or util.nauvis_fulgora
  if not source then return {} end
  local defs = copy(util.spawn_definitions(source) or {})
  adjust(defs, p)
  return defs
end
function M.apply(route, profile)
  if done[route] then return end
  local defs = route.asteroid_spawn_definitions
  if type(defs) ~= "table" or #defs == 0 then
    route.asteroid_spawn_definitions = M.create(profile)
  else
    adjust(defs, presets[profile] or presets.starter)
  end
  done[route] = true
end
function M.preserve_custom(target, duplicate)
  local incoming = duplicate.asteroid_spawn_definitions or {}
  if #incoming == 0 then return end
  target.asteroid_spawn_definitions = target.asteroid_spawn_definitions or {}
  local existing = target.asteroid_spawn_definitions
  local seen = {}
  for _, def in ipairs(existing) do
    seen[(def.type or "entity").."|"..(def.asteroid or "")] = true
  end
  for _, def in ipairs(incoming) do
    local key = (def.type or "entity").."|"..(def.asteroid or "")
    if not M.is_vanilla(def) and not seen[key] then
      existing[#existing + 1] = copy(def)
      seen[key] = true
    end
  end
end
return M
