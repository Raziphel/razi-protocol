-- Quality carrier asteroids.
local quality_asteroids = require("scripts.asteroids.quality")

local asteroids = {}

function asteroids.register(events)
	-- Only the quality carrier asteroids raise this effect: no scanning and no ticking.
	events:on_event(defines.events.on_script_trigger_effect, quality_asteroids.on_script_trigger_effect)
end

return asteroids
