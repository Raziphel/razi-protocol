-- Card prerequisites of the Vespera and Umbra gates (technology/seven_systems.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_seven_systems.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function contains(list, value)
	for _, entry in ipairs(list or {}) do
		if entry == value then
			return true
		end
	end
	return false
end

local function technology(name, prerequisites, unlocks, cards)
	local effects = {}
	for _, recipe in ipairs(unlocks or {}) do
		effects[#effects + 1] = {type = "unlock-recipe", recipe = recipe}
	end
	local ingredients = {}
	for _, card in ipairs(cards or {}) do
		ingredients[#ingredients + 1] = {card, 1}
	end
	return {type = "technology", name = name, prerequisites = prerequisites or {}, effects = effects,
		unit = {count = 10, time = 30, ingredients = ingredients}}
end

local logged = {}
local function build(technologies)
	local raw = {technology = {}}
	rawset(_G, "data", {raw = raw})
	data.extend = function(_, prototypes)
		for _, prototype in ipairs(prototypes) do
			raw[prototype.type] = raw[prototype.type] or {}
			raw[prototype.type][prototype.name] = prototype
		end
	end
	logged = {}
	rawset(_G, "log", function(message) logged[#logged + 1] = message end)

	package.loaded["prototypes.technology.seven_systems"] = nil
	local module = require("prototypes.technology.seven_systems")
	-- The module also defines the three gates; replace them with the scenario.
	raw.technology = {}
	for _, definition in ipairs(technologies) do
		raw.technology[definition.name] = definition
	end
	module.data_final_fixes()
	return raw.technology
end

-- (a) The unlocking technology is not an ancestor yet: it becomes a prerequisite.
local techs = build({
	technology("solaris-discovery"),
	technology("nyxaris-discovery"),
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}),
	technology("planet-discovery-moshine", {}, {"nyxaris-tech-card"}),
	technology("vespera-discovery", {"solaris-discovery", "nyxaris-discovery"}, nil,
		{"solaris-tech-card", "nyxaris-tech-card"})
})
check(contains(techs["vespera-discovery"].prerequisites, "planet-discovery-castra"), "Castra must be added")
check(contains(techs["vespera-discovery"].prerequisites, "planet-discovery-moshine"), "Moshine must be added")
check(#logged == 2 and string.find(logged[1], "vespera-discovery now requires planet-discovery-castra: it unlocks solaris-tech-card", 1, true),
	"Each added prerequisite is logged")

-- (b) The unlocking technology is already an ancestor (also through a chain): nothing changes.
techs = build({
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}),
	technology("solaris-discovery", {"planet-discovery-castra"}),
	technology("vespera-discovery", {"solaris-discovery"}, nil, {"solaris-tech-card"})
})
check(#techs["vespera-discovery"].prerequisites == 1, "An implied prerequisite is not repeated")
check(#logged == 0, "Nothing is logged without a change")

-- (c) Adding the prerequisite would close a cycle: it is skipped.
techs = build({
	technology("umbra-discovery", {}, nil, {"umbra-tech-card"}),
	technology("late-unlock", {"umbra-discovery"}, {"umbra-tech-card"})
})
check(#techs["umbra-discovery"].prerequisites == 0, "A cycle must not be created")
check(#logged == 0, "A skipped cycle is not logged")

-- (d) A technology without cards in the price, or an unrelated one, is untouched.
techs = build({
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}),
	technology("vespera-discovery", {}, nil, {"automation-science-pack"}),
	technology("some-other-tech", {}, nil, {"solaris-tech-card"})
})
check(#techs["vespera-discovery"].prerequisites == 0, "No card in the price, no new prerequisite")
check(#techs["some-other-tech"].prerequisites == 0, "Only the six gate technologies are processed")

-- A card nobody unlocks adds nothing and does not fail.
techs = build({technology("vespera-discovery", {}, nil, {"solaris-tech-card"})})
check(#techs["vespera-discovery"].prerequisites == 0, "A card without an unlocking technology is skipped")

print("test_seven_systems: ok")
