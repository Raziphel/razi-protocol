---@diagnostic disable: need-check-nil, param-type-mismatch
-- The folders of the mod (contributing.md, "Where a file goes"): no file loose at the top of prototypes/ or scripts/, no
-- new top folder without a decision, no file so long that nobody reads it to the end.
local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function listing(command)
	local lines = {}
	local pipe = io.popen(command)
	check(pipe, "Cannot run " .. command)
	for line in pipe:lines() do
		lines[#lines + 1] = line
	end
	pipe:close()
	return lines
end

local FOLDERS = {
	prototypes = {
		balance = true, compatibility = true, difficulty = true, fixes = true, industry = true, technology = true,
		ui = true, world = true,
	},
	scripts = {
		asteroids = true, commands = true, compatibility = true, convergence = true, dyson = true, enemies = true,
		events = true, journal = true, migration = true, projects = true, story = true,
	},
}

for root, allowed in pairs(FOLDERS) do
	local loose = listing("find " .. root .. " -maxdepth 1 -type f -name '*.lua'")
	check(#loose == 0, "A file directly in " .. root .. "/ belongs in a folder: " .. table.concat(loose, ", "))
	for _, path in ipairs(listing("find " .. root .. " -mindepth 1 -maxdepth 1 -type d")) do
		local name = path:match("([^/]+)$")
		check(allowed[name], "New folder " .. path .. ": add it to contributing.md and to this test")
	end
end

-- 500 is where to start splitting; a file over this limit was not split in time.
local MOST_LINES = 600
for _, path in ipairs(listing("find prototypes scripts lib settings -type f -name '*.lua'")) do
	local count = 0
	local file = io.open(path, "r")
	check(file, "Cannot read " .. path)
	for _ in file:lines() do
		count = count + 1
	end
	file:close()
	check(count <= MOST_LINES, path .. " has " .. count .. " lines: split it by meaning")
end

print("test_layout: ok")
