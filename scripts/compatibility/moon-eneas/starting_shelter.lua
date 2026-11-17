-- moon-eneas 1.0.10 replaces the starting items of freeplay with its own set (prototypes/scripts/inventory.lua:1-12, on
-- init and at every configuration change) instead of adding to it, and Krastorio 2 adds its shelter before it: a new
-- game starts without the shelter. It is added again after both; razi-protocol loads after them.
local starting_shelter = {}

function starting_shelter.restore()
	if not (remote.interfaces["freeplay"] and script.active_mods["moon-eneas"] and prototypes.item["kr-shelter"]) then
		return
	end

	local ok, items = pcall(function() return remote.call("freeplay", "get_created_items") end)
	if ok and type(items) == "table" and not items["kr-shelter"] then
		items["kr-shelter"] = 1
		pcall(function() remote.call("freeplay", "set_created_items", items) end)
	end
end

return starting_shelter
