-- Real industrial differences: saved inputs, faster throughput and
-- bounded high-volume alternatives, without rewriting source-mod recipes.
package.path="./?.lua;./?/init.lua;"..package.path
local p=require("prototypes.compat.industry_portfolio")
local function check(value,message) if not value then error(message,2) end end
local counts={catalytic=0,accelerated=0,bulk=0}
local total=0
for name in pairs(p.retained) do
  local profile=p.profile(name)
  check(profile and counts[profile.kind]~=nil,
    "Curated freight recipe lacks a useful industrial identity: "..name)
  counts[profile.kind]=counts[profile.kind]+1
  total=total+1
  if profile.kind=="catalytic" then
    check(profile.conserve and profile.fraction>0 and profile.fraction<=0.12,
      "Catalyst must name a real native input and a small savings ceiling")
  end
end
check(total==11 and counts.catalytic==3 and
  counts.accelerated==5 and counts.bulk==3,
  "Eleven curated recipes should deliver three distinct kinds of benefit")
local catalyst=p.profile("razi-bio-rare-metal-casting")
local native={{type="fluid",name="kr-molten-rare-metals",amount=40},
  {type="item",name="stone",amount=2}}
local okay,saved=p.conserve(native,catalyst)
check(okay and saved==4 and native[1].amount==36
  and native[2].amount==2,
  "Imported bioflux should save native molten rare metals, not other goods")
local absent,saved_absent=p.conserve(
  {{type="item",name="kr-molten-rare-metals",amount=40}},catalyst)
check(not absent and saved_absent==0,
  "Catalytic target must match ingredient TYPE as well as name")
local tiny={{type="fluid",name="kr-molten-rare-metals",amount=3}}
local possible,small=p.conserve(tiny,catalyst)
check(possible and small==0 and tiny[1].amount==3,
  "Tiny batches must not gain free fractional/catalyst savings")
local shortcut=p.profile("razi-electrobiological-components")
local rate=p.time_multiplier(shortcut,4,4,3,1.12)
check(rate>=1.06 and 19/(16*rate)<=1.1700001
  and 19/(16*rate)>16/16,
  "Precision electronics should accelerate, never exceed the 17% cap")
local edge=p.time_multiplier(shortcut,1,4,1,1.15)
check(5/(4*edge)<=1.1700001,
  "Small native batches must also respect the speed cap")
local bulk=p.profile("razi-network-frame-vesta-foundations")
check(p.time_multiplier(bulk,10,4,8,1.12)==1.12,
  "Bulk output should preserve deliberate native machine pacing")
print("Exchange profiles: 3 catalysts, 5 accelerated, 3 bulk with guarded costs")
