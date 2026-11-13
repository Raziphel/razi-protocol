-- Reversing research redraws the Journal without recording a completion.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local handlers = {}
local events = {
	on_research_finished = "research-finished",
	on_research_reversed = "research-reversed",
	on_technology_effects_reset = "technology-effects-reset",
	on_forces_merged = "forces-merged",
	on_force_created = "force-created",
}
rawset(_G, "defines", {events = events})

local defer_calls = {}
local on_research_calls = 0
package.loaded["scripts.journal.journal"] = {
	defer_research_refresh = function(force)
		defer_calls[#defer_calls + 1] = force
	end,
	on_research = function()
		on_research_calls = on_research_calls + 1
	end,
}
package.loaded["scripts.projects.platform_projects"] = {}
package.loaded["scripts.projects.great_projects"] = {}
package.loaded["scripts.convergence.deep_space_expedition"] = {}
package.loaded["lib.story"] = {dispatch = {}}
package.loaded["scripts.journal.spoiler_fog"] = {
	sync_force = function() end,
	defer = function() end,
}
package.loaded["scripts.convergence.convergence"] = {}

local force = {name = "player"}
local registry = {
	on_event = function(_, event_id, handler)
		handlers[event_id] = handler
	end,
}
require("scripts.events.forces").register(registry)

local reversed = handlers[defines.events.on_research_reversed]
check(type(reversed) == "function", "research-reversed handler is registered")
reversed({research = {force = force}})

check(#defer_calls == 1 and defer_calls[1] == force,
	"reversing research schedules a Journal refresh for the affected force")
check(on_research_calls == 0, "reversing research must not record a chapter completion")

print("test_research_reversed: ok")
