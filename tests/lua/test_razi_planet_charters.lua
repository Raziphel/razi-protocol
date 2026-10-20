-- Source-only planetary charter and spoiler safety regression.
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("scripts.razi_planet_briefs")
local function check(ok,message) if not ok then error(message,2) end end
local worlds={"muluna","vulcanus","castra","arig","hyarion","tellus","corrundum","gleba","moshine","apia","panglia","fulgora","cerys","ribbonia","paracelsin","muria","athos","rubia","aquilo","nulla","maraxsis","cubium","linox","secretas","frozeta","tenebris","crucible","vesta","abacayba"}
for _,world in ipairs(worlds) do
  check(M.charter_for_site(world)==world,"missing freight charter: "..world)
  check(M.charter_for_quest({id=world})==world,"missing Journal charter: "..world)
end
check(M.charter_for_site("not-installed")==nil,"unknown sites must have no charter")
for _,star in ipairs({"calidus","solaris","nyxaris","vibrant",
  "vespera","beetlejuice","umbra"}) do
  check(M.star_charter(star)==star,"missing system charter: "..star)
end
check(M.star_charter("finale")==nil,"finale must not be a star system")
check(M.charter_for_quest({id="convergence-victory"})==nil,
  "final victory must never become a planetary side assignment")
local by_id={
  athos={id="athos"},["athos-particulate"]={id="athos-particulate"},
  ["frontier-recovery-charter"]={id="frontier-recovery-charter"},
  rubia={id="rubia"},aquilo={id="aquilo"},maraxsis={id="maraxsis"}
}
local visible=M.visible_related({id="athos"},by_id,
  function(quest) return quest.id=="athos-particulate" end,3)
check(#visible==1 and visible[1].id=="athos-particulate",
  "hide uninstalled or spoiler-sealed follow-up milestones")
check(#M.visible_related({id="rubia"},by_id,function() return true end,1)==1,
  "field assignment link budget must be bounded")
check(#M.visible_related({id="rubia"},by_id,function() return true end,0)==0,
  "zero-link budget must be respected")
check(#M.visible_related({id="vulcanus"},by_id,function() return true end)==0,
  "missing optional destinations must not create phantom links")
print("Planetary charter and spoiler contracts OK")
