local adjust_maraxsis = data.raw["bool-setting"] and data.raw["bool-setting"]["adjust-maraxsis"]

if adjust_maraxsis then
	adjust_maraxsis.default_value = false
	adjust_maraxsis.forced_value = false
	adjust_maraxsis.hidden = true
end

-- Big-Monsters defaults to six in-game days between events. RP3 prefers
-- the optional event interval to start at zero for NEW games only.
-- This is runtime-global: changing the prototype default does not replace
-- a player's existing save setting, and the slider remains editable.
-- Big-Monsters 2.2.1 defines bm-event-days as an int-setting (min 0).
local big_monsters_interval = data.raw["int-setting"]
  and data.raw["int-setting"]["bm-event-days"]
if mods and mods["Big-Monsters"] and big_monsters_interval
  and big_monsters_interval.setting_type == "runtime-global"
  and (big_monsters_interval.minimum_value or 0) <= 0
  and (big_monsters_interval.maximum_value or 0) >= 0 then
  big_monsters_interval.default_value = 0
end
