-- Razi difficulty integration for Big Monsters' actual
-- "bm-big-enemy-hp-multiplier" startup setting (source default 1, 0.2..10).
--
-- Its owner reads the setting in data.lua, too early for Razi to change the
-- saved value. Reconcile only verified Big-Monsters-owned boss HP prototypes
-- after the source has built them, preserving other mods' prior adjustments.
-- Do not touch attacks, event chances, thresholds, generic biters or belts.
local M={}
M.profiles={easy=0.8,hard=1.2,nightmare=1.5}
M.owner="Big-Monsters"
M.setting="bm-big-enemy-hp-multiplier"

-- Names verified against the 2.1.2 public source mirror. Guard all missing
-- entities since the mod portal release is now 2.2.1, not the mirror release.
local function boss_unit(name)
 return type(name)=="string" and (
   name:match("^biterzilla[123]%d+$") or
   name:match("^bm%-motherbiterzilla%d+$") or
   name:match("^maf%-giant%-fire%-spitter%d+$") or
   name:match("^maf%-giant%-acid%-spitter%d+$")
 )~=nil
end
local function boss_spider(name)
 return type(name)=="string" and name:match("^bm%-spidertron_%d+$")~=nil
end
local boss_worms={
 ["maf-behemoth-worm-turret"]=true,
 ["maf-colossal-worm-turret"]=true,
 ["maf-worm-boss-fire-shooter"]=true,
 ["bm-worm-boss-acid-shooter"]=true,
}
local originals=setmetatable({},{__mode="k"})
local function valid(v)
 return type(v)=="number" and v>0 and v==v and v<math.huge
end
local function adjust(proto,factor)
 if type(proto)~="table" or not valid(proto.max_health) then return false end
 local original=originals[proto]
 if original==nil then original=proto.max_health;originals[proto]=original end
 local target=math.max(1,math.floor(original*factor+0.5))
 if proto.max_health==target then return false end
 proto.max_health=target
 return true
end
function M.apply(raw,startup,enabled)
 raw=raw or (data and data.raw) or {}
 startup=startup or (settings and settings.startup) or {}
 enabled=enabled or mods or {}
 local selected=startup["razi-difficulty-preset"]
 local target=M.profiles[selected and selected.value]
 local counts={units=0,spiders=0,worms=0,volcanoes=0}
 -- Both Normal and Custom are strict no-ops regardless of manual settings.
 if not target or not enabled[M.owner] then return counts end
 local source=startup[M.setting]
 local saved=source and source.value
 if not valid(saved) or saved<0.2 or saved>10 then return counts end
 local factor=target/saved
 for name,proto in pairs(raw.unit or {}) do
  if boss_unit(name) and adjust(proto,factor) then
   counts.units=counts.units+1
  end
 end
 for name,proto in pairs(raw["spider-vehicle"] or {}) do
  if boss_spider(name) and adjust(proto,factor) then
   counts.spiders=counts.spiders+1
  end
 end
 for name,proto in pairs(raw.turret or {}) do
  if boss_worms[name] and adjust(proto,factor) then
   counts.worms=counts.worms+1
  end
 end
 local volcano=raw["unit-spawner"] and raw["unit-spawner"]["bm-volcano"]
 if volcano and adjust(volcano,factor) then counts.volcanoes=1 end
 return counts
end
function M.data_final_fixes()
 return M.apply(data.raw,settings.startup,mods)
end
return M
