-- Console commands, registered in this order.
local razi_safe_cheat = require("scripts.commands.safe_cheat")
local writer = require("scripts.story.writer")
local welcome = require("scripts.story.welcome")
local convergence_audit = require("scripts.convergence.audit")
local victory_guard = require("scripts.convergence.victory_guard")

local command_list = {}

function command_list.register()
	commands.add_command("razi-cheat", {"razi-cheat.help"}, razi_safe_cheat.command)
	commands.add_command("razi-welcome", welcome.help(), welcome.command)
	commands.add_command("razi-writer", {"razi-writer.command-help"}, writer.command)
	commands.add_command("razi-audit", {"razi-audit.help"}, convergence_audit.command)
	-- Explicit diagnostic only. Never scans recipes, labs or source mods on ticks.
	commands.add_command("razi-victory-audit", {"razi-audit.victory-help"}, victory_guard.command)
end

return command_list
