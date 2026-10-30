-- Cards and platforms saved in 2.x come back after the update to 3.0.
-- Run from the mod root: lua5.2 tests/lua/test_prepared_2x.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

rawset(_G, "defines", {inventory = {lab_input = 1}})
local logged = {}
rawset(_G, "log", function(message) logged[#logged + 1] = message end)

local function make_inventory(capacity, accept)
	local inventory = {items = {}, capacity = capacity}
	function inventory.insert(stack)
		if accept and not accept[stack.name] then
			return 0
		end
		local used = 0
		for _, count in pairs(inventory.items) do
			used = used + count
		end
		local n = math.min(stack.count, inventory.capacity - used)
		local key = stack.name .. "/" .. stack.quality
		inventory.items[key] = (inventory.items[key] or 0) + n
		return n
	end
	return inventory
end

---@return any
local function world()
	local messages, spilled, created = {}, {}, {}
	local force = {name = "player", valid = true, platforms = {},
		print = function(message) messages[#messages + 1] = message end}
	local admin_messages = {}
	---@type any
	local surface
	surface = {name = "nauvis", labs = {},
		find_entity = function(name, position)
			return surface.labs[name .. ":" .. position.x .. ":" .. position.y]
		end,
		-- Positional like the real call: name, center, radius, precision.
		find_non_colliding_position = function(name, center, radius, precision)
			check(name == "steel-chest" and radius and precision, "find_non_colliding_position arguments")
			if surface.no_room then
				return nil
			end
			return {x = center.x + 2, y = center.y}
		end,
		create_entity = function(args)
			local chest = {valid = true, name = args.name, position = args.position, force = args.force,
				inventory = make_inventory(surface.chest_capacity or 100)}
			chest.insert = chest.inventory.insert
			created[#created + 1] = chest
			return chest
		end,
		spill_item_stack = function(args) spilled[#spilled + 1] = args end}
	local admin = {admin = true, print = function(message) admin_messages[#admin_messages + 1] = message end}
	local guest = {admin = false, print = function() error("guests get no message") end}
	rawset(_G, "game", {tick = 1, forces = {player = force}, surfaces = {nauvis = surface},
		players = {admin, guest}})
	local connections = {}
	rawset(_G, "prototypes", {space_location = {nauvis = {}, vulcanus = {}, fulgora = {}}, space_connection = connections})
	rawset(_G, "storage", {})
	return {connections = connections, force = force, surface = surface, messages = messages, spilled = spilled, created = created,
		admin_messages = admin_messages}
end

---@param w any
local function add_lab(w, name, x, y, accepts, capacity)
	local inventory = make_inventory(capacity or 100, accepts)
	local lab = {valid = true, name = name, force = w.force, position = {x = x, y = y},
		prototype = {lab_inputs = (function()
			local list = {}
			for input in pairs(accepts) do list[#list + 1] = input end
			return list
		end)()},
		get_inventory = function() return inventory end}
	w.surface.labs[name .. ":" .. x .. ":" .. y] = lab
	return lab, inventory
end

local function add_platform(w, index, name, location)
	-- The module reads a prototype and writes a name, like the real property.
	local platform = {valid = true, index = index, name = name, space_location = location and {name = location}}
	w.force.platforms[index] = platform
	return platform
end

local function prepared(labs, platforms)
	return {version = 1, tick = 5, labs = labs or {}, platforms = platforms or {}}
end

local function update(from)
	return {mod_changes = {["razi-protocol"] = {old_version = from, new_version = "3.0.0"}}}
end

local function where(platform)
	local location = platform.space_location
	return type(location) == "table" and location.name or location
end

local M = require("scripts.razi_prepared_2x")

-- Accepted cards go into the lab, the rest into a steel chest next to it; quality is kept.
do
	local w = world()
	local _, inventory = add_lab(w, "lab", 10, 20, {["calidus-tech-card"] = true, ["solaris-tech-card"] = true})
	w.surface.chest_capacity = 100
	storage.razi_prepare_3 = prepared({{
		surface = "nauvis", position = {x = 10, y = 20}, name = "lab", force = "player",
		items = {
			{name = "solaris-tech-card", quality = "rare", count = 5},
			{name = "vibrant-tech-card", quality = "normal", count = 3},
			{name = "umbra-tech-card", quality = "epic", count = 2}
		}}})
	M.on_configuration_changed(update("2.1.6"))
	check(inventory.items["solaris-tech-card/rare"] == 5, "accepted card goes into the lab with its quality")
	check(inventory.items["vibrant-tech-card/normal"] == nil, "rejected card stays out of the lab")
	check(#w.created == 1, "one chest for both rejected stacks")
	---@type any
	local chest = w.created[1]
	check(chest.name == "steel-chest" and chest.force == w.force, "steel chest of the lab's force")
	check(chest.inventory.items["vibrant-tech-card/normal"] == 3 and chest.inventory.items["umbra-tech-card/epic"] == 2,
		"rejected cards in the chest")
	check(storage.razi_prepare_3 == nil, "data cleared")
	check(#w.messages == 1 and w.messages[1][2] == 5 and w.messages[1][3] == 5, "summary for the force")
	check(#w.spilled == 0, "nothing on the ground")

	-- A second run changes nothing.
	local before = #w.created
	M.on_configuration_changed(update("2.1.6"))
	check(#w.created == before and inventory.items["solaris-tech-card/rare"] == 5, "second run does nothing")
	check(#w.admin_messages == 1, "second run: the not-prepared notice (no data any more)")
end

-- A full lab and a full chest: the rest is spilled for the force.
do
	local w = world()
	local _, inventory = add_lab(w, "lab", 0, 0, {["calidus-tech-card"] = true}, 2)
	w.surface.chest_capacity = 1
	storage.razi_prepare_3 = prepared({{
		surface = "nauvis", position = {x = 0, y = 0}, name = "lab", force = "player",
		items = {{name = "calidus-tech-card", quality = "normal", count = 4}}}})
	M.on_configuration_changed(update("2.1.5"))
	check(inventory.items["calidus-tech-card/normal"] == 2, "lab takes what fits")
	check(w.created[1].inventory.items["calidus-tech-card/normal"] == 1, "chest takes one")
	check(#w.spilled == 1 and w.spilled[1].stack.count == 1 and w.spilled[1].force == w.force, "the rest on the ground")
end

-- No room for a chest: everything on the ground.
do
	local w = world()
	w.surface.no_room = true
	storage.razi_prepare_3 = prepared({{
		surface = "nauvis", position = {x = 1, y = 1}, name = "lab", force = "player",
		items = {{name = "umbra-tech-card", quality = "normal", count = 6}}}})
	M.on_configuration_changed(update("2.2.0"))
	check(#w.spilled == 1 and w.spilled[1].stack.count == 6, "no chest: spilled")
end

-- The lab is gone: everything into a chest at its place.
do
	local w = world()
	storage.razi_prepare_3 = prepared({{
		surface = "nauvis", position = {x = 7, y = 8}, name = "lab", force = "player",
		items = {{name = "vibrant-tech-card", quality = "normal", count = 4}}}})
	M.on_configuration_changed(update("2.1.6"))
	check(#w.created == 1 and w.created[1].inventory.items["vibrant-tech-card/normal"] == 4, "lab missing: chest")
	check(math.abs(w.created[1].position.x - 9) < 0.01, "chest near the old lab position")
end

-- Platforms: stopped and in flight.
do
	local w = world()
	local stopped = add_platform(w, 1, "stopped", "fulgora")
	local flight = add_platform(w, 2, "near-start", "nauvis")
	local flight_end = add_platform(w, 3, "near-end", "nauvis")
	local gone = add_platform(w, 4, "no-place", "nauvis")
	local fine = add_platform(w, 5, "fine", "vulcanus")
	storage.razi_prepare_3 = prepared({}, {
		{force = "player", index = 1, name = "stopped", space_location = "vulcanus"},
		{force = "player", index = 2, name = "near-start", connection = {name = "gone-route", from = "vulcanus", to = "fulgora", distance = 0.2}},
		{force = "player", index = 3, name = "near-end", connection = {name = "gone-route", from = "vulcanus", to = "fulgora", distance = 0.7}},
		{force = "player", index = 4, name = "no-place", connection = {name = "gone-route", from = "ghost-a", to = "ghost-b", distance = 0.1}},
		{force = "player", index = 5, name = "fine", space_location = "vulcanus"},
		{force = "player", index = 6, name = "deleted", space_location = "vulcanus"}
	})
	M.on_configuration_changed(update("2.1.6"))
	check(where(stopped) == "vulcanus", "stopped platform returned")
	check(where(flight) == "vulcanus", "flight start side")
	check(where(flight_end) == "fulgora", "flight end side")
	check(where(gone) == "nauvis", "unknown places: left as it is")
	check(where(fine) == "vulcanus", "already in place")
	check(w.messages[1][5] == 3 and w.messages[1][6] == 2, "3 moved, 2 not solved")
end

-- A route that still exists keeps its flight untouched.
do
	local w = world()
	local p = add_platform(w, 1, "flying", "nauvis")
	w.connections["alive"] = {}
	storage.razi_prepare_3 = prepared({}, {
		{force = "player", index = 1, name = "flying", connection = {name = "alive", from = "vulcanus", to = "fulgora", distance = 0.2}}})
	M.on_configuration_changed(update("2.1.6"))
	check(where(p) == "nauvis", "existing route: platform not moved")
end

-- Only the move from 2.x to 3.x counts.
do
	local w = world()
	local _, inventory = add_lab(w, "lab", 0, 0, {["calidus-tech-card"] = true})
	local data = prepared({{surface = "nauvis", position = {x = 0, y = 0}, name = "lab", force = "player",
		items = {{name = "calidus-tech-card", quality = "normal", count = 1}}}})
	storage.razi_prepare_3 = data
	M.on_configuration_changed(update("3.0.1"))
	M.on_configuration_changed({mod_changes = {["other-mod"] = {old_version = "2.0.0"}}})
	M.on_configuration_changed({mod_changes = {["razi-protocol"] = {new_version = "3.0.0"}}})
	M.on_configuration_changed({})
	check(storage.razi_prepare_3 == data and next(inventory.items) == nil, "not a 2.x update: data kept, nothing done")
	check(#w.admin_messages == 0, "not a 2.x update: no notice")
end

-- 2.x update without preparation: one notice to admins only.
do
	local w = world()
	M.on_configuration_changed(update("2.1.6"))
	check(#w.admin_messages == 1 and w.admin_messages[1][1] == "razi-prepared-2x.not-prepared", "notice to admins")
	check(#w.messages == 0 and #w.created == 0, "nothing else happens")
end

print("test_prepared_2x: ok")
