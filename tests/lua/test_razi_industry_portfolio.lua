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
print("Razi Industries Cargo portfolio: prototype/read-only guards passed")
