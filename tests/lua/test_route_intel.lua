---@diagnostic disable: need-check-nil, undefined-field
-- luacheck: ignore 122
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
check(hz.kind(routes.huge)=="belt-crossing","Belt class lost")
check(hz.kind(routes.medium)=="interstellar","Interstellar class lost")
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
-- The route note is story text: the story is off by default and the tooltip
-- then holds only facts (route, ten-level danger, system).
local story=require("scripts.razi_story")
check(story.enabled()==false,"The story text must be off by default")
check(#regional.custom_tooltip_fields==3,
  "Regional tooltip must contain only route, ten-level danger and system")
check(row(regional,"dispatch")==nil,"Story off still shows a route note")
for _,f in ipairs(regional.custom_tooltip_fields) do
  local text=tostring(f.name[1])..tostring(type(f.value)=="table" and f.value[1] or f.value)
  check(not text:find("dispatch",1,true),"Story off still references a route note key")
end
story.configure(true)
local noted={from="vulcanus",to="arig",length=19500,shape="arc"}
check(intel.annotate(noted),"Known regional route should be annotated")
check(#noted.custom_tooltip_fields==4,
  "With the story on the tooltip adds the route note")
check(row(noted,"dispatch").value[1]=="razi-route-intel.dispatch-furnace-desert",
  "Wrong route note key")
story.configure(false)
check(row(regional,"danger")~=nil and row(regional,"quality-hazard")==nil,
  "Only the unified ten-level asteroid danger may be shown")
local quality=require("scripts.razi_asteroid_difficulty")
local _,regional_stage=quality.route_range(regional)
local quality_field=row(regional,"danger")
check(quality_field and quality_field.value[2]
  =="[color="..quality.route_color_richtext(regional_stage).."]",
  "Route tooltip color must match the exact starmap quality level")
local sector=row(regional,"sector")
check(sector and sector.value[1]=="razi-route-intel.inside-system",
  "Regional tooltip uses the wrong system identity")
check(not row(regional,"alert") and not row(regional,"preparation")
  and not row(regional,"quality-warning"),
  "Harmless local freight must not receive old combat alerts")
local cross={from="sye-solaris",to="sye-vibrant",shape="line"}
intel.annotate(cross)
check(row(cross,"sector").value[1]=="razi-route-intel.across-systems",
  "Interstellar sector label missing")
check(not row(cross,"haul") and not row(cross,"distance"),
  "Missing route distance should not produce two unlisted rows")
check(not row(cross,"composition"),
  "No classified spawns should leave the tooltip quiet")
intel.annotate(routes.huge)
check(row(routes.huge,"danger") and row(routes.huge,"progress")
  and row(routes.huge,"preparation"),
  "Belt crossing must show one ten-level rating and preparation advice")
check(not row(routes.huge,"alert") and not row(routes.huge,"quality-warning"),
  "Old five-tier alert and duplicated Legendary warnings must be gone")
intel.annotate(routes.unknown)
check(row(routes.unknown,"unknown") and row(routes.unknown,"preparation"),
  "Modded contacts must retain an explicit uncertainty warning")
check(not intel.annotate(regional),"Regional tooltip must not duplicate")
check(#routes.external.custom_tooltip_fields==3,
  "External route should retain its original row and unified rating")
check(routes.external.custom_tooltip_fields[1].order==12,
  "External tooltip ownership lost")
check(routes.external.localised_description[1]=="other.description",
  "Original description modified")
