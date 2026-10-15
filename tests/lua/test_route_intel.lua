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
check(hz.color(routes.huge)==hz.colors[5],
 "Huge-asteroid belt route must appear red instead of misleading purple")
check(hz.color({from="razi-umbra-belt-inner",
 to="razi-umbra-belt-outer",asteroid_spawn_definitions={}})==hz.belt_color,
 "Undocumented physical belt still needs amber caution color")
check(intel.annotate(routes.external),"External route should be annotated")
local regional={from="vulcanus",to="arig",length=19500,shape="arc"}
check(intel.annotate(regional),"Known regional route should be annotated")
local function row(route,key)
  for _,f in ipairs(route.custom_tooltip_fields or {}) do
    if type(f.name)=="table" and f.name[1]=="razi-route-intel."..key then
      return f
    end
  end
end
check(#regional.custom_tooltip_fields==4,
  "Harmless local routes should not bury native tooltips in warnings")
local sector=row(regional,"sector")
check(sector and sector.value[1]=="razi-route-intel.inside-system",
  "Regional tooltip uses the wrong system identity")
check(not row(regional,"alert") and not row(regional,"preparation"),
  "Harmless local freight must not receive combat alerts")
local cross={from="sye-solaris",to="sye-vibrant",shape="line"}
intel.annotate(cross)
check(row(cross,"sector").value[1]=="razi-route-intel.across-systems",
  "Interstellar sector label missing")
check(not row(cross,"haul") and not row(cross,"distance"),
  "Missing route distance should not produce two unlisted rows")
check(not row(cross,"composition"),
  "No classified spawns should leave the tooltip quiet")
intel.annotate(routes.huge)
check(row(routes.huge,"alert").value[1]=="razi-route-intel.alert-5",
  "Critical belt route must show a prominent hazard warning")
check(row(routes.huge,"progress") and row(routes.huge,"preparation"),
  "Required belt crossing must carry expedition preparation")
intel.annotate(routes.unknown)
check(row(routes.unknown,"unknown") and row(routes.unknown,"preparation"),
  "Modded contacts must retain an explicit uncertainty warning")
check(not intel.annotate(regional),"Regional tooltip must not duplicate")
check(#routes.external.custom_tooltip_fields==4,
  "Quiet external route must preserve only its owned source row and facts")
check(routes.external.custom_tooltip_fields[1].order==12,
  "External tooltip ownership lost")
check(routes.external.localised_description[1]=="other.description",
  "Original description modified")
check(not intel.annotate(routes.external),"Second application must be idempotent")
check(#routes.external.custom_tooltip_fields==4,"Fields duplicated")
rawset(_G,"data",{raw={["space-connection"]=routes}})
rawset(_G,"settings",{startup={["razi-route-intelligence"]={value=false}}})
intel.data_final_fixes()
check(routes.calm.custom_tooltip_fields==nil,"Disabled setting should preserve route")
settings.startup["razi-route-intelligence"].value=true
intel.data_final_fixes()
check(routes.calm.custom_tooltip_fields~=nil,"Enabled setting should add fields")
print("Razi route tooltip and hazard fixtures passed")
