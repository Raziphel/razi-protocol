-- Entity and Journal tick handlers coordinate a deferred Archive refresh.
package.path="./?.lua;./?/init.lua;"..package.path

local function check(value,message)
	if not value then error(message,2) end
end

local refreshes=0
package.loaded["scripts.journal.journal"]={
	refresh_open=function() refreshes=refreshes+1 end,
	flush_research_refreshes=function() end,
	refresh_nexus_visible=function() end,
	refresh_chapter_completions=function() end,
	refresh_systems_visible=function() end,
	refresh_research_visible=function() end
}
package.loaded["scripts.compatibility.Cerys-Moon-of-Fulgora.tower_lamp"]={
	filters=function() return {} end
}
package.loaded["scripts.journal.search_names"]={on_string_translated=function() return false end}
package.loaded["lib.story"]={dispatch={flush=function() end}}
package.loaded["scripts.journal.spoiler_fog"]={
	flush=function() end,sync_all=function() end,defer_all=function() end
}
package.loaded["scripts.story.welcome"]={flush=function() end}
package.loaded["scripts.convergence.victory_guard"]={enforce=function() end}

local event_ids=setmetatable({}, {__index=function(events,name)
	rawset(events,name,name)
	return name
end})
defines={events=event_ids}
storage={}

local handlers,tick_handlers={},{}
local events={
	on_event=function(_,ids,handler)
		if type(ids)~="table" then ids={ids} end
		for _,id in ipairs(ids) do handlers[id]=handler end
	end,
	on_nth_tick=function(_,interval,handler)
		tick_handlers[interval]=tick_handlers[interval] or {}
		tick_handlers[interval][#tick_handlers[interval]+1]=handler
	end
}

require("scripts.events.entities").register(events)
require("scripts.events.journal").register(events)

local remove=handlers[event_ids.on_player_mined_entity]
check(remove~=nil,"Archive relay removal handler must be registered")
local event={entity={valid=true,name="razi-archive-relay"}}
remove(event)
remove(event)
check(refreshes==0,"Removing the relay must defer the open Journal refresh")
check(storage.razi_archive_relay_refresh_pending==true,
	"Relay removal should leave a pending refresh flag in storage")

local thirty_tick=tick_handlers[30] and tick_handlers[30][1]
check(thirty_tick~=nil,"The 30-tick Journal pass must be registered")
thirty_tick()
check(refreshes==1 and storage.razi_archive_relay_refresh_pending==nil,
	"The next 30-tick pass should refresh once and clear the flag")
thirty_tick()
check(refreshes==1,"A cleared relay refresh flag must not refresh again")

print("runtime entities: Archive refresh deferred to the 30-tick Journal pass")
