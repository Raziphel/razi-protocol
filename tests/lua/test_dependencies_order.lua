-- Hidden dependencies keep data-stage patches behind the mods whose prototypes they change.
-- Run from the mod root:
--   lua5.2 tests/lua/test_dependencies_order.lua
local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local info_file = assert(io.open("info.json", "r"))
local info = info_file:read("*a")
info_file:close()

local dependency_block = info:match('"dependencies"%s*:%s*(%b[])')
check(dependency_block, "info.json has no dependencies array")

local dependency_entries = {}
for entry in dependency_block:gmatch('"([^"]+)"') do
	dependency_entries[entry] = true
end

for _, name in ipairs({"dea-dia-system", "pelagos", "Flare Stack"}) do
	check(dependency_entries["(?) " .. name], name .. " must be a hidden optional dependency without a version")
end

local nexus_fork = "Nexus-" .. "Updated"
local threat_fork = "Nexus-Threat-" .. "Updated"
check(not dependency_block:find(nexus_fork, 1, true), "dependencies still mention the Nexus fork")
check(not dependency_block:find(threat_fork, 1, true), "dependencies still mention the Nexus Threat fork")

local files = io.popen("find prototypes scripts -type f -name '*.lua' -print")
if not files then
	error("could not list Lua sources")
end
for path in files:lines() do
	local filename = tostring(path)
	local file = assert(io.open(filename, "r"))
	local source = file:read("*a")
	file:close()
	check(not source:find(nexus_fork, 1, true), filename .. " still mentions the Nexus fork")
	check(not source:find(threat_fork, 1, true), filename .. " still mentions the Nexus Threat fork")
end
check(files:close(), "could not finish scanning Lua sources")

print("test_dependencies_order: ok")
