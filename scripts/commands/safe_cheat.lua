-- The stock /cheat researches every technology in one engine call.
-- On a large modpack that can stall the simulation. This testing command
-- changes one research at a time and can be cancelled without a reset.
local M = {}

-- Optional listener for features that redraw on research changes.
-- Writing technology.researched does not have to raise an event, so a
-- feature that needs to know registers itself here instead.
local research_listener

local WARNING_COOLDOWN = 600
local WARNING_TINT = {r = 1, g = 0.77, b = 0.47}

local function say(index, key, ...)
	local message = {"razi-cheat.message", {"razi-cheat." .. key, ...}}
	local player = index and game.get_player(index)
	if player and player.valid then
		player.print(message)
	else
		log(message)
	end
end

local function notify(force)
	if research_listener then
		research_listener(force)
	end
end

local function eligible(technology)
	if not technology or technology.valid == false or technology.researched then
		return false
	end
	local prototype = technology.prototype
	return prototype and prototype.enabled ~= false and not prototype.hidden
end

-- Prerequisite order gives scripted progression a more natural sequence.
-- Technology tables are scanned once on request, never every game tick.
local function make_plan(force)
	local candidates = {}
	for name, technology in pairs(force.technologies) do
		if eligible(technology) then
			candidates[#candidates + 1] = name
		end
	end
	table.sort(candidates)

	local ordered, seen = {}, {}
	local function visit(name)
		if seen[name] then
			return
		end
		seen[name] = true
		local technology = force.technologies[name]
		if not eligible(technology) then
			return
		end
		local parents = {}
		for parent_name in pairs(technology.prerequisites or {}) do
			if eligible(force.technologies[parent_name]) then
				parents[#parents + 1] = parent_name
			end
		end
		table.sort(parents)
		for _, parent in ipairs(parents) do
			visit(parent)
		end
		ordered[#ordered + 1] = name
	end
	for _, name in ipairs(candidates) do
		visit(name)
	end
	return ordered
end

function M.set_research_listener(listener)
	research_listener = listener
end

function M.command(event)
	local player = event.player_index and game.get_player(event.player_index)
	if not (player and player.valid) then
		say(nil, "player-only")
		return
	end
	if not player.admin then
		say(player.index, "admin-only")
		return
	end

	local action = (event.parameter or ""):match("^%s*(.-)%s*$"):lower()
	if action == "" then
		action = "start"
	end
	if action ~= "start" and action ~= "status" and action ~= "cancel" then
		say(player.index, "usage")
		return
	end

	local force = player.force
	local jobs = storage.razi_cheat_jobs or {}
	local job = jobs[force.name]

	if action == "status" then
		if job then
			say(player.index, "status", job.position - 1, #job.names)
		else
			say(player.index, "status-idle")
		end
		return
	end

	if action == "cancel" then
		if job then
			jobs[force.name] = nil
			notify(force)
			say(player.index, "cancelled", job.position - 1, #job.names)
			if not next(jobs) then
				storage.razi_cheat_jobs = nil
			end
		else
			say(player.index, "cancel-idle")
		end
		return
	end

	if job then
		say(player.index, "already-running")
		return
	end

	local plan = make_plan(force)
	player.cheat_mode = true
	if #plan == 0 then
		say(player.index, "nothing-left")
		return
	end
	storage.razi_cheat_jobs = jobs
	jobs[force.name] = {
		names = plan,
		position = 1,
		completed = 0,
		failed = 0,
		last_reported = 0,
		player_index = player.index
	}
	notify(force)
	say(player.index, "started", #plan)
end

function M.tick()
	local jobs = storage.razi_cheat_jobs
	if not jobs then
		return
	end

	for force_name, job in pairs(jobs) do
		local force = game.forces[force_name]
		if not (force and force.valid ~= false) then
			jobs[force_name] = nil
		else
			local name = job.names[job.position]
			if name then
				local technology = force.technologies[name]
				if eligible(technology) then
					local ok, err = pcall(function()
						technology.researched = true
					end)
					if ok then
						job.completed = job.completed + 1
					else
						job.failed = job.failed + 1
						if job.failed <= 5 then
							log("[Razi Protocol/cheat] Failed to research " .. name .. ": " .. tostring(err))
						end
					end
				end
				job.position = job.position + 1
				notify(force)
				local mark = math.floor((job.position - 1) * 10 / #job.names)
				if mark > job.last_reported and mark < 10 then
					job.last_reported = mark
					say(job.player_index, "progress", mark * 10)
				end
			end
			if job.position > #job.names then
				jobs[force_name] = nil
				say(job.player_index, "complete", job.completed, job.failed)
				log(("[Razi Protocol/cheat] Force %s: %d completed, %d failed.")
					:format(force_name, job.completed, job.failed))
			end
		end
	end

	if not next(jobs) then
		storage.razi_cheat_jobs = nil
	end
end

-- Built-in commands belong to the engine, and Factorio does not provide
-- a cancellable pre-command hook. The console event is best-effort only.
function M.warn_builtin(event)
	if not (event and type(event.command) == "string" and event.command:lower() == "cheat") then
		return
	end
	local option = (event.parameters or ""):match("^%s*(.-)%s*$"):lower()
	if option == "off" then
		return
	end

	local player = event.player_index and game.get_player(event.player_index)
	if not (player and player.valid) then
		return
	end
	local last = storage.razi_cheat_last_warning and storage.razi_cheat_last_warning[player.index]
	if last and game.tick - last < WARNING_COOLDOWN and game.tick >= last then
		return
	end
	storage.razi_cheat_last_warning = storage.razi_cheat_last_warning or {}
	storage.razi_cheat_last_warning[player.index] = game.tick
	player.print({"razi-cheat.builtin-warning"}, {color = WARNING_TINT})
end

-- Players testing the pack need to see the alternative before trying
-- the built-in command. Show this only once per save, and only to admins.
function M.admin_tip(player)
	if not (player and player.valid and player.admin) then
		return
	end
	storage.razi_cheat_tip_seen = storage.razi_cheat_tip_seen or {}
	if storage.razi_cheat_tip_seen[player.index] then
		return
	end
	storage.razi_cheat_tip_seen[player.index] = true
	player.print({"razi-cheat.admin-tip"}, {color = WARNING_TINT})
end

function M.on_player_removed(index)
	if storage.razi_cheat_tip_seen then
		storage.razi_cheat_tip_seen[index] = nil
	end
	if storage.razi_cheat_last_warning then
		storage.razi_cheat_last_warning[index] = nil
	end
end

return M
