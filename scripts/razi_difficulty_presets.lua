-- Central RP3 difficulty, preserving all manually selected values.
-- The settings GUI cannot be programmatically switched to Custom during
-- settings editing. Effective mode resolves to Custom if a supported
-- gameplay lever differs from its original Normal default.
-- No source-mod setting is mutated, and no UPS-heavy dynamic world scans.
local M={}
M.baseline={
 ["razi-asteroid-difficulty-scale"]="balanced",
 ["razi-asteroid-population"]="standard",
 ["razi-belt-threats"]="standard",
 ["razi-belt-resource-richness"]="standard",
 ["razi-helios-progression"]="late",
 ["razi-helios-route-danger"]="extreme",
 ["razi-helios-route-distance"]="extended",
 ["razi-helios-commissioning"]="expedition",
 ["razi-helios-coronal-surges"]="occasional",
 ["razi-enemy-pressure"]="normal",
 ["razi-nexus-hostility"]="normal",
 ["razi-big-monsters-events"]=false,
 ["razi-planetary-interdependence"]="balanced",
 -- Additional gameplay changes resolve the session to Custom but are not
 -- blindly overwritten by presets (structural / compatibility switches).
 ["razi-enable-enemy-routing"]=true,
 ["razi-quality-asteroids"]=true,
 ["razi-enable-k2so-production-exchanges"]=true,
 ["razi-enable-modded-planet-exchanges"]=true,
 ["razi-distributed-technology"]=true,
 ["razi-stage-aquilo-breakthroughs"]=true,
 ["razi-helios-construction"]="satellites",
 ["razi-helios-convergence-proof"]=false,
 ["razi-dyson-milestone-weave"]=true,
 ["razi-belt-midsection-salvage"]=true,
 ["razi-belt-edge-harvesting"]=true
}
M.managed={
 "razi-asteroid-difficulty-scale","razi-asteroid-population",
 "razi-belt-threats","razi-belt-resource-richness",
 "razi-helios-progression","razi-helios-route-danger",
 "razi-helios-route-distance","razi-helios-commissioning",
 "razi-helios-coronal-surges","razi-enemy-pressure",
 "razi-nexus-hostility","razi-big-monsters-events",
 "razi-planetary-interdependence"
}
M.presets={
 easy={
  ["razi-asteroid-difficulty-scale"]="balanced",
  ["razi-asteroid-population"]="sparse",
  ["razi-belt-threats"]="relaxed",["razi-belt-resource-richness"]="rich",
  ["razi-helios-progression"]="late",
  ["razi-helios-route-danger"]="challenging",
  ["razi-helios-route-distance"]="extended",
  ["razi-helios-commissioning"]="expedition",
  ["razi-helios-coronal-surges"]="off",
  ["razi-enemy-pressure"]="light",["razi-nexus-hostility"]="normal",
  ["razi-big-monsters-events"]=false,
  ["razi-planetary-interdependence"]="balanced"
 },
 normal={
  ["razi-asteroid-difficulty-scale"]="balanced",
  ["razi-asteroid-population"]="standard",
  ["razi-belt-threats"]="standard",["razi-belt-resource-richness"]="standard",
  ["razi-helios-progression"]="late",
  ["razi-helios-route-danger"]="extreme",
  ["razi-helios-route-distance"]="extended",
  ["razi-helios-commissioning"]="expedition",
  ["razi-helios-coronal-surges"]="occasional",
  ["razi-enemy-pressure"]="normal",["razi-nexus-hostility"]="normal",
  ["razi-big-monsters-events"]=false,
  ["razi-planetary-interdependence"]="balanced"
 },
 hard={
  ["razi-asteroid-difficulty-scale"]="challenging",
  ["razi-asteroid-population"]="dense",
  ["razi-belt-threats"]="severe",["razi-belt-resource-richness"]="scarce",
  ["razi-helios-progression"]="late",
  ["razi-helios-route-danger"]="extreme",
  ["razi-helios-route-distance"]="marathon",
  ["razi-helios-commissioning"]="monumental",
  ["razi-helios-coronal-surges"]="volatile",
  ["razi-enemy-pressure"]="aggressive",["razi-nexus-hostility"]="hard",
  ["razi-big-monsters-events"]=true,
  ["razi-planetary-interdependence"]="deep"
 },
 nightmare={
  ["razi-asteroid-difficulty-scale"]="relentless",
  -- Dense is the safety ceiling. Swarm is an avoidable multiplayer UPS risk.
  ["razi-asteroid-population"]="dense",
  ["razi-belt-threats"]="severe",["razi-belt-resource-richness"]="scarce",
  ["razi-helios-progression"]="epic",
  ["razi-helios-route-danger"]="extreme",
  ["razi-helios-route-distance"]="marathon",
  ["razi-helios-commissioning"]="monumental",
  ["razi-helios-coronal-surges"]="volatile",
  ["razi-enemy-pressure"]="overrun",["razi-nexus-hostility"]="apocalypse",
  ["razi-big-monsters-events"]=true,
  ["razi-planetary-interdependence"]="deep"
 }
}
local legacy={relaxed="easy",standard="normal",extreme="nightmare"}
function M.selected()
 local startup=settings and settings.startup
 local v=startup and startup["razi-difficulty-preset"]
 local name=v and v.value or "normal"
 return legacy[name] or (M.presets[name] and name or "normal")
end
function M.manual_overrides()
 local found={}
 local startup=settings and settings.startup
 -- Watch *all* material gameplay toggles, not just the controls a named
 -- mode safely overrides. Prototype-changing switches remain independent.
 for name,default in pairs(M.baseline) do
  local choice=startup and startup[name]
  if choice and choice.value~=default then
    found[#found+1]=name
  end
 end
 return found
end
function M.active()
 local choice=M.selected()
 if choice=="custom" then return choice end
 -- Compare *saved* advanced controls to Normal defaults, never against
 -- a computed Hard/Nightmare preset. Selecting a named preset with the
 -- stock controls does not falsely activate Custom.
 if #M.manual_overrides()>0 then return "custom" end
 return choice
end
function M.effective(name,fallback)
 local mode=M.active()
 local preset=M.presets[mode]
 if preset and preset[name]~=nil then return preset[name] end
 local startup=settings and settings.startup
 local item=startup and startup[name]
 if item then return item.value end
 return fallback
end
return M
