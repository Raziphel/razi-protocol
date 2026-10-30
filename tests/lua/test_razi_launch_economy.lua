-- Rocket launch cost of the difficulty level: the rocket part crafts of every
-- silo prototype, Normal writes nothing, a second call never compounds.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
rawset(_G,"log",function() end)
local rocket=require("prototypes.compat.razi_launch_economy")
local resolver=require("scripts.razi_difficulty_presets")
local function selected(mode,overrides)
 local startup={["razi-difficulty-preset"]={value=mode}}
 for name,value in pairs(resolver.baseline) do startup[name]={value=value} end
 for name,value in pairs(overrides or {}) do startup[name]={value=value} end
 rawset(_G,"settings",{startup=startup})
end
local function silos()
 return {
  base={rocket_parts_required=50},
  capped={rocket_parts_required=50,rocket_parts_storage_cap=50},
  big={rocket_parts_required=150},
  no_second_bar={rocket_parts_required=80,rocket_parts_storage_cap=0},
  broken={rocket_parts_required=3,rocket_parts_storage_cap=1},
  unknown={},
 }
end

-- Normal changes nothing.
selected("normal")
local list=silos()
check(rocket.adjust(list,resolver)==0,"Normal must not touch a silo")
check(list.base.rocket_parts_required==50 and list.big.rocket_parts_required==150,
 "Normal changed the rocket parts")
check(list.base.rocket_parts_storage_cap==nil,"Normal added a storage cap")

-- Hard: every silo with a number of parts, each from its own value.
selected("hard")
list=silos()
check(rocket.adjust(list,resolver)==5,"Hard changes the five silos that have parts")
check(list.base.rocket_parts_required==65,"Hard: 50 -> 65")
check(list.big.rocket_parts_required==195,"Hard: 150 -> 195, the ratio of the silos stays")
check(list.base.rocket_parts_storage_cap==nil,
 "A silo without a cap gets none: the game derives it")
check(list.capped.rocket_parts_storage_cap==65,"The cap grows with the parts")
check(list.no_second_bar.rocket_parts_storage_cap==0,"Zero is a special cap")
check(list.broken.rocket_parts_storage_cap>=list.broken.rocket_parts_required,
 "A cap below the parts would stall the silo")
check(next(list.unknown)==nil,"A silo without parts stays as it is")
check(rocket.adjust(list,resolver)==0 and list.base.rocket_parts_required==65,
 "A second call must not compound")

-- Easy lowers the parts and never raises a cap.
selected("easy")
list=silos()
rocket.adjust(list,resolver)
check(list.base.rocket_parts_required==35,"Easy: 50 -> 35")
check(list.capped.rocket_parts_storage_cap==50,"A lower cost keeps the cap")

-- Nightmare, and a launch cost set by hand.
selected("nightmare")
list=silos()
rocket.adjust(list,resolver)
check(list.base.rocket_parts_required==83 and list.no_second_bar.rocket_parts_required==132,
 "Nightmare: 50 -> 83, 80 -> 132")
selected("normal",{["razi-rocket-launch-cost"]="costly"})
list=silos()
rocket.adjust(list,resolver)
check(list.base.rocket_parts_required==65,"A value set by hand applies")

-- No silos at all.
check(rocket.adjust(nil,resolver)==0,"Missing silo table")
print("Rocket launch cost passed")
