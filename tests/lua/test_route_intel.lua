-- Razi route tooltip and hazard inspection fixtures.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(x,msg) if not x then error(msg,2) end end
local hz=require("prototypes.system.route_hazards")
local intel=require("prototypes.system.route_intel")
local function def(name, probability)
  return {asteroid=name,spawn_points={{distance=0.5,probability=probability}}}
end
local routes={
  calm={from="nauvis",to="muluna",length=12000},
  medium={from="sye-solaris",to="sye-nyxaris",length=82000,shape="line",
    asteroid_spawn_definitions={def("medium-metallic-asteroid",0.02)}},
  huge={from="razi-umbra-belt-inner",to="razi-umbra-belt-outer",
    length=8000,asteroid_spawn_definitions={
      def("huge-oxide-asteroid",0.0002),
      {type="asteroid-chunk",asteroid="oxide-asteroid-chunk",probability=0.10}}},
  unknown={from="cubium",to="secretas",length=17000,
    asteroid_spawn_definitions={def("modded-asteroid",0.03)}},
  external={from="foo",to="bar",length=9000,
    localised_description={"other.description"},
    custom_tooltip_fields={{name={"other.label"},value={"other.value"},order=12}}}
}
check(hz.inspect(routes.calm).tier==1,"Empty route should not invent asteroids")
check(hz.inspect(routes.medium).tier==3,"Medium asteroid hazard lost")
check(hz.inspect(routes.huge).tier==5,"Huge asteroid threat lost")
check(hz.inspect(routes.huge).chunks==1,"Chunk scan lost")
check(hz.inspect(routes.huge).mix=="single","One threat size should remain single")
check(hz.inspect(routes.unknown).mix=="unclassified","Unknown size must be flagged")
check(hz.haul_class(routes.calm)=="shuttle","Local freight class lost")
check(hz.haul_class(routes.medium)=="long-haul","Long haul classification lost")
check(hz.haul_class({length=200000})=="expedition","Expedition class lost")
check(hz.haul_class({})=="unlisted","Unspecified distance must stay unknown")
local mixed={asteroid_spawn_definitions={def("small-metallic-asteroid",0.1),
  def("big-oxide-asteroid",0.0001)}}
check(hz.inspect(mixed).mix=="mixed","Asteroid size mixtures should be shown")
check(hz.inspect(routes.unknown).unknown,"Modded unknowns must be reported")
check(hz.inspect(routes.unknown).tier>=3,"Unknown hazards should not look safe")
check(hz.kind(routes.huge)=="belt-crossing","Belt class lost")
check(hz.kind(routes.medium)=="interstellar","Interstellar class lost")
check(hz.color(routes.huge)==hz.belt_color,"Belt art must remain identifiable")
check(intel.annotate(routes.external),"External route should be annotated")
local regional={from="vulcanus",to="arig",length=19500,shape="arc"}
check(intel.annotate(regional),"Known regional route should be annotated")
check(#regional.custom_tooltip_fields==9,"Regional route needs one sector line")
local sector=regional.custom_tooltip_fields[7]
check(sector.name[1]=="razi-route-intel.sector"
  and sector.value[1]=="razi-route-intel.inside-system",
  "Regional tooltip uses the wrong system identity")
local cross={from="sye-solaris",to="sye-vibrant",shape="line"}
intel.annotate(cross)
check(cross.custom_tooltip_fields[7].value[1]
  =="razi-route-intel.across-systems","Interstellar sector label missing")
check(cross.custom_tooltip_fields[8].value[1]=="razi-route-intel.haul-unlisted",
  "Missing distance must remain unlisted")
check(cross.custom_tooltip_fields[9].value[1]=="razi-route-intel.mix-unlisted",
  "Missing spawns must not invent hostile contacts")
check(not intel.annotate(regional),"Regional tooltip must not duplicate")
check(#routes.external.custom_tooltip_fields==9,"Existing tooltip field was lost")
check(routes.external.custom_tooltip_fields[1].order==12,"External tooltip ownership lost")
check(routes.external.localised_description[1]=="other.description",
  "Original description modified")
check(not intel.annotate(routes.external),"Second application must be idempotent")
check(#routes.external.custom_tooltip_fields==9,"Fields duplicated")
rawset(_G,"data",{raw={["space-connection"]=routes}})
rawset(_G,"settings",{startup={["razi-route-intelligence"]={value=false}}})
intel.data_final_fixes()
check(routes.calm.custom_tooltip_fields==nil,"Disabled setting should preserve route")
settings.startup["razi-route-intelligence"].value=true
intel.data_final_fixes()
check(routes.calm.custom_tooltip_fields~=nil,"Enabled setting should add fields")
print("Razi route tooltip and hazard fixtures passed")
