-- Planetaris technologies that wait for a craft are triggered by the crafted item.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local set_craft_trigger = helpers.set_craft_trigger

local glass_craft_triggers = {}

function glass_craft_triggers.data_final_fixes()
	-- Planetaris Arig/Tellus still exposes a few trigger-techs whose recipe names
	-- read like "glass panel" steps even though the crafts themselves produce the
	-- generic `glass` item. Trigger on the crafted item result directly so the
	-- Arig chain advances no matter which source recipe provided the glass.
	set_craft_trigger("planetaris-compression", "kr-glass", 50)
	set_craft_trigger("planetaris-raw-diamond-production", "kr-quartz", 50)
	set_craft_trigger("condensing-agricultural-tower", "kr-glass", 25)
end

return glass_craft_triggers
