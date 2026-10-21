-- texlua tests/test_xy_inflation_difficulty.lua
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("prototypes.compat.xy_inflation_difficulty")
local startup={
 ["razi-difficulty-preset"]={value="normal"},
 ["xy-tech-inflation"]={value=true},
 ["xy-tech-inflation-scale"]={value="50%"},
}
local enabled={["xy-k2so-enhancements-nulls-fork"]="0.8.5"}
local raw={technology={
 ["legendary-quality"]={unit={count=300}},
 ["kr-intergalactic-transceiver"]={unit={count=1000}},
 ["biolab"]={unit={count=40}},
 ["unrelated-tech"]={unit={count=77}},
}}
local function mode(v)
 startup["razi-difficulty-preset"].value=v
 return M.apply(raw,startup,enabled)
end
assert(mode("normal")==0)
assert(raw.technology["legendary-quality"].unit.count==300)
assert(mode("easy")==3)
assert(raw.technology["legendary-quality"].unit.count==450)
assert(raw.technology["kr-intergalactic-transceiver"].unit.count==1500)
assert(raw.technology.biolab.unit.count==60)
assert(raw.technology["unrelated-tech"].unit.count==77)
assert(mode("easy")==0,"idempotent")
assert(mode("hard")==3)
assert(raw.technology["legendary-quality"].unit.count==900)
assert(mode("nightmare")==3)
assert(raw.technology["legendary-quality"].unit.count==1200)
assert(mode("normal")==0,"Normal never changes values")
assert(mode("custom")==0,"Custom never changes values")
assert(raw.technology["legendary-quality"].unit.count==1200)
startup["razi-difficulty-preset"].value="hard"
assert(M.apply(raw,startup,{})==0,"source mod disabled")
startup["xy-tech-inflation"].value=false
assert(M.apply(raw,startup,enabled)==0,"source feature disabled")
startup["xy-tech-inflation"].value=true
startup["xy-tech-inflation-scale"].value="unknown"
assert(M.apply(raw,startup,enabled)==0,"unrecognized source setting skipped")
local fresh={technology={["legendary-quality"]={unit={count=333}}}}
startup["xy-tech-inflation-scale"].value="50%"
startup["razi-difficulty-preset"].value="normal"
assert(M.apply(fresh,startup,enabled)==0)
assert(fresh.technology["legendary-quality"].unit.count==333)
print("XY numeric inflation: 10 source technologies only, Normal unchanged PASS")
