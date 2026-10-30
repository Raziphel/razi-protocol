---@diagnostic disable: undefined-field
-- Journal quests that opened with technologies the installed packs do not
-- define now point at the technology that unlocks the quest's key recipe,
-- or at the world discovery for a planet.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
local data=require("scripts.razi_journal_data")
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
print("PASS test_journal_quest_targets")
