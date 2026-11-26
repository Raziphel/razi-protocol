-- Runs after every other mod in the data stage of tests/load/run.sh (the name sorts last and it needs razi-protocol).
-- Stops the load on what the game would only fail on later, or not at all, and logs the numbers that have a limit.
local problems = {}

local function count(prototypes)
	local total = 0
	for _ in pairs(prototypes or {}) do
		total = total + 1
	end
	return total
end

-- a lab that lists a science pack twice (razi adds pack lists to labs of other mods)
for name, lab in pairs(data.raw.lab or {}) do
	local seen = {}
	for _, input in ipairs(lab.inputs or {}) do
		if seen[input] then
			problems[#problems + 1] = "lab " .. name .. " lists " .. input .. " twice in inputs"
		end
		seen[input] = true
	end
end

---@param version string "2.1.25"
---@param minimum integer[] {2, 1, 25}
---@return boolean
local function at_least(version, minimum)
	local parts = {}
	for number in string.gmatch(version, "%d+") do
		parts[#parts + 1] = tonumber(number)
	end
	for i, wanted in ipairs(minimum) do
		local have = parts[i] or 0
		if have ~= wanted then
			return have > wanted
		end
	end
	return true
end

-- tile effects: the engine takes 32 before Factorio 2.1.25 and 255 from it (a new one past the limit stops the load)
local tile_effect_limit = at_least(mods["base"], {2, 1, 25}) and 255 or 32
local tile_effects = count(data.raw["tile-effect"])
local recipes = count(data.raw.recipe)
if tile_effects > tile_effect_limit then
	problems[#problems + 1] = "tile effects: " .. tile_effects .. " of " .. tile_effect_limit
end
-- recipes: ids are 16 bit
if recipes > 65535 then
	problems[#problems + 1] = "recipes: " .. recipes .. " of 65535"
end

log("razi-load-check: tile effects " .. tile_effects .. " of " .. tile_effect_limit .. ", recipes " .. recipes .. " of 65535, labs " .. count(data.raw.lab))

if mods["Smart_Inserters"] then
	local startup = settings and settings.startup or {}
	local function check_setting(name, expected)
		local setting = startup[name]
		if not setting or setting.value ~= expected then
			problems[#problems + 1] = "Smart_Inserters setting " .. name .. " must be " .. tostring(expected)
		end
	end

	check_setting("si-range-adder", "inserter")
	for _, name in ipairs({
		"si-disable-inserters-consumption",
		"si-disable-long-inserters",
		"si-range-technologies",
		"si-diagonal-technologies",
		"si-offset-technologies",
	}) do
		check_setting(name, false)
	end
	check_setting("si-inserters-chase-belt-items", true)

	for name, expected in pairs({
		inserter = 0.035,
		["fast-inserter"] = 0.1,
		["long-handed-inserter"] = 0.05,
	}) do
		local inserter = data.raw.inserter and data.raw.inserter[name]
		if not inserter then
			problems[#problems + 1] = "Smart_Inserters is missing inserter " .. name
		elseif type(inserter.extension_speed) ~= "number" or math.abs(inserter.extension_speed - expected) > 1e-9 then
			problems[#problems + 1] = "Smart_Inserters changed " .. name .. " extension_speed"
		end
	end

	local long_handed = data.raw.inserter and data.raw.inserter["long-handed-inserter"]
	if not long_handed or long_handed.fast_replaceable_group ~= "long-handed-inserter" then
		problems[#problems + 1] = "Smart_Inserters changed long-handed-inserter fast_replaceable_group"
	end
	if not long_handed or long_handed.next_upgrade ~= "kr-superior-long-inserter" then
		problems[#problems + 1] = "Smart_Inserters changed long-handed-inserter next_upgrade"
	end
	for name, inserter in pairs(data.raw.inserter or {}) do
		if type(inserter.fast_replaceable_group) == "string"
			and string.find(inserter.fast_replaceable_group, "razi-long-handed-inserter", 1, true) then
			problems[#problems + 1] = "Smart_Inserters left the group marker on " .. name
		end
	end
end

if #problems > 0 then
	error("razi-load-check: " .. table.concat(problems, "; "))
end
