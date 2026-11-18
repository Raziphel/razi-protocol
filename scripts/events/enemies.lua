-- Enemy expansion: Castra Prime's tanks must not build vanilla nests on Castra.
local castra_expansion = require("scripts.compatibility.castra-prime.expansion_nests")

local enemies = {}

function enemies.register(events)
	events:on_event(defines.events.on_build_base_arrived, castra_expansion.on_build_base_arrived)
	events:on_event(defines.events.on_biter_base_built, castra_expansion.on_biter_base_built)
	-- New games have no such nests; a save made before this fix gets them removed once.
	events:on_configuration_changed(castra_expansion.clear_built_nests)
end

return enemies
