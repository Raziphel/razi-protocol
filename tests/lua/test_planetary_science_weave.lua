-- Optional planetary science is added only when its native path works.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local function has_science(node,pack)
  for _,entry in ipairs((node.unit and node.unit.ingredients) or {}) do
    if (entry.name or entry[1])==pack then return true end
  end
  return false
end
local function has_parent(node,name)
  for _,entry in ipairs(node.prerequisites or {}) do
    if entry==name then return true end
  end
  return false
end
local function fixture(setting)
  rawset(_G,"settings",{startup={
    ["razi-planetary-interdependence"]={value=setting or "balanced"}
  }})
  local techs={
    ["planet-discovery-moshine"]={prerequisites={}},
    ["planet-discovery-paracelsin"]={prerequisites={}},
    ["planet-discovery-crucible"]={prerequisites={}},
    ["planet-discovery-vesta"]={prerequisites={"planet-discovery-crucible"}},
    ["moshine-native-research"]={
      prerequisites={"planet-discovery-moshine"},
      effects={{type="unlock-recipe",recipe="thermodynamic-science-pack"}}
    },
    ["razi-network-precision-matrix"]={
      prerequisites={"planet-discovery-moshine","planet-discovery-paracelsin"},
      unit={count=420,time=45,
        ingredients={{"solaris-tech-card",1},{"nyxaris-tech-card",1}}}
    },
    ["razi-network-panglia-optic-bond"]={
      prerequisites={"planet-discovery-moshine"},
      unit={count=360,ingredients={{"solaris-tech-card",1},
        {"nyxaris-tech-card",1}}}
    },
    ["razi-network-umbra-pressure-frame"]={
      prerequisites={"planet-discovery-crucible","planet-discovery-vesta"},
      unit={count=980,ingredients={{"beetlejuice-tech-card",1},
        {"umbra-tech-card",1}}}
    }
  }
  local raw={
    technology=techs,
    tool={
      ["thermodynamic-science-pack"]={},
      ["planet-crucible-science-pack"]={},
      ["solaris-tech-card"]={},
      ["nyxaris-tech-card"]={},
      ["beetlejuice-tech-card"]={},
      ["umbra-tech-card"]={}
    },
    item={["circuit"]={},["iron-plate"]={}},
    recipe={
      ["thermodynamic-science-pack"]={
        enabled=false,
        ingredients={{type="item",name="circuit",amount=1}},
        results={{type="item",name="thermodynamic-science-pack",amount=1}}
      },
      ["planet-crucible-science-pack"]={
        enabled=true,
        ingredients={{type="item",name="iron-plate",amount=1}},
        results={{type="item",name="planet-crucible-science-pack",amount=1}}
      }
    },
    lab={advanced={inputs={
      "solaris-tech-card","nyxaris-tech-card",
      "beetlejuice-tech-card","umbra-tech-card",
      "thermodynamic-science-pack",
      "planet-crucible-science-pack"
    }}}
  }
  rawset(_G,"data",{raw=raw})
  package.loaded["prototypes.technology.planetary_science_weave"]=nil
  local weave=require("prototypes.technology.planetary_science_weave")
  return raw,weave
end
local balanced,w=fixture("balanced")
w.data_final_fixes()
local matrix=balanced.technology["razi-network-precision-matrix"]
check(has_science(matrix,"thermodynamic-science-pack"),
  "Earlier native Moshine science must return in matrix research")
check(has_parent(matrix,"moshine-native-research"),
  "Native producer unlock must be listed as a real technology dependency")
check(not has_science(matrix,"electrochemical-science-pack"),
  "Missing source science must never become a requirement")
check(has_science(balanced.technology["razi-network-panglia-optic-bond"],
  "thermodynamic-science-pack"),
  "Panglia must be able to reuse Moshine's proven science producer")
local frame=balanced.technology["razi-network-umbra-pressure-frame"]
check(not has_science(frame,"planet-crucible-science-pack"),
  "Deep-only science must not leak into Balanced")
