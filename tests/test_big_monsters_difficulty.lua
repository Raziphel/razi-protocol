-- texlua tests/test_big_monsters_difficulty.lua
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("prototypes.compat.big_monsters_difficulty")
local startup={
 ["razi-difficulty-preset"]={value="normal"},
 ["bm-big-enemy-hp-multiplier"]={value=2},
 ["bm-big-enemy-hp-variant"]={value=1.7},
 ["bm-enemy-damage-multiplier"]={value=4},
}
local enabled={["Big-Monsters"]="2.2.1"}
local raw={
 unit={
  ["biterzilla11"]={max_health=3000},
  ["biterzilla22"]={max_health=4000},
  ["biterzilla35"]={max_health=6000},
  ["bm-motherbiterzilla4"]={max_health=2000},
  ["maf-giant-fire-spitter3"]={max_health=1000},
  ["maf-giant-acid-spitter2"]={max_health=1500},
  ["biter-spawner"]={max_health=2000},
  ["other-mod-biterzilla11"]={max_health=300},
 },
 ["spider-vehicle"]={
  ["bm-spidertron_3"]={max_health=9000},
  ["player-spidertron"]={max_health=3000},
 },
 turret={
  ["maf-behemoth-worm-turret"]={max_health=40000},
  ["maf-colossal-worm-turret"]={max_health=80000},
  ["maf-worm-boss-fire-shooter"]={max_health=30000},
  ["bm-worm-boss-acid-shooter"]={max_health=25000},
  ["behemoth-worm-turret"]={max_health=3000},
 },
 ["unit-spawner"]={
  ["bm-volcano"]={max_health=40000},
  ["biter-spawner"]={max_health=350},
 },
}
local function apply(mode,source,owners)
 startup["razi-difficulty-preset"].value=mode
 if source then startup["bm-big-enemy-hp-multiplier"].value=source end
 return M.apply(raw,startup,owners or enabled)
end
local function total(c) return c.units+c.spiders+c.worms+c.volcanoes end
assert(total(apply("normal"))==0,"Normal must be an absolute no-op")
assert(raw.unit.biterzilla11.max_health==3000)
assert(total(apply("custom"))==0,"Custom must be an absolute no-op")
local e=apply("easy")
assert(e.units==6 and e.spiders==1 and e.worms==4 and e.volcanoes==1)
assert(raw.unit.biterzilla11.max_health==1200)
assert(raw["spider-vehicle"]["bm-spidertron_3"].max_health==3600)
assert(raw.turret["maf-behemoth-worm-turret"].max_health==16000)
assert(raw["unit-spawner"]["bm-volcano"].max_health==16000)
assert(total(apply("easy"))==0,"Repeated passes must not compound")
assert(raw.unit["other-mod-biterzilla11"].max_health==300)
assert(raw.unit["biter-spawner"].max_health==2000)
assert(raw.turret["behemoth-worm-turret"].max_health==3000)
assert(raw["spider-vehicle"]["player-spidertron"].max_health==3000)
assert(raw["unit-spawner"]["biter-spawner"].max_health==350)
assert(startup["bm-big-enemy-hp-multiplier"].value==2)
assert(startup["bm-big-enemy-hp-variant"].value==1.7)
assert(startup["bm-enemy-damage-multiplier"].value==4)
assert(total(apply("hard"))==12)
assert(raw.unit.biterzilla11.max_health==1800)
assert(total(apply("nightmare"))==12)
assert(raw.unit.biterzilla11.max_health==2250)
assert(total(apply("normal"))==0)
assert(raw.unit.biterzilla11.max_health==2250,
 "Changing startup difficulty requires a reload; Normal never writes.")
-- A fresh normal run with manual source multiplier 3 must remain as-is.
local fresh={unit={biterzilla11={max_health=6000}}}
startup["razi-difficulty-preset"].value="normal"
startup["bm-big-enemy-hp-multiplier"].value=3
assert(total(M.apply(fresh,startup,enabled))==0)
assert(fresh.unit.biterzilla11.max_health==6000)
-- Missing source mod or setting and invalid values must fail closed.
startup["razi-difficulty-preset"].value="hard"
assert(total(M.apply(fresh,startup,{}))==0)
startup["bm-big-enemy-hp-multiplier"].value=0
assert(total(M.apply(fresh,startup,enabled))==0)
startup["bm-big-enemy-hp-multiplier"].value="bad"
assert(total(M.apply(fresh,startup,enabled))==0)
assert(total(M.apply({},startup,enabled))==0)
print("Big Monsters numeric source HP: selected bosses only, Normal unchanged PASS")
