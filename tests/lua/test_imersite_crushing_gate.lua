---@diagnostic disable: missing-fields, need-check-nil, param-type-mismatch, undefined-field
-- Imersite asteroid crushing waits for the discovery of Fulgora, where its asteroids first fly
-- (prototypes/compatibility/Imersite-Asteroids/crushing_gate.lua), on a mocked data.raw.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

rawset(_G, "log", function(_) end)

local function setup(installed, technologies)
	rawset(_G, "mods", installed and {["Imersite-Asteroids"] = "1.3.0"} or {})
	rawset(_G, "data", {raw = {technology = technologies}})
	package.loaded["prototypes.compatibility.Imersite-Asteroids.crushing_gate"] = nil
	package.loaded["prototypes.fixes.common.progression_helpers"] = nil
	return require("prototypes.compatibility.Imersite-Asteroids.crushing_gate")
end

local function pack()
	return {
		["imersite-asteroid-crushing"] = {
			name = "imersite-asteroid-crushing",
			prerequisites = {"production-science-pack", "space-science-pack"},
		},
		["planet-discovery-fulgora"] = {name = "planet-discovery-fulgora", prerequisites = {"space-platform-thruster"}},
	}
end

local function count(list, value)
	local result = 0
	for _, entry in ipairs(list or {}) do
		if entry == value then
			result = result + 1
		end
	end
	return result
end

-- The research waits for Fulgora and keeps its own prerequisites, once even when run twice.
do
	local technologies = pack()
	local gate = setup(true, technologies)
	gate.data_final_fixes()
	gate.data_final_fixes()
	local prerequisites = technologies["imersite-asteroid-crushing"].prerequisites
	check(count(prerequisites, "planet-discovery-fulgora") == 1, "crushing waits for Fulgora once")
	check(count(prerequisites, "production-science-pack") == 1, "production science stays")
	check(count(prerequisites, "space-science-pack") == 1, "space science stays")
	check(#technologies["planet-discovery-fulgora"].prerequisites == 1, "Fulgora gets no new prerequisite")
end

-- Without Imersite-Asteroids nothing changes, even with a technology of that name.
do
	local technologies = pack()
	setup(false, technologies).data_final_fixes()
	check(count(technologies["imersite-asteroid-crushing"].prerequisites, "planet-discovery-fulgora") == 0,
		"no gate without the mod")
end

-- Without Fulgora's discovery the prerequisite is not added: it would point at no technology.
do
	local technologies = pack()
	technologies["planet-discovery-fulgora"] = nil
	setup(true, technologies).data_final_fixes()
	check(count(technologies["imersite-asteroid-crushing"].prerequisites, "planet-discovery-fulgora") == 0,
		"no dangling prerequisite")
end

-- Without the crushing research there is nothing to gate and no error.
do
	local technologies = pack()
	technologies["imersite-asteroid-crushing"] = nil
	setup(true, technologies).data_final_fixes()
	check(technologies["imersite-asteroid-crushing"] == nil, "no research is made up")
end

print("ok")
