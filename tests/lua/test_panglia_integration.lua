-- Panglia integration regression: no new science bypasses or free imports.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local captured
package.loaded["prototypes.compat.planet_production_exchanges"]={
 register_additional=function(specs) captured=specs end
}
rawset(_G,"mods",{["panglia_planet"]="0.7.2"})
local bridge=require("prototypes.compat.panglia_industry")
bridge.data_final_fixes()
check(captured and #captured==2,"Panglia's two reciprocal production bridges missing")
local seen={}
for _,spec in ipairs(captured) do
 check(not seen[spec.name],"Duplicate Panglia exchange")
 seen[spec.name]=true
 check(spec.source_mod=="panglia_planet" and spec.working_world,
   "Exchange no longer belongs to Panglia's Moshine network")
 check(spec.require_supplier_provenance and spec.keep_native_category,
   "Native industry or import provenance was bypassed")
 check(spec.batch==4 and spec.bonus==1
   and spec.max_bonus_fraction<=.25
   and spec.time_multiplier>=1.1,
   "Panglia exchange breaks the intended 25 percent cap")
 check(#spec.planets>=3 and #spec.additional==2
   and #spec.supplier_recipes==2,
   "Panglia exchange lost its actual research and supply links")
 local available={}
 for _,source in ipairs(spec.supplier_recipes) do
   available[source.product]=true
 end
 for _,extra in ipairs(spec.additional) do
   check(available[extra.name],
     "Unproven imported component in "..spec.name)
 end
end
check(seen["razi-panglia-biooptic-glass"]
  and seen["razi-moshine-panglia-optical-cables"],
  "Either direction of Panglia's cargo loop was lost")
captured=nil
mods["panglia_planet"]=nil
bridge.data_final_fixes()
check(captured==nil,"Absent Panglia still created bonus technology")

local function source(path)
 local fd=assert(io.open(path,"r"))
 local s=fd:read("*a") fd:close()
 return s
end
local gates=source("prototypes/technology/seven_system_gates.lua")
check(gates:find('"panglia_planet_discovery_panglia"',1,true),
 "Panglia disappeared from frontier mastery")
check(not gates:find('replace_requirements("panglia_planet_discovery_panglia"',1,true),
 "Source data-cell technology must never be replaced with ordinary science")
local journal=require("scripts.razi_journal_data")
local milestones={}
for _,q in ipairs(journal.quests) do
 check(not milestones[q.id],"Duplicate Chronicle ID: "..q.id)
 milestones[q.id]=q
end
for _,id in ipairs({"panglia","panglia-glass","panglia-timewarp",
  "panglia-dna-optics","panglia-fish-dna","panglia-biter-dna",
  "panglia-demolisher-dna","panglia-pentapod-dna","panglia-dna",
  "panglia-simulation","panglia-matrix","panglia-sentient",
  "panglia-biooptic-trade","panglia-optical-return"}) do
 check(milestones[id],"Missing Panglia story objective: "..id)
end
for _,id in ipairs({"panglia-biooptic-trade","panglia-optical-return"}) do
 check(milestones[id].chapter=="network",
   "Industry bridges belong in the interplanetary network chapter")
end
check(source("data-final-fixes.lua"):find(
  'require("prototypes.compat.panglia_industry").data_final_fixes()',1,true),
  "Panglia's guarded production integration is not registered")
print("Panglia source science, story milestones and industry guards passed")
