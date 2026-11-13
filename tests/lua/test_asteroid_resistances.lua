---@diagnostic disable: missing-fields, need-check-nil, undefined-field
-- Asteroid armor of the difficulty levels (prototypes/world/asteroids/asteroid_resistances.lua) on a mocked data.raw.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(message) logs[#logs + 1] = message end)

-- The vanilla resistances of a size (space-age/prototypes/entity/asteroid.lua), with an immunity to fire
local vanilla = {
	small = {physical = {0, 0}, explosion = {0, 50}},
	medium = {physical = {0, 10}, explosion = {0, 30}},
	big = {physical = {2000, 10}, explosion = {0, 10}},
	huge = {physical = {3000, 10}, explosion = {0, 99}},
}
local function resistances(size)
	local result = {{type = "fire", percent = 100}, {type = "laser", decrease = 0, percent = 90}}
	for damage, values in pairs(vanilla[size]) do
		result[#result + 1] = {type = damage, decrease = values[1], percent = values[2]}
	end
	return result
end

local function setup(level, manual)
	local startup = {
		["razi-difficulty-preset"] = {value = level},
		["razi-asteroid-resistances"] = {value = manual or "standard"},
	}
	rawset(_G, "settings", {startup = startup})
	local asteroid = {}
	for size in pairs(vanilla) do
		asteroid[size .. "-metallic-asteroid"] = {name = size .. "-metallic-asteroid", resistances = resistances(size)}
	end
	-- Rubia's try_scale_asteroid_health result (rubia/prototypes/data-script/asteroid-update.lua:98-125).
	asteroid["huge-rubia-metallic-asteroid"] = {name = "huge-rubia-metallic-asteroid", resistances = {
		{type = "physical", percent = 100},
		{type = "rubia-kinetic", decrease = 3000, percent = 10},
	}}
	-- Krastorio2-spaced-out copies explosion resistance to kr-explosion before this pass.
	local k2_resistances = resistances("big")
	k2_resistances[#k2_resistances + 1] = {type = "kr-explosion", percent = 10}
	asteroid["big-k2-metallic-asteroid"] = {name = "big-k2-metallic-asteroid", resistances = k2_resistances}
	-- an asteroid of another mod without resistances, and a name without a size
	asteroid["medium-rock-asteroid"] = {name = "medium-rock-asteroid"}
	asteroid["odd-thing"] = {name = "odd-thing", resistances = {{type = "physical", percent = 5}}}
	rawset(_G, "data", {raw = {asteroid = asteroid}})
	logs = {}
	package.loaded["prototypes.world.asteroids.asteroid_resistances"] = nil
	package.loaded["lib.difficulty.presets"] = nil
	return require("prototypes.world.asteroids.asteroid_resistances").data_final_fixes()
end

local function get(name, damage)
	for _, resistance in ipairs(data.raw.asteroid[name].resistances or {}) do
		if resistance.type == damage then
			return resistance.decrease or 0, resistance.percent or 0
		end
	end
	return nil
end

-- Easy and Normal: nothing changes, nothing is logged
for _, level in ipairs({"easy", "normal"}) do
	check(setup(level) == 0, level .. " changed asteroids")
	check(#logs == 0, level .. " logged")
	local decrease, percent = get("medium-metallic-asteroid", "physical")
	check(decrease == 0 and percent == 10, level .. ": medium physical changed")
end

-- Hard: +10 % own damage, huge +10 %, medium +1 flat physical, big +20 flat explosion
local hard_changed = setup("hard")
check(#logs == 1, "hard: one log line")
local d, p = get("small-metallic-asteroid", "physical")
check(d == 0 and p == 10, "hard: small physical " .. d .. " " .. p)
d, p = get("medium-metallic-asteroid", "physical")
check(d == 1 and p == 20, "hard: medium physical " .. d .. " " .. p)
d, p = get("medium-metallic-asteroid", "explosion")
check(d == 0 and p == 30, "hard: medium explosion must stay")
d, p = get("big-metallic-asteroid", "explosion")
check(d == 20 and p == 20, "hard: big explosion " .. d .. " " .. p)
d, p = get("big-metallic-asteroid", "physical")
check(d == 2000 and p == 10, "hard: big physical must stay")
check(get("big-metallic-asteroid", "kr-explosion") == nil, "hard: big without kr-explosion must not get one")
d, p = get("big-k2-metallic-asteroid", "kr-explosion")
check(d == 20 and p == 20, "hard: K2 big explosion " .. d .. " " .. p)
d, p = get("huge-metallic-asteroid", "physical")
check(d == 3000 and p == 20, "hard: huge physical " .. d .. " " .. p)
d, p = get("huge-rubia-metallic-asteroid", "rubia-kinetic")
check(d == 3000 and p == 20, "hard: Rubia huge kinetic " .. d .. " " .. p)
check((10000 - d) * (1 - p / 100) >= 5000, "hard: Rubia railgun shot must kill a 5000 HP huge asteroid")
d, p = get("huge-rubia-metallic-asteroid", "physical")
check(d == 0 and p == 100, "hard: Rubia huge physical must stay " .. d .. " " .. p)
p = select(2, get("huge-metallic-asteroid", "fire"))
check(p == 100, "hard: immunity must stay")
d, p = get("medium-rock-asteroid", "physical")
check(d == 1 and p == 10, "hard: an asteroid without resistances gets them")
check(get("odd-thing", "physical") == 0 and select(2, get("odd-thing", "physical")) == 5, "hard: a name without a size")
check(hard_changed == 7, "hard: every sized asteroid changes")

-- Nightmare: +20 % for other sizes, +15 % for huge, +2 and +40
check(setup("nightmare") == 7, "nightmare: every sized asteroid changes")
d, p = get("medium-metallic-asteroid", "physical")
check(d == 2 and p == 30, "nightmare: medium physical " .. d .. " " .. p)
d, p = get("big-metallic-asteroid", "explosion")
check(d == 40 and p == 30, "nightmare: big explosion " .. d .. " " .. p)
d, p = get("big-k2-metallic-asteroid", "kr-explosion")
check(d == 40 and p == 30, "nightmare: K2 big explosion " .. d .. " " .. p)
d, p = get("huge-metallic-asteroid", "physical")
check(d == 3000 and p == 25, "nightmare: vanilla huge physical " .. d .. " " .. p)
d, p = get("huge-rubia-metallic-asteroid", "rubia-kinetic")
check(d == 3000 and p == 25, "nightmare: Rubia huge kinetic " .. d .. " " .. p)
check((10000 - d) * (1 - p / 100) >= 5000, "nightmare: Rubia railgun shot must kill a 5000 HP huge asteroid")
d, p = get("huge-rubia-metallic-asteroid", "physical")
check(d == 0 and p == 100, "nightmare: Rubia huge physical must stay " .. d .. " " .. p)

-- A value set by hand wins over the level; Custom uses it as well
check(setup("hard", "armored") == 7, "manual armored on hard")
d, p = get("big-metallic-asteroid", "explosion")
check(d == 40 and p == 30, "manual armored on hard: big explosion " .. d .. " " .. p)
-- A saved "standard" is the default and cannot be told from an untouched setting: the level applies
check(setup("nightmare", "standard") == 7, "nightmare with the default saved")
check(setup("custom", "hardened") == 7, "custom hardened")

-- The percent stops at 95
rawset(_G, "settings", {startup = {["razi-difficulty-preset"] = {value = "nightmare"},
	["razi-asteroid-resistances"] = {value = "standard"}}})
rawset(_G, "data", {raw = {asteroid = {["huge-x-asteroid"] = {resistances = {{type = "physical", percent = 90}}}}}})
package.loaded["prototypes.world.asteroids.asteroid_resistances"] = nil
package.loaded["lib.difficulty.presets"] = nil
require("prototypes.world.asteroids.asteroid_resistances").data_final_fixes()
check(data.raw.asteroid["huge-x-asteroid"].resistances[1].percent == 95, "percent above 95")

print("asteroid_resistances: ok")
