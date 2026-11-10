-- Takes back what /razi-prepare-3 saved in a 2.x save: the system tech cards
-- that were in laboratories, the positions of space platforms and the levels of infinite technologies.
-- Runs once, on the update from 2.x to 3.x, and only if the command was used.
local M = {}

local Names = require("lib.infinite_research_names")

local VERSION = 1
local INFINITE_VERSION = 1
-- The game's max_level of a technology with no end (uint32).
local INFINITE_LEVEL = 4294967295
local CHEST = "steel-chest"

local function is_update_from_2x(event)
	local change = event and event.mod_changes and event.mod_changes["razi-protocol"]
	local old = change and change.old_version
	return type(old) == "string" and old:sub(1, 2) == "2."
end

local function force_report(reports, name)
	local report = reports[name]
	if not report then
		report = {labs = 0, chests = 0, lost = 0, moved = 0, unsolved = 0}
		reports[name] = report
	end
	return report
end

local function accepted_inputs(lab)
	local accepted = {}
	local inputs = lab.prototype and lab.prototype.lab_inputs
	for _, name in pairs(inputs or {}) do
		accepted[name] = true
	end
	return accepted
end

-- One chest per lab record position, shared by every stack that does not fit the lab.
local function chest_for(surface, force, position, chests)
	local key = surface.name .. ":" .. position.x .. ":" .. position.y
	local chest = chests[key]
	if chest and chest.valid then
		return chest
	end
	local free = surface.find_non_colliding_position(CHEST, position, 8, 0.5)
	if not free then
		return nil
	end
	chest = surface.create_entity({name = CHEST, position = free, force = force})
	chests[key] = chest
	return chest
end

-- Puts a stack where the lab could not take it. Returns "chest" or "lost" (spilled on the ground).
local function stash(surface, force, position, stack, chests)
	local chest = chest_for(surface, force, position, chests)
	local left = stack.count
	if chest and chest.valid then
		left = left - chest.insert(stack)
		if left <= 0 then
			return "chest"
		end
	end
	surface.spill_item_stack({
		position = position,
		stack = {name = stack.name, count = left, quality = stack.quality},
		enable_looted = true,
		force = force,
		allow_belts = false
	})
	return "lost"
end

local function restore_lab(record, reports, chests)
	local force = game.forces[record.force]
	local report = force_report(reports, record.force)
	local surface = game.surfaces[record.surface]
	if not (surface and force) then
		for _, stack in ipairs(record.items) do
			report.unsolved = report.unsolved + stack.count
		end
		log("razi-prepared-2x: no surface " .. tostring(record.surface) .. " for a saved laboratory")
		return
	end

	local lab = surface.find_entity(record.name, record.position)
	if lab and not (lab.valid and lab.force == force) then
		lab = nil
	end
	local accepted = lab and accepted_inputs(lab) or {}
	local inventory = lab and lab.get_inventory(defines.inventory.lab_input)

	for _, stack in ipairs(record.items) do
		local left = stack.count
		if inventory and accepted[stack.name] then
			left = left - inventory.insert({name = stack.name, count = left, quality = stack.quality})
			report.labs = report.labs + (stack.count - left)
		end
		if left > 0 then
			local rest = {name = stack.name, count = left, quality = stack.quality}
			if stash(surface, force, record.position, rest, chests) == "chest" then
				report.chests = report.chests + left
			else
				report.lost = report.lost + left
			end
		end
	end
end

local function find_platform(force, record)
	local platform = force.platforms[record.index]
	if platform and platform.valid and platform.name == record.name then
		return platform
	end
	for _, other in pairs(force.platforms) do
		if other.valid and other.name == record.name then
			return other
		end
	end
end

local function location_exists(name)
	return name ~= nil and prototypes.space_location[name] ~= nil
end

