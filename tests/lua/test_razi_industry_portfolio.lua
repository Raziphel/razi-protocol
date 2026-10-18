-- Synthetic runtime test for the read-only optional factory portfolio.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
package.loaded["scripts.razi_journal_industry"]={
  quests={
    {id="alliance-a",tech="razi-test-a",site="fulgora"},
    {id="alliance-b",tech="razi-test-b",site="aquilo"},
    {id="alliance-missing",tech="razi-test-missing",site="castra"}
  }
}
package.loaded["scripts.galactic_trade_catalog"]={
  state=function(tech)
    return {status=tech.researched and "researched" or
      tech.enabled==false and "disabled" or "ready"}
  end
}
prototypes={recipe={
  ["razi-test-a"]={name="razi-test-a"},
  ["razi-test-b"]={name="razi-test-b"}
}}
local module=require("scripts.razi_industry_portfolio")
local snapshot=module.snapshot({technologies={
  ["razi-test-a"]={researched=true,enabled=true},
  ["razi-test-b"]={researched=false,enabled=true},
  ["razi-test-missing"]={researched=false,enabled=true}
}},8)
check(snapshot.available==2,"Missing prototype was shown as a working recipe")
check(snapshot.researched==1 and snapshot.ready==1,
  "Research states were replaced with simulated output")
check(#snapshot.entries==2 and snapshot.entries[1].quest.id=="alliance-b",
  "Ready research should precede already completed research")
local limited=module.snapshot({technologies={
  ["razi-test-a"]={researched=true},
  ["razi-test-b"]={researched=false}
}},1)
check(#limited.entries==1 and limited.available==2,
  "Display limit must not change the installed recipe totals")
local empty=module.snapshot(nil,8)
check(empty.available==0 and #empty.entries==0,"Nil force did not fail safely")
-- Pass 6: near-term choices outrank equally ready late-network factories.
local journal=package.loaded["scripts.razi_journal_industry"]
journal.quests[#journal.quests+1]={
  id="alliance-first-example",tech="razi-frontier-test-silicon",site="moshine"}
journal.quests[#journal.quests+1]={
  id="alliance-middle-example",tech="razi-middle-test-coils",site="paracelsin"}
prototypes.recipe["razi-frontier-test-silicon"]={name="razi-frontier-test-silicon"}
prototypes.recipe["razi-middle-test-coils"]={name="razi-middle-test-coils"}
local ordered=module.snapshot({technologies={
  ["razi-test-a"]={researched=true,enabled=true},
  ["razi-test-b"]={researched=false,enabled=true},
  ["razi-frontier-test-silicon"]={researched=false,enabled=true},
  ["razi-middle-test-coils"]={researched=false,enabled=true}
}},8)
check(ordered.available==4 and ordered.tiers.first==1 and
  ordered.tiers.middle==1 and ordered.tiers.extended==2,
  "First/middle/extended summary must reflect installed prototypes")
check(ordered.entries[1].quest.id=="alliance-first-example" and
  ordered.entries[2].quest.id=="alliance-middle-example",
  "Near-term upgrades must precede distant equally ready upgrades")
check(ordered.entries[3].quest.id=="alliance-b",
  "Extended ready upgrade must precede previously researched technology")
print("Razi Industries Cargo portfolio: prototype/read-only guards passed")
