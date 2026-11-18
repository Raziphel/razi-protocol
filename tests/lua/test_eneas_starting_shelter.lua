---@diagnostic disable: missing-fields, lowercase-global, need-check-nil
-- The Krastorio 2 shelter is put back into the starting items that moon-eneas replaces.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, why) if not ok then error(why, 2) end end

local shelter = require("scripts.compatibility.moon-eneas.starting_shelter")

local created
local function world(mods, has_shelter, items)
	created = items
	rawset(_G, "script", { active_mods = mods })
	rawset(_G, "prototypes", { item = has_shelter and { ["kr-shelter"] = {} } or {} })
	rawset(_G, "remote", {
		interfaces = { freeplay = {} },
		call = function(_, name, value)
			if name == "get_created_items" then return created end
			created = value
		end,
	})
end

world({ ["moon-eneas"] = "1.0.10" }, true, { ["iron-plate"] = 8 })
shelter.restore()
check(created["kr-shelter"] == 1 and created["iron-plate"] == 8, "The shelter joins the Eneas items")

world({ ["moon-eneas"] = "1.0.10" }, true, { ["kr-shelter"] = 2 })
shelter.restore()
check(created["kr-shelter"] == 2, "A shelter already there is kept as it is")

world({}, true, { ["iron-plate"] = 8 })
shelter.restore()
check(created["kr-shelter"] == nil, "Without Eneas the starting items are left alone")

world({ ["moon-eneas"] = "1.0.10" }, false, { ["iron-plate"] = 8 })
shelter.restore()
check(created["kr-shelter"] == nil, "Without the shelter item nothing is added")

print("test_eneas_starting_shelter: ok")
