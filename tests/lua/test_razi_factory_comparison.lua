-- Cargo Network: grounded factory comparison only, never fictitious freight.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local tool=require("scripts.razi_factory_comparison")
local native={products={{type="item",name="silicon-cell",amount=3},
                         {type="fluid",name="spent-acid",amount=2}},
  ingredients={{type="item",name="iron-plate",amount=2}}}
local improved={products={{type="item",name="silicon-cell",amount=15},
                           {type="fluid",name="spent-acid",amount=8}},
  ingredients={{type="item",name="iron-plate",amount=8},
               {type="item",name="optical-cable",amount=2},
               {type="item",name="rare-metals",amount=1}}}
local recipes={["silicon-cell"]=native,
  ["razi-frontier-moshine-biometal-silicon"]=improved}
local summary=tool.compare("razi-frontier-moshine-biometal-silicon",recipes)
check(summary and summary.baseline==12 and summary.output==15,
  "Native four-batch output is incorrect")
check(summary.bonus_percent==25,"Gross percentage must be source-backed")
check(#summary.additional==2 and summary.additional[1].name=="optical-cable",
  "Additional ingredients should be deterministic and sorted")
check(tool.compare("razi-never-installed",recipes)==nil,
  "Unknown recipes must not claim an output bonus")
local reduced={products=improved.products,ingredients={{
  type="item",name="iron-plate",amount=7}}}
recipes["razi-frontier-moshine-biometal-silicon"]=reduced
check(tool.compare("razi-frontier-moshine-biometal-silicon",recipes)==nil,
  "Reduced original ingredients must never be advertised as value")
recipes["razi-frontier-moshine-biometal-silicon"]={
  products={{type="item",name="silicon-cell",amount=15}},
  ingredients=improved.ingredients}
check(tool.compare("razi-frontier-moshine-biometal-silicon",recipes)==nil,
  "Dropped source byproducts must invalidate the comparison")
recipes["razi-frontier-moshine-biometal-silicon"]={
  products={{type="item",name="silicon-cell",amount=15,probability=.5},
            {type="fluid",name="spent-acid",amount=8}},
  ingredients=improved.ingredients}
check(tool.compare("razi-frontier-moshine-biometal-silicon",recipes)==nil,
  "Random outputs cannot be shown as a fixed bonus")
print("Source-backed factory comparison guards passed")
