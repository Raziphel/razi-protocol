---@diagnostic disable: missing-fields, assign-type-mismatch, need-check-nil
-- Late technologies spend the Vespera and Umbra cards (technology/progression.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_late_system_cards.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local card_names = {
	"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card", "vibrant-tech-card",
	"vespera-tech-card", "beetlejuice-tech-card", "umbra-tech-card", "deep-space-tech-card"
}

local technology_names = {
	"promethium-science-pack", "promethium-882-research", "planet-discovery-nexus",
	"planet-nexus-scanning", "black-hole-discovery", "beetlejuice-discovery",
	"linox-technology_planet-discovery-linox", "linox-technology_exploring-linox-landing-site"
}

local function build(mod_list)
	local raw = {tool = {}, item = {}, technology = {}, lab = {}}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", mod_list or {})
	rawset(_G, "log", function(_) end)
	for _, name in ipairs(card_names) do
		raw.tool[name] = {type = "tool", name = name}
	end
	for _, name in ipairs(technology_names) do
		raw.technology[name] = {type = "technology", name = name, prerequisites = {},
			unit = {count = 100, time = 30, ingredients = {{"automation-science-pack", 1}}}}
	end
	raw.lab.lab = {type = "lab", name = "lab", inputs = {"automation-science-pack"}}

	package.loaded["util"] = nil
	package.loaded["prototypes.technology.systems.progression"] = nil
	require("util")
	require("prototypes.technology.systems.progression")
	return raw
end

local function cards(raw, technology)
	local result = {}
	for _, ingredient in ipairs(raw.technology[technology].unit.ingredients) do
		result[ingredient.name or ingredient[1]] = true
	end
	return result
end

local function has_all(set, names)
	for _, name in ipairs(names) do
		if not set[name] then
			return false, name
		end
	end
	return true
end

local function count(set)
	local total = 0
	for _ in pairs(set) do
		total = total + 1
	end
	return total
end

local seven = {
	"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card", "vibrant-tech-card",
	"vespera-tech-card", "beetlejuice-tech-card", "umbra-tech-card"
}

-- Edge-of-system research (no Nexus) costs all seven system cards, nothing else.
local raw = build()
for _, name in ipairs({"promethium-science-pack", "promethium-882-research", "planet-discovery-nexus",
	"planet-nexus-scanning", "black-hole-discovery"}) do
	local set = cards(raw, name)
	local ok, missing = has_all(set, seven)
	check(ok, name .. " must spend " .. tostring(missing))
	check(count(set) == 7, name .. " must spend exactly the seven system cards")
end

-- The Beetlejuice discovery stops at the Vibrant card: Vespera and Umbra come later.
local gate = cards(raw, "beetlejuice-discovery")
check(gate["vibrant-tech-card"] and not gate["vespera-tech-card"] and not gate["umbra-tech-card"]
	and not gate["beetlejuice-tech-card"], "beetlejuice-discovery keeps the cards up to Vibrant")

-- Linox research sits after Vespera, not after Vibrant.
for _, name in ipairs({"linox-technology_planet-discovery-linox",
	"linox-technology_exploring-linox-landing-site"}) do
	local set = cards(raw, name)
	local ok, missing = has_all(set, {"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card",
		"vibrant-tech-card", "vespera-tech-card"})
	check(ok, name .. " must spend " .. tostring(missing))
	check(count(set) == 5, name .. " must spend exactly five cards")
	check(not set["beetlejuice-tech-card"] and not set["umbra-tech-card"], name .. " must not spend later cards")
end

-- With Nexus the Void Processing gate also spends the Deep Space card on top of the seven.
raw = build({["Nexus-Updated"] = "1.0.0"})
local nexus_set = cards(raw, "black-hole-discovery")
check(has_all(nexus_set, seven), "With Nexus black-hole-discovery keeps the seven system cards")
check(nexus_set["deep-space-tech-card"], "With Nexus black-hole-discovery spends the Deep Space card")

print("test_late_system_cards: ok")
