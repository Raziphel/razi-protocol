-- Runtime: the nests that a planet's prototype switches off are switched off in the settings of surfaces that exist
-- already (scripts/razi_enemy_surfaces.lua), on a mocked game.
-- Run from the mod root:
--   lua5.2 tests/lua/test_enemy_surfaces.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logged = {}
rawset(_G, "log", function(message) logged[#logged + 1] = message end)

local off = {frequency = 0, size = 0, richness = 0}
local shared = {
	"armoured-biter-spawner", "arachnid-spawner-unitspawner", "toxic-biter-spawner", "small-toxic-worm-turret",
	"medium-toxic-worm-turret", "big-toxic-worm-turret", "behemoth-toxic-worm-turret", "leviathan-toxic-worm-turret",
	"mother-toxic-worm-turret"
}

local function prototype_settings(entries)
	return {map_gen_settings = {autoplace_settings = {entity = {settings = entries}}}}
end

-- A surface whose map_gen_settings is a property: reads give a copy, a write is counted.
local function surface(name, planet_prototype, settings)
	local writes = 0
	local object = {name = name, read = function() return settings end}
	if planet_prototype then
		object.planet = {prototype = planet_prototype}
	end
	setmetatable(object, {
		__index = function(_, key)
			if key == "map_gen_settings" then
				return table.deepcopy and table.deepcopy(settings) or settings
			elseif key == "writes" then
				return writes
			end
		end,
		__newindex = function(_, key, value)
			if key == "map_gen_settings" then
				writes = writes + 1
				settings = value
			end
		end
	})
	return object
end

if not table.deepcopy then
	local function deepcopy(value)
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for key, entry in pairs(value) do
			copy[key] = deepcopy(entry)
		end
		return copy
	end
	table.deepcopy = deepcopy -- luacheck: ignore 122
end

local function entity_setting(object, name)
	local settings = object.read().autoplace_settings
	return settings and settings.entity and settings.entity.settings and settings.entity.settings[name]
end

-- The prototype of Nauvis (and Terrapalus): the shared nests are off, the vanilla ones stand.
local zeroed_entries = {["biter-spawner"] = {}}
for _, name in ipairs(shared) do
	zeroed_entries[name] = off
end
zeroed_entries["small-worm-turret"] = off -- not a name of the three families: never copied
local home_entries = {["arachnid-spawner-unitspawner"] = {}, ["biter-spawner"] = off}

local nauvis = surface("nauvis", prototype_settings(zeroed_entries), {
	autoplace_controls = {["enemy-base"] = {frequency = 1, size = 1, richness = 1}},
	autoplace_settings = {entity = {settings = {["iron-ore"] = {frequency = 2}}}, tile = {settings = {["grass-1"] = {}}}},
	seed = 4242
})
local terrapalus = surface("terrapalus", prototype_settings(zeroed_entries), {
	autoplace_settings = {entity = {settings = {["toxic-biter-spawner"] = {frequency = 0.5}}, treat_missing_as_default = true}}
})
local settled = surface("settled", prototype_settings(zeroed_entries), {autoplace_settings = {entity = {settings = (function()
	local entries = {}
	for _, name in ipairs(shared) do
		entries[name] = {frequency = 0, size = 0, richness = 0}
	end
	return entries
end)()}}})
local athos = surface("athos", prototype_settings(home_entries), {autoplace_settings = {entity = {settings = {}}}})
local platform = surface("platform-1", nil, {})
local bare = surface("bare", {map_gen_settings = {}}, {})
local bare_entity = surface("bare-entity", {map_gen_settings = {autoplace_settings = {tile = {settings = {}}}}}, {})

rawset(_G, "game", {surfaces = {nauvis = nauvis, terrapalus = terrapalus, settled = settled, athos = athos, platform = platform,
	bare = bare, bare_entity = bare_entity}})

local surfaces = require("scripts.razi_enemy_surfaces")
local changed = surfaces.apply()
table.sort(changed)
check(#changed == 2 and changed[1] == "nauvis" and changed[2] == "terrapalus", "Nauvis and Terrapalus are changed: " .. table.concat(changed, ","))

-- Nauvis: every nest and worm of the three families is off; nothing else is touched.
for _, name in ipairs(shared) do
	local setting = entity_setting(nauvis, name)
	check(setting and setting.frequency == 0 and setting.size == 0 and setting.richness == 0, "Nauvis: " .. name .. " is off")
end
check(entity_setting(nauvis, "biter-spawner") == nil and entity_setting(nauvis, "small-worm-turret") == nil, "Nauvis: the vanilla enemies are not written")
check(entity_setting(nauvis, "iron-ore").frequency == 2, "Nauvis: other entity entries stay")
check(nauvis.read().autoplace_settings.tile.settings["grass-1"] ~= nil and nauvis.read().seed == 4242
	and nauvis.read().autoplace_controls["enemy-base"].frequency == 1, "Nauvis: nothing else in the settings changes")
check(nauvis.writes == 1, "Nauvis: one write")

-- A weaker entry is replaced; the flag next to the entries stays.
check(entity_setting(terrapalus, "toxic-biter-spawner").frequency == 0, "Terrapalus: a half-on entry is switched off")
check(terrapalus.read().autoplace_settings.entity.treat_missing_as_default == true, "Terrapalus: treat_missing_as_default stays")

-- Where there is nothing to change nothing is written.
check(settled.writes == 0, "a surface that has the entries is not written")
check(athos.writes == 0 and entity_setting(athos, "arachnid-spawner-unitspawner") == nil, "a home keeps its nests")
check(platform.writes == 0, "a surface without a planet is not written")
check(bare.writes == 0 and bare_entity.writes == 0, "a planet without entity settings is not written")
check(#logged == 2, "each change is logged once: " .. #logged)
check(logged[1]:find("nauvis", 1, true) or logged[2]:find("nauvis", 1, true), "the log names the surface")

-- A second pass changes nothing.
logged = {}
check(#surfaces.apply() == 0 and nauvis.writes == 1 and terrapalus.writes == 1 and #logged == 0, "the second pass writes nothing")

rawset(_G, "game", nil)
rawset(_G, "log", nil)
print("enemy_surfaces: ok")
