---@diagnostic disable: missing-fields
-- Shared by the tests of prototypes/balance/: a mocked data.raw, the log, and the level of razi-resource-loops.
local support = {}

support.logs = {}
rawset(_G, "log", function(message) support.logs[#support.logs + 1] = message end)

function support.check(value, message)
	if not value then
		error(message, 2)
	end
end

-- Lines of the log that contain the text.
function support.logged(text)
	local count = 0
	for _, line in ipairs(support.logs) do
		if line:find(text, 1, true) then
			count = count + 1
		end
	end

	return count
end

function support.copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = support.copy(item)
	end

	return result
end

function support.same(left, right)
	if type(left) ~= "table" or type(right) ~= "table" then
		return left == right
	end
	for key, item in pairs(left) do
		if not support.same(item, right[key]) then
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

-- Installs a data.raw with the given recipes and technologies and clears the log.
function support.install(recipes, technologies)
	support.logs = {}
	local raw = { recipe = recipes or {}, technology = technologies or {} }
	rawset(_G, "data", { raw = raw })

	return raw
end

-- The level a player gets: the difficulty level and the saved value of razi-resource-loops.
function support.level(preset, saved)
	rawset(_G, "settings", { startup = {
		["razi-difficulty-preset"] = { value = preset },
		["razi-resource-loops"] = { value = saved or "closed" },
	} })
end

-- Runs the group on a fresh fixture at every level. Open (Easy, or open picked by hand) must change nothing and log
-- nothing; closed and strict (Normal, Hard, Nightmare, or picked by hand) must satisfy applied(raw).
-- fixture() returns the recipes, and the technologies if it has them.
function support.gate(loops, fixture, applied)
	local rows = {
		{ "easy", "closed", false }, { "custom", "open", false }, { "normal", "open", false },
		{ "normal", "closed", true }, { "hard", "closed", true }, { "nightmare", "closed", true },
		{ "custom", "closed", true }, { "custom", "strict", true }, { "easy", "strict", true },
	}
	for _, row in ipairs(rows) do
		support.level(row[1], row[2])
		local recipes, technologies = fixture()
		local raw = support.install(recipes, technologies)
		local before = support.copy(raw)
		loops.data_final_fixes()
		local label = row[1] .. " with " .. row[2]
		if row[3] then
			support.check(applied(raw), label .. ": the loop must be closed")
		else
			support.check(support.same(raw, before) and #support.logs == 0,
				label .. ": the loop must stay open, nothing changed and nothing logged")
		end
	end
end

function support.no_settings()
	rawset(_G, "settings", nil)
end

return support
