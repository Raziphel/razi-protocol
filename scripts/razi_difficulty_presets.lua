-- Razi Protocol gameplay difficulty presets, shared by prototype and control
-- stages. Reading a preset never mutates native or third-party mod settings.
-- Cosmetic, client, performance and safety settings are always independent.
local M={}
M.presets={
  relaxed={
    ["razi-asteroid-difficulty-scale"]="balanced",
    ["razi-asteroid-population"]="sparse",
    ["razi-belt-threats"]="relaxed",
    ["razi-belt-resource-richness"]="rich",
    ["razi-helios-progression"]="late",
    ["razi-helios-route-danger"]="challenging",
    ["razi-helios-route-distance"]="extended",
    ["razi-helios-commissioning"]="expedition",
    ["razi-helios-coronal-surges"]="off"
  },
  standard={
    ["razi-asteroid-difficulty-scale"]="balanced",
    ["razi-asteroid-population"]="standard",
    ["razi-belt-threats"]="standard",
    ["razi-belt-resource-richness"]="standard",
    ["razi-helios-progression"]="late",
    ["razi-helios-route-danger"]="extreme",
    ["razi-helios-route-distance"]="extended",
    ["razi-helios-commissioning"]="expedition",
    ["razi-helios-coronal-surges"]="occasional"
  },
  hard={
    ["razi-asteroid-difficulty-scale"]="challenging",
    ["razi-asteroid-population"]="dense",
    ["razi-belt-threats"]="severe",
    ["razi-belt-resource-richness"]="scarce",
    ["razi-helios-progression"]="late",
    ["razi-helios-route-danger"]="extreme",
    ["razi-helios-route-distance"]="marathon",
    ["razi-helios-commissioning"]="monumental",
    ["razi-helios-coronal-surges"]="volatile"
  },
  extreme={
    ["razi-asteroid-difficulty-scale"]="relentless",
    -- Deliberately avoid 'swarm': high UPS cost on multiplayer servers.
    ["razi-asteroid-population"]="dense",
    ["razi-belt-threats"]="severe",
    ["razi-belt-resource-richness"]="scarce",
    ["razi-helios-progression"]="epic",
    ["razi-helios-route-danger"]="extreme",
    ["razi-helios-route-distance"]="marathon",
    ["razi-helios-commissioning"]="monumental",
    ["razi-helios-coronal-surges"]="volatile"
  }
}
M.managed={
  "razi-asteroid-difficulty-scale",
  "razi-asteroid-population",
  "razi-belt-threats",
  "razi-belt-resource-richness",
  "razi-helios-progression",
  "razi-helios-route-danger",
  "razi-helios-route-distance",
  "razi-helios-commissioning",
  "razi-helios-coronal-surges"
}
function M.active()
  local startup=settings and settings.startup
  local selected=startup and startup["razi-difficulty-preset"]
  local name=selected and selected.value or "custom"
  return M.presets[name] and name or "custom"
end
function M.effective(name,fallback)
  -- Only nine audited gameplay levers are mapped. Unmanaged toggles
  -- continue respecting the player's existing settings in every mode.
  local values=M.presets[M.active()]
  if values then
    local choice=values[name]
    if choice~=nil then return choice end
  end
  local startup=settings and settings.startup
  local saved=startup and startup[name]
  if saved then return saved.value end
  return fallback
end
return M
