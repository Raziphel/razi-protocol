-- Players joining, being created and being removed.
local razi_safe_cheat = require("scripts.commands.safe_cheat")
local razi_journal = require("scripts.journal.journal")
local story = require("lib.story")
local welcome = require("scripts.story.welcome")
local cargo_orders = require("scripts.cargo.orders")

local players = {}

function players.register(events)
	events:on_event(defines.events.on_player_removed, function(event)
		razi_journal.on_removed(event.player_index)
		razi_safe_cheat.on_player_removed(event.player_index)
		welcome.on_player_removed(event.player_index)
		story.on_removed(event.player_index)
		cargo_orders.cleanup(event.player_index)
	end)
	events:on_event(defines.events.on_player_joined_game, function(event)
		local player = game.get_player(event.player_index)
		if player then
			razi_journal.sync(player)
			welcome.on_player_joined(player)
		end
	end)
	events:on_event(defines.events.on_player_created, function(event)
		local player = game.get_player(event.player_index)
		if player then
			razi_journal.sync(player)
			welcome.on_player_created(player)
		end
	end)
end

return players
