---@diagnostic disable: need-check-nil
-- Machines found at the ends of the corridors: placed launchers on the surface of a world and built platforms in
-- its orbit. Worlds without a surface are left out of the answer.
package.path = "./?.lua;./?/init.lua;" .. package.path
local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local infrastructure = require("scripts.cargo.infrastructure")

-- The game refuses an unknown field of a prototype; so does this mock.
local function prototype(kind)
	return setmetatable({}, {
		__index = function(_, key)
			check(key == "type", "Unknown property of LuaEntityPrototype: " .. tostring(key))
			return kind
		end,
	})
end
prototypes = {
	entity = {
		["orbital-cannon-launcher"] = prototype("assembling-machine"),
		["orbital-catapult-pad"] = prototype("container"),
		["orbital-cannon-decoration"] = prototype("simple-entity"),
		["steel-chest"] = prototype("container"),
	},
}

local names = infrastructure.launcher_names()
check(#names == 2 and names[1] == "orbital-cannon-launcher" and names[2] == "orbital-catapult-pad",
	"launcher names: " .. table.concat(names, ","))

local counted = {}
local function surface(count)
	return {
		valid = true,
		count_entities_filtered = function(filter)
			counted[#counted + 1] = filter
			return count
		end,
	}
end
local function platform(fields)
	local value = { valid = true, hidden = false, scheduled_for_deletion = 0, hub = { valid = true } }
	for key, field in pairs(fields or {}) do
		value[key] = field
	end
	return value
end
game = { surfaces = { nauvis = surface(3), vulcanus = surface(0) } }
local at = {
	nauvis = { platform(), platform({ hub = { valid = false } }), platform({ hidden = true }), platform() },
	vulcanus = {},
}
local force = {
	get_space_platforms = function(world)
		check(at[world], "platforms asked for " .. world)
		return at[world]
	end,
}

local found = infrastructure.inspect(force, { "nauvis", "vulcanus", "gleba" })
check(found.nauvis.launchers == 3 and found.nauvis.platforms == 2,
	"nauvis: " .. found.nauvis.launchers .. " launchers, " .. found.nauvis.platforms .. " platforms")
check(found.vulcanus.launchers == 0 and found.vulcanus.platforms == 0, "vulcanus is empty")
check(found.gleba == nil, "a world without a surface is not in the answer")
check(#counted == 2 and counted[1].force == force and #counted[1].name == 2, "one count per surface, of the launcher names")

-- At most eight worlds are looked at.
counted = {}
local many = {}
for index = 1, 12 do
	local world = "world" .. index
	game.surfaces[world] = surface(1)
	at[world] = {}
	many[index] = world
end
found = infrastructure.inspect(force, many)
check(#counted == 8 and found.world8 and not found.world9, "the count is bounded by eight worlds")

-- No launcher prototypes: no count on the surface.
prototypes.entity = { ["steel-chest"] = prototype("container") }
counted = {}
found = infrastructure.inspect(force, { "nauvis" })
check(#counted == 0 and found.nauvis.launchers == 0, "nothing to count without launcher prototypes")

print("test_cargo_infrastructure: ok")
