---@diagnostic disable: lowercase-global, missing-fields
-- Checks Smart Inserters speed, long-inserter groups, belt chasing, and post-mod copies.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local MODULE = "prototypes.compatibility.Smart_Inserters.smart_inserters"

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function deep_copy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, item in pairs(value) do
		copy[deep_copy(key)] = deep_copy(item)
	end
	return copy
end

local function equal(left, right)
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end
	for key, value in pairs(left) do
		if not equal(value, right[key]) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function new_data()
	return {
		raw = {
			inserter = {
				inserter = { name = "inserter", extension_speed = 0.035, chases_belt_items = true },
				["fast-inserter"] = { name = "fast-inserter", extension_speed = 0.1, chases_belt_items = true },
				["long-handed-inserter"] = {
					name = "long-handed-inserter",
					extension_speed = 0.05,
					fast_replaceable_group = "long-handed-inserter",
					next_upgrade = "kr-superior-long-inserter",
					chases_belt_items = true,
				},
				["kr-superior-long-inserter"] = {
					name = "kr-superior-long-inserter",
					extension_speed = 0.105,
					fast_replaceable_group = "long-handed-inserter",
					chases_belt_items = true,
				},
				["RTThrower-EjectorHatchRT"] = {
					name = "RTThrower-EjectorHatchRT",
					extension_speed = 0.035,
					chases_belt_items = false,
				},
				["hps__ml-loader"] = { name = "hps__ml-loader", extension_speed = 0.5, chases_belt_items = false },
			},
		},
	}
end

local function load_fix(installed_mods, fixture)
	local logs = {}
	rawset(_G, "mods", installed_mods)
	rawset(_G, "data", fixture)
	rawset(_G, "log", function(line)
		logs[#logs + 1] = line
	end)
	package.loaded[MODULE] = nil
	return require(MODULE), logs
end

local function run_smart_inserters()
	for name, inserter in pairs(data.raw.inserter) do
		if string.find(name, "hps__ml-", 1, true) ~= 1 then
			inserter.allow_custom_vectors = true
			inserter.extension_speed = (inserter.extension_speed or 1) * 2
			inserter.chases_belt_items = true
			if inserter.fast_replaceable_group == "long-handed-inserter" then
				inserter.fast_replaceable_group = "inserter"
				if inserter.name == "long-handed-inserter" then
					inserter.next_upgrade = "inserter"
				end
			end
		end
	end
end

local function add_post_smart_inserters_copies()
	local inserters = data.raw.inserter
	inserters.inserter_panglia_fast_version = deep_copy(inserters.inserter)
	inserters.inserter_panglia_fast_version.name = "inserter_panglia_fast_version"
	inserters["RTThrower-long-handed-inserter"] = deep_copy(inserters["long-handed-inserter"])
	inserters["RTThrower-long-handed-inserter"].name = "RTThrower-long-handed-inserter"
	inserters["bioluminescent-RTThrower-EjectorHatchRT"] = deep_copy(inserters["RTThrower-EjectorHatchRT"])
	inserters["bioluminescent-RTThrower-EjectorHatchRT"].name = "bioluminescent-RTThrower-EjectorHatchRT"
	inserters["RTThrower-inserter"] = deep_copy(inserters.inserter)
	inserters["RTThrower-inserter"].name = "RTThrower-inserter"
	inserters["RTThrower-inserter"].extension_speed = 0.3
	inserters["harene-infused-long-handed-inserter"] = deep_copy(inserters["long-handed-inserter"])
	inserters["harene-infused-long-handed-inserter"].name = "harene-infused-long-handed-inserter"
	inserters["harene-infused-long-handed-inserter"].fast_replaceable_group =
		inserters["long-handed-inserter"].fast_replaceable_group .. "-with-ears"
	inserters["harene-infused-long-handed-inserter"].next_upgrade = nil
end

local fix, logs = load_fix({ Smart_Inserters = "2.1.0" }, new_data())
fix.data_updates()
run_smart_inserters()
add_post_smart_inserters_copies()
fix.data_final_fixes()

local inserters = data.raw.inserter
for name, expected in pairs({
	inserter = 0.035,
	["fast-inserter"] = 0.1,
	["long-handed-inserter"] = 0.05,
	["kr-superior-long-inserter"] = 0.105,
	["RTThrower-EjectorHatchRT"] = 0.035,
	["inserter_panglia_fast_version"] = 0.035,
	["RTThrower-long-handed-inserter"] = 0.05,
	["bioluminescent-RTThrower-EjectorHatchRT"] = 0.035,
	["RTThrower-inserter"] = 0.3,
	["harene-infused-long-handed-inserter"] = 0.05,
	["hps__ml-loader"] = 0.5,
}) do
	check(inserters[name].extension_speed == expected, name .. " extension_speed is " .. tostring(inserters[name].extension_speed))
end
for _, name in ipairs({ "long-handed-inserter", "kr-superior-long-inserter", "RTThrower-long-handed-inserter" }) do
	check(inserters[name].fast_replaceable_group == "long-handed-inserter", name .. " group was not restored")
end
check(inserters["harene-infused-long-handed-inserter"].fast_replaceable_group == "long-handed-inserter-with-ears",
	"the post-SI copy group suffix was not preserved")
for name, inserter in pairs(inserters) do
	local group = inserter.fast_replaceable_group
	check(type(group) ~= "string" or not string.find(group, "razi-long-handed-inserter", 1, true),
		name .. " kept the temporary group marker")
end
check(inserters["long-handed-inserter"].next_upgrade == "kr-superior-long-inserter", "SI changed the long inserter upgrade")
check(inserters["RTThrower-EjectorHatchRT"].chases_belt_items == false, "Renai ejector should not chase belt items")
check(inserters["bioluminescent-RTThrower-EjectorHatchRT"].chases_belt_items == false,
	"Tenebris copy of the Renai ejector should not chase belt items")
check(inserters.inserter.chases_belt_items == true, "ordinary inserters should keep SI belt chasing")
check(logs[#logs] == "razi-protocol: Smart_Inserters: 5 inserters restored, 0 speed mismatches",
	"unexpected summary log: " .. tostring(logs[#logs]))

-- A later speed change is reported without aborting data-final-fixes.
fix, logs = load_fix({ Smart_Inserters = "2.1.0" }, new_data())
fix.data_updates()
run_smart_inserters()
local mismatch_inserters = data.raw.inserter
mismatch_inserters["fast-inserter"].extension_speed = 0.125
fix.data_final_fixes()
local mismatch_found = false
for _, line in ipairs(logs) do
	if string.find(line, "fast-inserter extension_speed 0.125, expected 0.1", 1, true) then
		mismatch_found = true
	end
end
check(mismatch_found, "a changed speed must be logged with its expected value")

-- Without Smart_Inserters the prototypes and log stay untouched.
local fixture = new_data()
local original = deep_copy(fixture.raw)
fix, logs = load_fix({}, fixture)
fix.data_updates()
fix.data_final_fixes()
check(equal(fixture.raw, original), "prototypes changed without Smart_Inserters")
check(#logs == 0, "the compatibility module logged without Smart_Inserters")

-- An unsupported release logs once and does not touch prototypes.
fixture = new_data()
original = deep_copy(fixture.raw)
fix, logs = load_fix({ Smart_Inserters = "2.2.0" }, fixture)
fix.data_updates()
fix.data_final_fixes()
check(equal(fixture.raw, original), "prototypes changed with an unsupported Smart_Inserters version")
check(#logs == 1 and string.find(logs[1], "is not 2.1.x", 1, true), "unsupported version must log one warning")

print("test_smart_inserters: ok")
