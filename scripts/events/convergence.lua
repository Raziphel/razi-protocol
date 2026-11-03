-- Convergence: the once-per-second advance of the force transmissions.
local razi_journal = require("scripts.journal.journal")
local convergence = require("scripts.convergence.convergence")
local victory_guard = require("scripts.convergence.victory_guard")

local convergence_events = {}

function convergence_events.register(events)
	-- An idle Convergence has no pending work. Active force transmissions
	-- advance once per second and only redraw their open final panels.
	events:on_nth_tick(60, function(event)
		-- An unknown source mod may call native victory directly. Official
		-- opt-outs prevent known triggers; this heals a stray state on the
		-- next simulation tick without erasing inherited or Razi victories.
		victory_guard.recover_unexpected()
		local changed = convergence.advance(event.tick)
		if changed then
			for _, index in ipairs(changed) do
				local force = game.forces[index]
				if force then
					razi_journal.refresh_convergence(force)
				end
			end
		end
	end)
end

return convergence_events
