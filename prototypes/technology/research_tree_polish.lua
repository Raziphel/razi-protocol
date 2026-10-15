-- Make Razi's own industrial research a connected, readable late game.
-- This is intentionally after the source mods, science arrival guards and
-- premium recipe registration. Never rewrite native planet discovery techs.
local M={}
local mode=require("prototypes.compat.interdependence_mode")
local Graph=require("__razi_lib__/lib/technology_graph")
local function technology(name)
  return (data.raw.technology or {})[name]
end
local function active(name)
  local node=technology(name)
  return node and node.enabled~=false and not node.hidden
end
function M.safe_link(target,parent)
  if not (active(target) and active(parent)) or target==parent then
    return false
  end
  local techs=data.raw.technology or {}
  if Graph.reaches(techs,parent,target) then return false end
  -- A transitive prerequisite already enforces the same milestone.
  if Graph.reaches(techs,target,parent) then return true end
  return Graph.add_prerequisite(techs,target,parent)
end

-- All of these are optional AFTER-arrival industries. First discoveries,
-- launching rockets, labs and native material processing stay untouched.
M.balanced={
  {"razi-network-bond-paracelsin-coils","panglia_advanced_optics_nanotech"},
  {"razi-network-bond-linox-refining","panglia_advanced_optics_nanotech"}
}
M.deep={
  -- Deep asks both independently viable interplanetary component networks
  -- to cooperate. No new component or planetary science is fabricated.
  {"razi-network-umbra-pressure-frame","razi-network-extreme-lattice"},
  {"razi-network-lattice-vesta-magnets","razi-network-panglia-optic-bond"},
  {"razi-network-lattice-vesta-foundations","razi-network-panglia-optic-bond"},
  {"razi-network-frame-vesta-foundations","razi-network-lattice-vesta-magnets"},
  {"razi-network-frame-aquilo-controllers","razi-network-matrix-cryo-controllers"},
  {"razi-network-lattice-balack-shielding","razi-network-panglia-optic-bond"},
  -- Deep factories reward completing earlier regional component networks.
  {"razi-network-lattice-balack-shielding","razi-network-matrix-linox-refining"},
  {"razi-network-frame-vesta-foundations","razi-network-matrix-rubia-logistics"},
  {"razi-network-frame-aquilo-controllers","razi-network-bond-linox-refining"}
}

-- This explicitly reduces a handful of disproportionately priced Razi
-- upgrade choices. Existing cheaper modpack overrides remain cheaper.
-- Do not apply global count multipliers to thousands of native technologies.
M.science_budget={
  -- The four Razi components are vital industries, not cost walls.
  ["razi-network-precision-matrix"]=400,
  ["razi-network-panglia-optic-bond"]=340,
  ["razi-network-extreme-lattice"]=650,
  ["razi-network-umbra-pressure-frame"]=900,
  -- Cross-world upgrades should not dwarf the research for their worlds.
  ["razi-network-matrix-cryo-controllers"]=760,
  ["razi-network-matrix-rubia-logistics"]=780,
  ["razi-network-matrix-linox-refining"]=780,
  ["razi-network-bond-paracelsin-coils"]=480,
  ["razi-network-bond-linox-refining"]=600,
  ["razi-network-lattice-vesta-magnets"]=1000,
  ["razi-network-lattice-vesta-foundations"]=1250,
  ["razi-network-lattice-balack-shielding"]=1300,
  ["razi-network-frame-vesta-foundations"]=900,
  ["razi-network-frame-aquilo-controllers"]=1000
}
M.families={
  {"razi-network-precision-matrix","f[razi-industry]-a[precision]"},
  {"razi-network-matrix-cryo-controllers","f[razi-industry]-a[precision]-a[aquilo]"},
  {"razi-network-matrix-rubia-logistics","f[razi-industry]-a[precision]-b[rubia]"},
  {"razi-network-matrix-linox-refining","f[razi-industry]-a[precision]-c[linox]"},
  {"razi-network-panglia-optic-bond","f[razi-industry]-b[panglia]"},
  {"razi-network-bond-paracelsin-coils","f[razi-industry]-b[panglia]-a[paracelsin]"},
  {"razi-network-bond-linox-refining","f[razi-industry]-b[panglia]-b[linox]"},
  {"razi-network-extreme-lattice","f[razi-industry]-c[lattice]"},
  {"razi-network-lattice-vesta-magnets","f[razi-industry]-c[lattice]-a[magnets]"},
  {"razi-network-lattice-vesta-foundations","f[razi-industry]-c[lattice]-b[foundations]"},
  {"razi-network-lattice-balack-shielding","f[razi-industry]-c[lattice]-c[balack]"},
  {"razi-network-umbra-pressure-frame","f[razi-industry]-d[pressure]"},
  {"razi-network-frame-vesta-foundations","f[razi-industry]-d[pressure]-a[vesta]"},
  {"razi-network-frame-aquilo-controllers","f[razi-industry]-d[pressure]-b[aquilo]"}
}
local components={
  ["razi-network-precision-matrix"]=true,
  ["razi-network-panglia-optic-bond"]=true,
  ["razi-network-extreme-lattice"]=true,
  ["razi-network-umbra-pressure-frame"]=true
}
function M.data_final_fixes()
  if not mode.enabled() then return end
  for _,edge in ipairs(M.balanced) do
    M.safe_link(edge[1],edge[2])
  end
  if mode.deep() then
    for _,edge in ipairs(M.deep) do M.safe_link(edge[1],edge[2]) end
  end
  for name,ceiling in pairs(M.science_budget) do
    local node=technology(name)
    local unit=node and node.unit
    if active(name) and unit and type(unit.count)=="number"
      and unit.count>ceiling then
      unit.count=ceiling
    end
  end
  for _,entry in ipairs(M.families) do
    local node=technology(entry[1])
    if active(entry[1]) then
      -- Existing source-mod node names, icons and technology prototypes
      -- stay intact; only Razi's private factory research is reordered.
      node.order=entry[2]
      if components[entry[1]] then node.essential=true end
    end
  end
end
return M
