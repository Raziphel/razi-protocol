-- Standalone Lua 5.2 suite for source-aware asteroid distribution.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local chunks={
  ["imersite-asteroid-chunk"]={},
  ["auric-asteroid-chunk"]={},
  ["foliax-charged-promethium-asteroid-chunk"]={}
}
local enemy={}
for _,size in ipairs({"small","medium","big","huge"}) do
  enemy[size.."-auric-asteroid"]={type="asteroid"}
end
local original_custom={
  type="asteroid-chunk",asteroid="auric-asteroid-chunk",
  spawn_points={{distance=.5,probability=.019,speed=.04}}
}
local original_vanilla={
  type="asteroid-chunk",asteroid="metallic-asteroid-chunk",
  spawn_points={{distance=.5,probability=.05,speed=.035}}
}
local shared={original_custom,original_vanilla}
local routes={
  starter={from="nauvis",to="muluna",asteroid_spawn_definitions={
    original_vanilla}},
  fulgora={from="fulgora",to="ribbonia",asteroid_spawn_definitions={
    original_vanilla}},
  -- A direct future source-owned shortcut must still count as Aquilo-bound.
  direct={from="fulgora",to="aquilo",asteroid_spawn_definitions={
    original_vanilla}},
  reverse={from="secretas",to="cubium",
    asteroid_spawn_definitions={original_vanilla}},
  belt={from="asteroid-belt-inner-edge",to="asteroid-belt-outer-edge",
    asteroid_spawn_definitions={original_vanilla}},
  aquilo={from="rubia",to="aquilo",asteroid_spawn_definitions={
    original_vanilla}},
  inner={from="cubium",to="secretas",asteroid_spawn_definitions=shared},
  moon={from="secretas",to="frozeta"},
  outer={from="secretas",to="solar-system-edge",
    asteroid_spawn_definitions={original_vanilla}},
  unrelated={from="aquilo",to="frozeta",
    asteroid_spawn_definitions={original_vanilla}},
  deep={from="solar-system-edge",to="nexus",
    asteroid_spawn_definitions={original_vanilla}}
}
local fulgora={asteroid_spawn_definitions={original_vanilla}}
local secretas={asteroid_spawn_definitions={original_custom}}
local map={
  ["asteroid-chunk"]=chunks,asteroid=enemy,
  planet={fulgora=fulgora},
  ["space-location"]={
    secretas=secretas,
    ["asteroid-belt-inner-edge"]={},
    ["asteroid-belt-outer-edge"]={}
  },
  ["space-connection"]=routes
}
rawset(_G,"data",{raw=map})
rawset(_G,"log",function()end)
package.loaded["scripts.galactic_catalog"]={system=function(name)
  if name=="nauvis" or name=="muluna" then return "calidus" end
  return "unassigned"
end}
package.loaded["scripts.razi_asteroid_difficulty"]=nil
package.loaded["prototypes.system.modded_asteroid_distribution"]=nil
local distribution=require("prototypes.system.modded_asteroid_distribution")
local function def(route,name)
  for _,row in ipairs(route.asteroid_spawn_definitions or {}) do
    if row.asteroid==name then return row end
  end
end
local original_shared=shared
local changed=distribution.data_final_fixes()
check(changed>=13,"Expected source-aware custom encounters were not added")
check(not def(routes.starter,"imersite-asteroid-chunk"),
  "Home-system starter route must remain free from imersite harvesting")
check(not def(routes.starter,"auric-asteroid-chunk"),
  "Auric debris must never appear around Nauvis")
check(def(routes.fulgora,"imersite-asteroid-chunk"),
  "Early Fulgora routes must have a trace of imersite")
check(def(routes.belt,"imersite-asteroid-chunk"),
  "The Vibrant belt crossing must become the primary imersite field")
check(def(routes.aquilo,"imersite-asteroid-chunk"),
  "Aquilo-bound routes need proper advanced imersite gathering")
check(def(routes.belt,"imersite-asteroid-chunk").spawn_points[3].probability
  >def(routes.fulgora,"imersite-asteroid-chunk").spawn_points[3].probability,
  "Belt crossing has to reward players more than trace Fulgora")
