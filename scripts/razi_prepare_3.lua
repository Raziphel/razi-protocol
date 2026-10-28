-- /razi-prepare-3: run it in 2.1.x just before updating Razi Protocol to 3.0.
-- It takes the system tech cards out of laboratories and records where they were,
-- and records every space platform's position, so 3.0 can put them back.
-- Everything is kept in storage.razi_prepare_3; the command never runs by itself.
local M = {}

local VERSION = 1

local card_names = {
	["deep-space-tech-card"] = true
}
for _, prefix in ipairs({"calidus", "solaris", "nyxaris", "vibrant", "beetlejuice"}) do
	card_names[prefix .. "-tech-card"] = true
end

local function say(player, message)
	if player and player.valid then
		player.print(message)
	else
		-- Console and RCON: there is no player to answer.
		game.print(message)
		log(message)
	end
end

local function can_run(player)
	-- No player means the server console or RCON.
	return not player or (player.valid and player.admin)
end

-- Takes every system card out of one lab. Returns the list of removed stacks.
local function take_cards(lab)
	local inventory = lab.get_inventory(defines.inventory.lab_input)
	if not inventory then
		return {}
	end
	local found = {}
	for _, item in pairs(inventory.get_contents()) do
		if card_names[item.name] then
			found[#found + 1] = {name = item.name, quality = item.quality or "normal", count = item.count}
		end
	end
	local taken = {}
	for _, stack in ipairs(found) do
		local removed = inventory.remove({name = stack.name, quality = stack.quality, count = stack.count})
		if removed > 0 then
			taken[#taken + 1] = {name = stack.name, quality = stack.quality, count = removed}
		end
	end
	return taken
end

local function collect_labs()
	local labs, cards = {}, 0
	for _, surface in pairs(game.surfaces) do
		for _, lab in pairs(surface.find_entities_filtered({type = "lab"})) do
			local taken = take_cards(lab)
			if #taken > 0 then
				for _, stack in ipairs(taken) do
					cards = cards + stack.count
				end
				labs[#labs + 1] = {
					surface = surface.name,
					position = {x = lab.position.x, y = lab.position.y},
					name = lab.name,
					force = lab.force.name,
					items = taken
				}
			end
		end
	end
	return labs, cards
end

local function collect_platforms()
	local platforms = {}
	for _, force in pairs(game.forces) do
		for _, platform in pairs(force.platforms) do
			if platform.valid then
				local record = {force = force.name, index = platform.index, name = platform.name}
				local location = platform.space_location
				if location then
					record.space_location = location.name
				end
				local connection = platform.space_connection
				if connection and connection.from and connection.to then
					record.connection = {
						name = connection.name,
						from = connection.from.name,
						to = connection.to.name,
						distance = platform.distance
					}
				end
				platforms[#platforms + 1] = record
			end
		end
	end
	return platforms
end

function M.command(event)
	local player = event.player_index and game.get_player(event.player_index) or nil
	if not can_run(player) then
		say(player, {"razi-prepare-3.admin-only"})
		return
	end

	local labs, cards = collect_labs()
	local platforms = collect_platforms()

	-- A repeat call adds the labs (their cards are already gone) and rewrites the platforms.
	local data = storage.razi_prepare_3
	if type(data) ~= "table" or data.version ~= VERSION then
		data = {version = VERSION, labs = {}}
	end
	data.tick = game.tick
	for _, lab in ipairs(labs) do
		data.labs[#data.labs + 1] = lab
	end
	data.platforms = platforms
	storage.razi_prepare_3 = data

	local message = {"razi-prepare-3.summary", #labs, cards, #platforms}
	say(player, message)
	log(string.format("razi-prepare-3: %d labs, %d cards, %d platforms saved at tick %d",
		#labs, cards, #platforms, game.tick))
end

function M.register()
	commands.add_command("razi-prepare-3", {"razi-prepare-3.help"}, M.command)
end

return M
