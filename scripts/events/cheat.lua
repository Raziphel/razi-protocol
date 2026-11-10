-- Staged research (/razi-cheat) and the notice about the built-in /cheat.
local razi_safe_cheat = require("scripts.commands.safe_cheat")

local cheat = {}

function cheat.register(events)
	-- Spread debug research across ticks instead of freezing the whole modpack.
	-- Exits at once while no staged research is running.
	events:on_nth_tick(6, razi_safe_cheat.tick)
	-- /cheat is a built-in command and cannot be replaced. This notification
	-- runs only if the engine gets far enough to emit its console event.
	events:on_event(defines.events.on_console_command, razi_safe_cheat.warn_builtin)
	events:on_event(defines.events.on_player_joined_game, function(event)
		razi_safe_cheat.admin_tip(game.get_player(event.player_index))
	end)
end

return cheat
