---@diagnostic disable: need-check-nil
-- The fleet summary of the Cargo Network project: which platforms count, which have no schedule and which are
-- travelling.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local fleet = require("scripts.cargo.fleet")

-- A platform as the game gives it: reading a field that does not exist is an error.
local function platform(fields)
	local values = {
		valid = true, hidden = false, scheduled_for_deletion = 0, schedule = nil, space_connection = nil,
	}
	for key, value in pairs(fields or {}) do
		values[key] = value
	end
	return setmetatable({}, {
		__index = function(_, key)
			if values[key] == nil and not ({ schedule = true, space_connection = true })[key] then
				error("Unknown property of LuaSpacePlatform: " .. tostring(key))
			end
			return values[key]
		end,
	})
end

local research = { name = "interplanetary-trade-logistics", researched = false }
local force = {
	technologies = { ["interplanetary-trade-logistics"] = research },
	platforms = {
		[1] = platform({ schedule = { records = { {} } } }),
		[2] = platform(),
		[3] = platform({ schedule = { records = {} } }),
		[4] = platform({ schedule = { records = { {} } }, space_connection = {} }),
		[5] = platform({ hidden = true }),
		[6] = platform({ scheduled_for_deletion = 120 }),
		[7] = platform({ valid = false }),
	},
}

local facts = fleet.snapshot(force)
check(facts.platforms == 4, "platforms: " .. facts.platforms .. " (hidden, deleted and invalid ones do not count)")
check(facts.unscheduled == 2, "unscheduled: " .. facts.unscheduled .. " (no schedule and empty records)")
check(facts.in_transit == 1, "in transit: " .. facts.in_transit)
check(facts.research == research and facts.unlocked == false, "the research is not done")

research.researched = true
check(fleet.snapshot(force).unlocked == true, "the research is done")

force.technologies = {}
facts = fleet.snapshot(force)
check(facts.research == nil and facts.unlocked == false, "a missing technology is not unlocked")

force.platforms = {}
facts = fleet.snapshot(force)
check(facts.platforms == 0 and facts.unscheduled == 0 and facts.in_transit == 0, "no platforms")

print("test_cargo_fleet: ok")
