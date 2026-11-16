-- Check that removed Lab-ready cards are returned to their science packs in saves.
-- Run from the mod root: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function read(path)
	local file = assert(io.open(path, "r"))
	local content = file:read("*a")
	file:close()
	return content
end

local migration = read("migrations/3.2.0.json")
local pairs_found, old_names, new_names = 0, {}, {}
for old, new in migration:gmatch('%[%s*"([^"]+)"%s*,%s*"([^"]+)"%s*%]') do
	pairs_found = pairs_found + 1
	check(old == "razi-" .. new .. "-tech-card", "unexpected card migration: " .. old .. " -> " .. new)
	check(not old_names[old] and not new_names[new], "duplicate migration pair: " .. old .. " -> " .. new)
	old_names[old], new_names[new] = true, true
end
check(pairs_found == 68, "expected 68 migrated science packs, found " .. pairs_found)

local top_level_keys = 0
for key in migration:gmatch("[{,]%s*\"([^\"]+)\"%s*:") do
	top_level_keys = top_level_keys + 1
	check(key == "item", "unexpected top-level migration key: " .. key)
end
check(top_level_keys == 1, "migration must have only the item key")

local removed_setting = "razi-" .. "auto-" .. "tech-cards"
check(not read("settings/integration.lua"):find(removed_setting, 1, true), "removed setting remains declared")
check(not read("lib/difficulty/presets.lua"):find(removed_setting, 1, true), "removed setting remains managed")

print("test_tech_cards_migration ok")
