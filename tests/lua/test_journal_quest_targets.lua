---@diagnostic disable: undefined-field, need-check-nil, param-type-mismatch
-- Journal quests that opened with technologies the installed packs do not
-- define now point at the technology that unlocks the quest's key recipe,
-- or at the world discovery for a planet.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local data=require("scripts.journal.data")
local expected={
 ["nauvis-power"]="steam-power",
 ["nauvis-advanced-electronics"]="advanced-circuit",
 ["fragment-2"]="processing-unit",
 ["compression"]="planetaris-compression-science",
 ["alien"]="ribbonia-tech-rocket-part",
 ["biorecycling"]="craptonite-processing",
 ["galvanization"]="galvanization-science-pack",
 ["gas-manipulation"]="s1_gas_manipulation_science_pack",
 ["nuclear-science"]="cerysian-science-pack",
}
for id,tech in pairs(expected) do
 local quest=assert(data.by_id[id],id.." is missing")
 check(quest.tech==tech,id.." must open with "..tech..", not "..tostring(quest.tech))
end
local frozeta=data.by_id["frozeta"]
check(frozeta and frozeta.world=="frozeta" and frozeta.tech==nil,
 "frozeta opens with the discovery of the world")

-- Every research of ours that opens a quest must be defined in prototypes/.
-- Researches of other mods and of the base game cannot be seen without the
-- game, so only the razi- ones are checked.
local sources={}
local listing=io.popen("find prototypes -name '*.lua'")
for path in listing:lines() do
 local file=io.open(path,"r")
 check(file,"Cannot read "..path)
 sources[#sources+1]=file:read("*a")
 file:close()
end
listing:close()
check(#sources>0,"No prototype files found")
local function defined(tech)
 for _,text in ipairs(sources) do
  if text:find('"'..tech..'"',1,true) or text:find("'"..tech.."'",1,true) then
   return true
  end
 end
 return false
end
for _,quest in ipairs(data.quests) do
 local tech=quest.tech
 if tech and tech:sub(1,5)=="razi-" then
  check(defined(tech),"Quest "..quest.id.." opens with research "..tech
   .." that no prototype defines")
 end
end

print("PASS test_journal_quest_targets")

-- Under Krastorio 2 the radar needs green science (kr-sentinel, 200 red + green): its milestone comes after it.
local radar=assert(data.by_id["nauvis-radar"],"nauvis-radar is missing")
check(radar.phase=="growth","nauvis-radar must be a growth milestone, not "..tostring(radar.phase))
local after_green=false
for _,id in ipairs(radar.requires) do after_green=after_green or id=="green-science" end
check(after_green,"nauvis-radar must require green-science")