local prior=#matrix.unit.ingredients
local parents=#matrix.prerequisites
w.data_final_fixes()
check(#matrix.unit.ingredients==prior and #matrix.prerequisites==parents,
  "Repeated science weaving must be idempotent")

local deep,d=fixture("deep")
d.data_final_fixes()
check(has_science(deep.technology["razi-network-umbra-pressure-frame"],
  "planet-crucible-science-pack"),
  "Deep pressure research should consume native Crucible science")
check(not has_science(deep.technology["planet-discovery-crucible"] or {
    unit={ingredients={}}},"planet-crucible-science-pack"),
  "Planet discovery itself must remain untouched")
local unsupported,x=fixture("deep")
unsupported.lab.advanced.inputs={"beetlejuice-tech-card","umbra-tech-card",
  "solaris-tech-card","nyxaris-tech-card"}
x.data_final_fixes()
check(not has_science(unsupported.technology["razi-network-precision-matrix"],
  "thermodynamic-science-pack"),
  "Lab incompatibility must skip the extra science rather than softlock")
check(not has_science(unsupported.technology["razi-network-umbra-pressure-frame"],
  "planet-crucible-science-pack"),
  "Deep lab mismatch must not force an impossible science combination")
local late,late_w=fixture("balanced")
late.technology["moshine-native-research"].prerequisites={
  "razi-network-precision-matrix"
}
late_w.data_final_fixes()
check(not has_science(late.technology["razi-network-precision-matrix"],
  "thermodynamic-science-pack"),
  "Science unlocked only after target must never be required by target")
local no_owner,owner_w=fixture("balanced")
no_owner.technology["razi-network-precision-matrix"].prerequisites={}
owner_w.data_final_fixes()
check(not has_science(no_owner.technology["razi-network-precision-matrix"],
  "thermodynamic-science-pack"),
  "An unrelated world cannot be imposed before its discovery")
local removed,removed_w=fixture("balanced")
removed.recipe["thermodynamic-science-pack"].ingredients[1].name="nonexistent-item"
removed_w.data_final_fixes()
check(not has_science(removed.technology["razi-network-precision-matrix"],
  "thermodynamic-science-pack"),
  "Science source with absent inputs must not be presumed manufacturable")
local wrong_world,world_w=fixture("balanced")
wrong_world.planet={
  moshine={surface_properties={pressure=50}}
}
wrong_world.recipe["thermodynamic-science-pack"].surface_conditions={
  {property="pressure",min=120}
}
world_w.data_final_fixes()
check(not has_science(wrong_world.technology["razi-network-precision-matrix"],
  "thermodynamic-science-pack"),
  "A science source with incompatible surface conditions must be skipped")
local matching_world,matched_w=fixture("balanced")
matching_world.planet={
  moshine={surface_properties={pressure=150}}
}
matching_world.recipe["thermodynamic-science-pack"].surface_conditions={
  {property="pressure",min=120}
}
matched_w.data_final_fixes()
check(has_science(matching_world.technology["razi-network-precision-matrix"],
  "thermodynamic-science-pack"),
  "A compatible native science production surface should pass the guard")
local off,o=fixture("off")
o.data_final_fixes()
check(not has_science(off.technology["razi-network-precision-matrix"],
  "thermodynamic-science-pack"),"Off mode must not alter technologies")
for _,rule in ipairs(o.rules) do
  check(rule[1]:find("^razi%-network%-")~=nil,
    "Science weave must never directly edit source planet discoveries")
end
local f=assert(io.open("data-final-fixes.lua","r"))
local main=f:read("*a")
f:close()
local polish=assert(main:find(
 'require("prototypes.technology.research_tree_polish").data_final_fixes()',1,true))
local science=assert(main:find(
 'require("prototypes.technology.planetary_science_weave").data_final_fixes()',1,true))
check(science>polish,"Native science weave must run after industrial research polish")
print("Planetary science weave: modes, native supply, research cycle, labs and safety passed")