check(def(routes.direct,"imersite-asteroid-chunk").spawn_points[3].probability
  ==def(routes.aquilo,"imersite-asteroid-chunk").spawn_points[3].probability,
  "Fulgora-Aquilo must get Aquilo's harvesting rate, not Fulgora traces")
check(not def(routes.deep,"auric-asteroid-chunk"),
  "Auric debris cannot scatter across unrelated Deep Space routes")
check(def(routes.inner,"auric-asteroid-chunk")==original_custom,
  "Native Secretas Auric curve must remain byte-for-byte source-owned")
check(def(routes.inner,"big-auric-asteroid"),
  "Secretas approach should introduce serious Auric enemies")
check(not def(routes.inner,"huge-auric-asteroid"),
  "Huge Auric enemies only belong in terminal Secretas expedition")
local approach=def(routes.inner,"small-auric-asteroid").spawn_points
check(approach[1].probability<approach[#approach].probability,
  "Auric hazards should increase towards Secretas at route end")
local return_leg=def(routes.reverse,"small-auric-asteroid").spawn_points
check(return_leg[1].probability>return_leg[#return_leg].probability,
  "Reversed Secretas corridor must mirror the hazard gradient")
check(def(routes.outer,"huge-auric-asteroid"),
  "Deep Space gate route should support rare huge Auric enemies")
local huge_field=def(routes.outer,"huge-auric-asteroid").spawn_points
check(huge_field[1].probability>huge_field[#huge_field].probability,
  "Huge Auric field should stay near Secretas, not peak in empty space")
check(def(routes.moon,"auric-asteroid-chunk")
  and def(routes.moon,"big-auric-asteroid"),
  "Frozeta supply crossing should contain richer Auric asteroids")
check(def(routes.moon,"auric-asteroid-chunk").spawn_points[6].probability
  >=.008*.52,"Frozeta's end of its supply route should not be depleted")
check(routes.inner.asteroid_spawn_definitions~=original_shared,
  "Adding Auric to one connection cannot mutate the source shared table")
check(original_shared[1]==original_custom and
  original_custom.spawn_points[1].probability==.019,
  "Native source Auric probability must not be overwritten")
check(fulgora.asteroid_spawn_definitions[1]==original_vanilla,
  "Fulgora stationary original definitions must survive")
check(def(fulgora,"imersite-asteroid-chunk")
  and def(fulgora,"imersite-asteroid-chunk").probability==.001,
  "Fulgora stationary field must remain a rare trace")
check(not def(secretas,"imersite-asteroid-chunk"),
  "Do not invent Imersite in Secretas orbit")
check(def(secretas,"auric-asteroid-chunk")==original_custom,
  "Do not double the original Secretas stationary Auric field")
check(not def(routes.moon,"foliax-charged-promethium-asteroid-chunk"),
  "Foliax's craft-only fuel chunk cannot spawn from empty space")
local fields=distribution.classify_unknowns()
check(fields.auric and fields.imersite,
  "Custom asteroid discovery must identify existing prototype families")
local snapshot=routes.outer.asteroid_spawn_definitions
check(distribution.data_final_fixes()==0,
  "Second distribution pass must never multiply custom asteroids")
check(routes.outer.asteroid_spawn_definitions==snapshot,
  "Idempotent pass may not replace the route table a second time")
local used=0
for _,row in ipairs(routes.outer.asteroid_spawn_definitions) do
  if row.asteroid=="huge-auric-asteroid" then used=used+1 end
end
check(used==1,"Auric enemy definition was duplicated")
-- Simulate a new install without either mod. Must gracefully do nothing.
chunks["imersite-asteroid-chunk"]=nil
chunks["auric-asteroid-chunk"]=nil
package.loaded["prototypes.system.modded_asteroid_distribution"]=nil
local no_sources=require("prototypes.system.modded_asteroid_distribution")
local other={from="sye-nyxaris",to="sye-vibrant"}
routes.new=other
check(no_sources.data_final_fixes()==0,
  "Missing custom source mods should not invent items or crash")
check(other.asteroid_spawn_definitions==nil,
  "Source-free install must not create fabricated asteroid entries")
print("Razi modded asteroid distribution passed")
