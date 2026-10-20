-- Single, curated manufacturing portfolio for Balanced and Deep.
-- Source recipes are NEVER removed. Retired Razi alternates are simply not
-- registered; their old researched technology remains harmless in saves.
local M={}
local retained={
  ["razi-bio-rare-metal-casting"]=true,
  ["razi-electrobiological-components"]=true,
  ["razi-cryo-energy-control"]=true,
  ["razi-gleba-tenebris-biopolymer"]=true,
  ["razi-linox-rare-earth-exchange"]=true,
  ["razi-cubium-precious-metal-alloying"]=true,
  ["razi-first-frontier-relay-components"]=true,
  ["razi-modded-paracelsin-optical-coils"]=true,
  ["razi-modded-moshine-zinc-silicon"]=true,
  ["razi-network-matrix-cryo-controllers"]=true,
  ["razi-network-lattice-vesta-magnets"]=true,
  ["razi-network-bond-paracelsin-coils"]=true,
  ["razi-network-bond-linox-refining"]=true,
  ["razi-network-frame-vesta-foundations"]=true,
  ["razi-network-frame-aquilo-controllers"]=true
}
M.retained=retained
function M.keep(name) return retained[name]==true end

-- Generic, lab-compatible research is an administrative unlock, never a
-- demand for technology cards from earlier stars. Actual planet and source
-- recipe research prerequisites provide the tier gate; imported ingredients
-- provide the freight challenge.
function M.science(rule)
  local original=rule.science or {}
  local first=original[1]
  if first=="calidus-tech-card" then
    return {"automation-science-pack","logistic-science-pack"}
  end
  if first=="solaris-tech-card" or first=="nyxaris-tech-card" then
    return {"chemical-science-pack","production-science-pack"}
  end
  return {"production-science-pack","utility-science-pack"}
end
return M