local function restore_platform(record, reports)
	local force = game.forces[record.force]
	local report = force_report(reports, record.force)
	local platform = force and find_platform(force, record)
	if not platform then
		report.unsolved = report.unsolved + 1
		return
	end

	local target
	if record.connection then
		-- A flight on a route that is still there survives the update.
		if platform.space_connection or prototypes.space_connection[record.connection.name] then
			return
		end
		target = record.connection.distance < 0.5 and record.connection.from or record.connection.to
	else
		target = record.space_location
	end

	local current = platform.space_location and platform.space_location.name
	if current == target then
		return
	end
	if not target then
		return
	end
	if not location_exists(target) then
		report.unsolved = report.unsolved + 1
		log("razi-prepared-2x: no place " .. tostring(target) .. " for platform " .. record.name)
		return
	end
	platform.space_location = target
	report.moved = report.moved + 1
end

-- 3.0 cuts an infinite technology that goes on in a card technology (balance/common/infinite_research_cards.lua) to its
-- first five levels, and the game cuts a saved level to the new top before any script runs; the level saved by
-- /razi-prepare-3 goes to the continuation, the cut technology stays researched.
local function restore_infinite(record, reports)
	local report = reports[record.force]
	if not report then
		report = {levels = 0, unsolved = 0}
		reports[record.force] = report
	end
	local force = game.forces[record.force]
	local _, first = Names.split(record.name)
	if not force or type(record.level) ~= "number" or record.level <= first + Names.span - 1 then
		return
	end

	local continuation = force.technologies[Names.continuation(record.name)]
	if not continuation then
		-- With razi-infinite-research-cards off the technology is still infinite and keeps the level itself.
		local original = force.technologies[record.name]
		if original and original.prototype.max_level >= INFINITE_LEVEL then
			return
		end
		report.unsolved = report.unsolved + 1
		log("razi-prepared-2x: no " .. Names.continuation(record.name) .. " for " .. record.name .. " at level " .. record.level)
		return
	end
	local ok, problem = pcall(function()
		if continuation.level < record.level then
			continuation.level = record.level
		end
		if type(record.progress) == "number" and record.progress > 0 then
			continuation.saved_progress = math.min(record.progress, 0.9999)
		end
	end)
	if ok then
		report.levels = report.levels + 1
	else
		report.unsolved = report.unsolved + 1
		log("razi-prepared-2x: " .. continuation.name .. " did not take level " .. record.level .. ": " .. tostring(problem))
	end
end

function M.on_configuration_changed(event)
	if not is_update_from_2x(event) then
		return
	end

	local data = storage.razi_prepare_3
	if type(data) ~= "table" or data.version ~= VERSION then
		for _, player in pairs(game.players) do
			if player.admin then
				player.print({"razi-prepared-2x.not-prepared"})
			end
		end
		log("razi-prepared-2x: the save was updated from 2.x without /razi-prepare-3")
		return
	end

	local reports, chests = {}, {}
	for _, record in ipairs(data.labs or {}) do
		restore_lab(record, reports, chests)
	end
	for _, record in ipairs(data.platforms or {}) do
		restore_platform(record, reports)
	end
	local infinite_reports = {}
	local infinite = data.infinite
	if type(infinite) == "table" and infinite.version == INFINITE_VERSION then
		for _, record in ipairs(infinite.technologies or {}) do
			restore_infinite(record, infinite_reports)
		end
	else
		log("razi-prepared-2x: no levels of infinite technologies in the save, levels above the fifth are gone")
	end
	storage.razi_prepare_3 = nil

	for name, report in pairs(infinite_reports) do
		local force = game.forces[name]
		if force and (report.levels > 0 or report.unsolved > 0) then
			force.print({"razi-prepared-2x.infinite", report.levels, report.unsolved})
		end
		log(string.format("razi-prepared-2x: force %s: %d infinite technologies continued, %d not found",
			name, report.levels, report.unsolved))
	end

	for name, report in pairs(reports) do
		local force = game.forces[name]
		local message = {"razi-prepared-2x.summary", report.labs, report.chests, report.lost, report.moved, report.unsolved}
		if force then
			force.print(message)
		end
		log(string.format("razi-prepared-2x: force %s: %d cards to labs, %d to chests, %d on the ground, %d platforms moved, %d not found",
			name, report.labs, report.chests, report.lost, report.moved, report.unsolved))
	end
end

return M
