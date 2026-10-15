-- Post-arrival industrial technology weave, with no source-mod rewrites.
dofile("tests/lua/razi_lib_bootstrap.lua")
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
local names={
 "razi-network-precision-matrix",
 "razi-network-matrix-cryo-controllers",
 "razi-network-matrix-rubia-logistics",
 "razi-network-matrix-linox-refining",
 "razi-network-panglia-optic-bond",
 "razi-network-bond-paracelsin-coils",
 "razi-network-bond-linox-refining",
 "razi-network-extreme-lattice",
 "razi-network-lattice-vesta-magnets",
 "razi-network-lattice-vesta-foundations",
 "razi-network-lattice-balack-shielding",
 "razi-network-umbra-pressure-frame",
 "razi-network-frame-vesta-foundations",
 "razi-network-frame-aquilo-controllers",
 "panglia_advanced_optics_nanotech"
}
local function setup(mode)
  rawset(_G,"settings",{startup={
    ["razi-planetary-interdependence"]={value=mode}
  }})
  local raw={technology={}}
  for _,name in ipairs(names) do
    raw.technology[name]={
      order="source-author-order",prerequisites={},
      unit={count=2400,time=60,ingredients={{"solaris-tech-card",1}}}
    }
  end
  raw.technology["planet-discovery-vesta"]={
    order="original-vesta",prerequisites={}
  }
  raw.technology["panglia_planet_discovery_panglia"]={
    order="original-panglia",prerequisites={}
  }
  rawset(_G,"data",{raw=raw})
  package.loaded["prototypes.technology.research_tree_polish"]=nil
  return raw,require("prototypes.technology.research_tree_polish")
end
local function has(t,parent)
  for _,name in ipairs(t.prerequisites or {}) do
    if name==parent then return true end
  end
  return false
end
local balanced,m=setup("balanced")
m.data_final_fixes()
check(has(balanced.technology["razi-network-bond-linox-refining"],
  "panglia_advanced_optics_nanotech"),
  "Balanced Panglia/Linox handoff must follow the optical technology")
check(not has(balanced.technology["razi-network-umbra-pressure-frame"],
  "razi-network-extreme-lattice"),
  "Deep planetary coupling leaked into Balanced mode")
check(balanced.technology["razi-network-matrix-cryo-controllers"].unit.count==760
  and balanced.technology["razi-network-matrix-linox-refining"].unit.count==780
  and balanced.technology["razi-network-lattice-vesta-foundations"].unit.count==1250,
  "Factory upgrade science budgets not capped")
check(balanced.technology["razi-network-precision-matrix"].unit.count==400
  and balanced.technology["razi-network-extreme-lattice"].unit.count==650,
  "Core manufacturing milestones must have reachable science budgets")
check(balanced.technology["razi-network-panglia-optic-bond"].essential
  and balanced.technology["razi-network-extreme-lattice"].essential,
  "The four component technologies must be visible in essential research")
check(balanced.technology["planet-discovery-vesta"].order=="original-vesta"
  and balanced.technology["panglia_planet_discovery_panglia"].order=="original-panglia",
  "Razi industrial polish should not reorder native discoveries")
local count=#balanced.technology["razi-network-bond-linox-refining"].prerequisites
m.data_final_fixes()
check(#balanced.technology["razi-network-bond-linox-refining"].prerequisites==count,
  "Repeated late research weave introduced duplicate prerequisites")

local deep,d=setup("deep")
d.data_final_fixes()
for _,edge in ipairs(d.deep) do
  check(has(deep.technology[edge[1]],edge[2]),
    "Deep network research missing its guarded source connection: "..edge[1])
end
check(has(deep.technology["razi-network-umbra-pressure-frame"],
  "razi-network-extreme-lattice"),
  "Deep pressure framework must recognise the older Lattice network")
deep.technology["razi-network-precision-matrix"].unit.count=320
d.data_final_fixes()
check(deep.technology["razi-network-precision-matrix"].unit.count==320,
  "Cheaper user tuning must not be increased")

local cycle,cyclic=setup("deep")
cycle.technology["razi-network-extreme-lattice"].prerequisites={
  "razi-network-umbra-pressure-frame"
}
cyclic.data_final_fixes()
check(not has(cycle.technology["razi-network-umbra-pressure-frame"],
  "razi-network-extreme-lattice"),
  "A source-mod cycle must suppress the optional Deep prerequisite")
local missing,missing_module=setup("balanced")
missing.technology["panglia_advanced_optics_nanotech"]=nil
missing_module.data_final_fixes()
check(not has(missing.technology["razi-network-bond-paracelsin-coils"],
  "panglia_advanced_optics_nanotech"),
  "Missing source research must not create phantom prerequisites")

local off,o=setup("off")
o.data_final_fixes()
check(off.technology["razi-network-matrix-cryo-controllers"].unit.count==2400
  and not off.technology["razi-network-panglia-optic-bond"].essential
  and not has(off.technology["razi-network-bond-linox-refining"],
    "panglia_advanced_optics_nanotech"),
  "Interdependence Off must leave this research untouched")
print("Research tree polish: Balanced, Deep, Off, idempotence, native preservation and cycles passed")
