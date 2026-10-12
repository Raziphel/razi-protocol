-- Protocol Codex chapter art direction. No save data, events or prototypes.
-- Runtime icons reuse source-owned installed artwork and always fall back to
-- the Razi Codex emblem when a candidate is missing in a particular modpack.
local M={}
M.themes={
  calidus={primary={r=1,g=0.75,b=0.43},soft={r=0.77,g=0.64,b=0.47},
    icons={"technology/automation","item/automation-science-pack"}},
  solaris={primary={r=1,g=0.48,b=0.23},soft={r=0.94,g=0.65,b=0.42},
    icons={"space-location/sye-solaris","space-location/vulcanus","technology/metallurgic-science-pack"}},
  nyxaris={primary={r=0.39,g=0.94,b=0.64},soft={r=0.62,g=0.81,b=0.72},
    icons={"space-location/sye-nyxaris","space-location/gleba","technology/agricultural-science-pack"}},
  vibrant={primary={r=0.43,g=0.72,b=1},soft={r=0.63,g=0.81,b=0.97},
    icons={"space-location/sye-vibrant","space-location/fulgora","technology/electromagnetic-science-pack"}},
  vespera={primary={r=0.72,g=0.64,b=1},soft={r=0.81,g=0.77,b=0.96},
    icons={"space-location/sye-vespera","space-location/aquilo","technology/cryogenic-science-pack"}},
  beetlejuice={primary={r=1,g=0.73,b=0.34},soft={r=0.96,g=0.81,b=0.55},
    icons={"space-location/sye-beetlejuice","space-location/cubium","technology/production-science-pack"}},
  umbra={primary={r=1,g=0.42,b=0.56},soft={r=0.94,g=0.7,b=0.77},
    icons={"space-location/sye-umbra","space-location/tenebris","technology/military-science-pack"}},
  stellar={primary={r=1,g=0.9,b=0.43},soft={r=0.95,g=0.86,b=0.63},
    icons={"technology/slp-dyson-sphere","technology/solar-energy","item/solar-panel"}},
  network={primary={r=0.33,g=0.91,b=0.85},soft={r=0.63,g=0.88,b=0.86},
    icons={"technology/interplanetary-trade-logistics","technology/logistic-robotics","item/logistic-robot"}},
  alliances={primary={r=1,g=0.64,b=0.35},soft={r=0.94,g=0.78,b=0.57},
    icons={"technology/razi-network-precision-matrix","technology/kr-advanced-tech-card","technology/steel-processing"}},
  finale={primary={r=0.82,g=0.8,b=1},soft={r=0.89,g=0.86,b=1},
    icons={"technology/razi-stable-intergalactic-singularity","technology/kr-singularity-tech-card","technology/space-science-pack"}},
  foundations={primary={r=0.92,g=0.73,b=0.51},soft={r=0.84,g=0.78,b=0.65},
    icons={"item/assembling-machine-1","technology/steel-processing"}},
  fleet={primary={r=0.44,g=0.77,b=1},soft={r=0.72,g=0.84,b=0.98},
    icons={"technology/space-platform","technology/rocket-silo","item/rocket-silo"}},
  outposts={primary={r=0.69,g=0.91,b=0.49},soft={r=0.78,g=0.89,b=0.66},
    icons={"technology/planet-discovery-muluna","item/radar","technology/radar"}},
  sciences={primary={r=0.79,g=0.58,b=1},soft={r=0.84,g=0.75,b=0.96},
    icons={"item/chemical-science-pack","technology/chemical-science-pack"}},
  defense={primary={r=1,g=0.5,b=0.41},soft={r=0.95,g=0.73,b=0.64},
    icons={"technology/laser-turret","item/gun-turret"}},
  deepworks={primary={r=0.49,g=0.83,b=1},soft={r=0.72,g=0.87,b=0.96},
    icons={"technology/planet-nexus-scanning","technology/kr-matter-processing","technology/nuclear-power"}},
  echoes={primary={r=1,g=0.81,b=0.61},soft={r=0.93,g=0.83,b=0.71},
    icons={"technology/razi-intergalactic-transceiver-signal","technology/radar","item/radar"}},
}
M.default=M.themes.calidus
function M.get(id)
  return M.themes[id] or M.default
end
function M.icon(id)
  for _,candidate in ipairs(M.get(id).icons) do
    if not (helpers and helpers.is_valid_sprite_path)
      or helpers.is_valid_sprite_path(candidate) then return candidate end
  end
  return "razi-journal-book-icon"
end
return M
