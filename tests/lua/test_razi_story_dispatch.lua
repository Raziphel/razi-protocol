-- Archive notifications: research, world discoveries, shipped mandates,
-- rate limiting, per-player muting and old-save-safe storage.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
package.loaded["scripts.razi_journal_data"]={by_id={
  ["first-signal"]={id="first-signal",tech="automation"},
  ["green-science"]={id="green-science",tech="logistic-science-pack"},
  castra={id="castra",tech="planet-discovery-castra"},
  nulla={id="nulla",world="nulla"},
  ["convergence-stellar"]={id="convergence-stellar",tech="razi-commission",
    convergence="stellar"}
}}
package.loaded["scripts.razi_journal_corporate"]={
  {id="corp-welcome",unlock="first-signal"},
  {id="corp-shift-roster",unlock="green-science",series="field"},
  {id="corp-castra",unlock="castra"},
  {id="corp-nulla",unlock="nulla"},
  {id="corp-shipment-stellar",unlock="convergence-stellar"}
}
storage={}
local a,b={},{}
local one={index=1,print=function(msg) a[#a+1]=msg end}
local two={index=2,print=function(msg) b[#b+1]=msg end}
local force={index=9,connected_players={one,two}}
game={tick=100,forces={[9]=force}}
local notices=require("scripts.razi_story_dispatch")
notices.on_research{research={name="automation",force=force}}
game.tick=160;notices.flush()
check(#a==0,"Research notification was not throttled")
game.tick=221;notices.flush()
check(#a==1 and #b==1,"Single research should notify both active readers")
check(storage.razi_expedition_journal[1].story_unread["corp-welcome"],
  "New archive record must be marked unread")
notices.on_research{research={name="automation",force=force}}
game.tick=360;notices.flush()
check(#a==1,"Duplicate research must not reannounce a story page")
storage.razi_expedition_journal[2].story_alerts=false
notices.on_research{research={name="planet-discovery-castra",force=force}}
notices.on_research{research={name="test-world",force=force,
  prototype={effects={{type="unlock-space-location",space_location="nulla"}}}}}
game.tick=490;notices.flush()
check(#a==2 and #b==1,"Bulk research must emit one notice and honor muting")
check(a[2][1]=="razi-story.records-unlocked","Research burst should be summarized")
check(storage.razi_expedition_journal[2].story_unread["corp-nulla"],
  "Muted readers should still receive unread archive markers")
notices.shipment(force,"stellar")
notices.shipment(force,"stellar")
check(#a==3 and #b==1,"A real shipment is announced exactly once")
local recipient={index=12,connected_players={one}}
game.forces[12]=recipient
notices.forces_merged{source_index=9,destination=recipient}
notices.shipment(recipient,"stellar")
check(#a==3,"Merging multiplayer forces must preserve announcement deduplication")
notices.shipment(recipient,"victory")
check(#a==4,"Final victory should release its own epilogue notice")
check(storage.razi_expedition_journal[1].story_unread["corp-epilogue"],
  "Victory epilogue must become unread for the player")
notices.on_research{research={name="logistic-science-pack",force=recipient}}
game.tick=500;notices.flush()
check(#a==4,"Human correspondence should still respect quiet batching")
game.tick=630;notices.flush()
check(#a==5 and a[5][1]=="razi-story.field-unlocked",
  "Personal field correspondence must have its own dispatch style")
check(storage.razi_expedition_journal[1].story_unread["corp-shift-roster"],
  "New field account must be tracked in the existing unread archive")
print("Journal research, world, shipment, merge, throttle and mute guards passed")