check(not intel.annotate(routes.external),"Second application must be idempotent")
check(#routes.external.custom_tooltip_fields==3,"Fields duplicated")
rawset(_G,"data",{raw={["space-connection"]=routes}})
rawset(_G,"settings",{startup={["razi-route-intelligence"]={value=false}}})
intel.data_final_fixes()
check(routes.calm.custom_tooltip_fields==nil,"Disabled setting should preserve route")
settings.startup["razi-route-intelligence"].value=true
intel.data_final_fixes()
check(routes.calm.custom_tooltip_fields~=nil,"Enabled setting should add fields")
check(row(routes.calm,"danger")~=nil,
  "Starter routes need a blue Level 1 danger value")
check(row(routes.calm,"danger").value[2]
  =="[color="..quality.route_color_richtext(1).."]",
  "Level 1 tooltip must use the same blue as its starmap marker")
local nexus={from="solar-system-edge",to="nexus",length=300000,
  asteroid_spawn_definitions={
    def("huge-metallic-asteroid",0.2),
    {type="asteroid-chunk",asteroid="oxide-asteroid-chunk",probability=.1}
  }}
check(intel.annotate(nexus),"Deep Space route should receive one danger row")
local danger=row(nexus,"danger")
check(danger and danger.value[3][1]=="razi-route-intel.quality-stage"
  and danger.value[3][2]=="10",
  "Deep Space must use the one Level 10 / 10 scale")
check(row(nexus,"largest") and row(nexus,"salvage"),
  "Preserve asteroid sizes and salvage facts")
local advisory=row(nexus,"preparation")
check(advisory and advisory.value[1]=="razi-route-intel.prepare-legendary",
  "Level 10 needs one meaningful Legendary readiness recommendation")
check(not row(nexus,"alert") and not row(nexus,"quality-warning")
  and not row(nexus,"quality-hazard") and not row(nexus,"distance"),
  "Legacy risk, duplicate warnings and duplicate distance must be removed")
local danger_count=0
for _,f in ipairs(nexus.custom_tooltip_fields) do
  if f.name[1]=="razi-route-intel.danger" then
    danger_count=danger_count+1
  end
end
check(danger_count==1,"Deep Space can have only one rating")
check(not intel.annotate(nexus),"Second route inspection should be idempotent")
-- Each "show" switch hides exactly its own row when turned off.
for _,name in ipairs({"danger","sizes","salvage","advice","unknown","belts","sectors","haul"}) do
  settings.startup["razi-route-show-"..name]={value=false}
end
local hidden={from="sye-calidus",to="sye-solaris",length=120000,
  asteroid_spawn_definitions={
    def("huge-metallic-asteroid",0.2),
    {type="asteroid-chunk",asteroid="oxide-asteroid-chunk",probability=.1}
  }}
check(intel.annotate(hidden),"Route should still be annotated with every row hidden")
for _,key in ipairs({"danger","largest","salvage","preparation","unknown","progress","sector","haul"}) do
  check(row(hidden,key)==nil,"Switch off must hide the "..key.." row")
end
check(row(hidden,"route")~=nil,"The route class row has no switch")
settings.startup["razi-route-show-danger"].value=true
local shown={from="sye-calidus",to="sye-solaris",length=120000,
  asteroid_spawn_definitions=hidden.asteroid_spawn_definitions}
intel.annotate(shown)
check(row(shown,"danger")~=nil and row(shown,"sector")==nil,
  "Only the switched-on row should appear")
-- Every route note listed in the dossiers has its text in both languages
-- (the notes are shown only while the story text is on).
local dossier_file=assert(io.open("prototypes/system/route_dossiers.lua","r"))
local dossier_source=dossier_file:read("*a")
dossier_file:close()
local note_count=0
for _,lang in ipairs({"en","ru"}) do
  local locale_file=assert(io.open("locale/"..lang.."/routes.cfg","r"))
  local locale=locale_file:read("*a")
  locale_file:close()
  note_count=0
  for id in dossier_source:gmatch('{"[^"]+","[^"]+","([%w%-]+)"}') do
    note_count=note_count+1
    check(locale:find("\ndispatch-"..id.."=",1,true),lang..": no route note "..id)
  end
  check(locale:find("\ndispatch=",1,true),lang..": no route note label")
end
check(note_count>60,"The route note list was not read")
print("Razi route tooltip and hazard fixtures passed")
