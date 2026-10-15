-- AAI's source research may guide advanced Razi factories, but
-- cannot become a mandatory planet-discovery or travel prerequisite.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,why) if not ok then error(why,2) end end
local function node(pre)
  return {prerequisites=pre or {},unit={count=100,ingredients={{"space-science-pack",1}}}}
end
local function fixture(opts)
  opts=opts or {}
  local mode=opts.mode or "balanced"
  rawset(_G,"settings",{startup={["razi-planetary-interdependence"]={value=mode}}})
  rawset(_G,"mods",opts.mods==false and {} or {["aai-signal-transmission"]="0.6.0"})
  local technologies={
    ["aai-signal-transmission"]=node(),
    ["razi-network-precision-matrix"]=node({"planet-discovery-fulgora"}),
    ["razi-network-panglia-optic-bond"]=node({"planet-discovery-moshine"}),
    ["planet-discovery-moshine"]=node(),
    ["planet-discovery-fulgora"]=node(),
    ["beetlejuice-discovery"]=node(),
    ["umbra-discovery"]=node(),
    ["razi-outer-frontier-mastery"]=node()
  }
  rawset(_G,"data",{raw={technology=technologies}})
  package.loaded["prototypes.compat.interdependence_mode"]=nil
  package.loaded["prototypes.compat.aai_signal_partnerships"]=nil
  return technologies,require("prototypes.compat.aai_signal_partnerships")
end
local function has(t,id)
  for _,parent in ipairs(t.prerequisites or {}) do
    if parent==id then return true end
  end
  return false
end
local raw,m=fixture()
m.data_final_fixes()
for _,name in ipairs(m.targets) do
  check(has(raw[name],"aai-signal-transmission"),
    "Existing native AAI research should qualify advanced components")
end
check(not has(raw["planet-discovery-fulgora"],"aai-signal-transmission"),
  "Native world discoveries must not change")
local prior=#raw["razi-network-precision-matrix"].prerequisites
m.data_final_fixes()
check(#raw["razi-network-precision-matrix"].prerequisites==prior,
  "Second call duplicated a research prerequisite")
local renamed,renamed_mod=fixture()
renamed["signal-transmission"]=renamed["aai-signal-transmission"]
renamed["aai-signal-transmission"]=nil
renamed_mod.data_final_fixes()
check(has(renamed["razi-network-precision-matrix"],"signal-transmission"),
  "Supported native AAI alias must be accepted")
local absent,absent_module=fixture()
absent["aai-signal-transmission"]=nil
absent_module.data_final_fixes()
check(not has(absent["razi-network-precision-matrix"],
  "aai-signal-transmission"),"Missing source must not create fake research")
local late,late_mod=fixture()
late["aai-signal-transmission"].prerequisites={"beetlejuice-discovery"}
late_mod.data_final_fixes()
check(not has(late["razi-network-precision-matrix"],
  "aai-signal-transmission"),"Future system must not gate an earlier factory")
local cycle,c=fixture()
cycle["aai-signal-transmission"].prerequisites={
  "razi-network-precision-matrix"}
c.data_final_fixes()
check(not has(cycle["razi-network-precision-matrix"],
  "aai-signal-transmission"),"Native source must not cycle through target")
local hidden,h=fixture()
hidden["aai-signal-transmission"].hidden=true
h.data_final_fixes()
check(not has(hidden["razi-network-precision-matrix"],
  "aai-signal-transmission"),"Hidden research must not gate Razi components")
local off,o=fixture({mode="off"})
o.data_final_fixes()
check(not has(off["razi-network-precision-matrix"],
  "aai-signal-transmission"),"Off mode must preserve its native progression")
local missing,x=fixture({mods=false})
x.data_final_fixes()
check(not has(missing["razi-network-precision-matrix"],
  "aai-signal-transmission"),"AAI must remain optional")
local fork,f=fixture()
fork["aai-signal-transmission"]=nil
fork["my-signal-transmission"]=node()
fork["my-signal-transmission"].effects={{
  type="unlock-recipe",recipe="aai-signal-transmitter"}}
f.data_final_fixes()
check(has(fork["razi-network-precision-matrix"],
  "my-signal-transmission"),"Effect-backed native source alias not found")
print("AAI communication partnership: optional, cycles, aliases and modes passed")
