-- Research gates of the seven systems (technology/seven_system_gates.lua, technology/system_gate_links.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_seven_system_gates.lua
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

local cards = {
	"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card", "vibrant-tech-card",
	"vespera-tech-card", "beetlejuice-tech-card", "umbra-tech-card"
}

local logged = {}
local function technology(name, prerequisites, unlocks, packs, trigger)
	local effects = {}
	for _, recipe in ipairs(unlocks or {}) do
		effects[#effects + 1] = {type = "unlock-recipe", recipe = recipe}
	end
	local ingredients = {}
	for _, pack in ipairs(packs or {}) do
		ingredients[#ingredients + 1] = {pack, 1}
	end
	return {type = "technology", name = name, prerequisites = prerequisites or {}, effects = effects,
		unit = not trigger and {count = 10, time = 30, ingredients = ingredients} or nil,
		research_trigger = trigger}
end

local function build(list, recipes)
	local raw = {technology = {}, item = {}, recipe = recipes or {}}
	for _, card in ipairs(cards) do
		raw.item[card] = {type = "item", name = card}
	end
	for _, definition in ipairs(list) do
		raw.technology[definition.name] = definition
	end
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", {})
	logged = {}
	rawset(_G, "log", function(message) logged[#logged + 1] = message end)
	for _, module in ipairs({"prototypes.technology.gates.seven_system_gates", "prototypes.technology.gates.system_gate_links"}) do
		package.loaded[module] = nil
	end
	require("prototypes.technology.gates.seven_system_gates").data_final_fixes()
	require("prototypes.technology.gates.system_gate_links").data_final_fixes()
	return raw.technology
end

local function has_cycle(technologies)
	local state = {}
	local function visit(name)
		state[name] = 1
		for _, parent in ipairs(technologies[name].prerequisites or {}) do
			if technologies[parent] then
				if state[parent] == 1 then return true end
				if not state[parent] and visit(parent) then return true end
			end
		end
		state[name] = 2
		return false
	end
	for name in pairs(technologies) do
		if not state[name] and visit(name) then return true end
	end
	return false
end

-- (a) A trigger research becomes a priced one; the prerequisites are replaced and absent ones are dropped.
local techs = build({
	technology("space-science-pack"),
	technology("solaris-discovery", {"planet-discovery-fulgora"}, nil, nil, {type = "build-entity", entity = "lab"}),
	technology("nyxaris-discovery", {"planet-discovery-corrundum"}),
	technology("planet-discovery-vulcanus", {"asteroid-collector"}),
	technology("planet-discovery-castra", {"solaris-discovery"}, {"solaris-tech-card"}, {"calidus-tech-card"}),
	technology("vibrant-discovery", {"planet-discovery-missing"})
})
check(techs["solaris-discovery"].research_trigger == nil, "The trigger must be replaced by a price")
check(techs["solaris-discovery"].unit.count == 650, "Solaris costs 650 units")
check(techs["solaris-discovery"].unit.ingredients[1][1] == "calidus-tech-card", "Solaris costs the Calidus card")
check(techs["solaris-discovery"].prerequisites[1] == "space-science-pack" and #techs["solaris-discovery"].prerequisites == 1,
	"Solaris follows the space science pack only")
check(#techs["planet-discovery-vulcanus"].prerequisites == 1 and techs["planet-discovery-vulcanus"].prerequisites[1] == "solaris-discovery",
	"Vulcanus follows Solaris")
check(not contains(techs["vibrant-discovery"].prerequisites, "planet-discovery-missing"), "An absent prerequisite is dropped")
check(not has_cycle(techs), "The gates must not create a cycle")

-- (b) A replacement that would close a cycle is dropped.
techs = build({
	technology("space-science-pack"),
	technology("nyxaris-discovery"),
	technology("planet-discovery-gleba", {"planet-discovery-apia-carnova"}),
	technology("planet-discovery-apia-carnova", {"planet-discovery-gleba"})
})
check(not has_cycle(techs), "Mutually dependent technologies stay acyclic")

-- (c) Aquilo follows Rubia although Rubia used to follow Aquilo.
techs = build({
	technology("space-science-pack"),
	technology("planet-discovery-muria"),
	technology("planet-discovery-aquilo", {"vibrant-discovery"}),
	technology("planet-discovery-rubia", {"planet-discovery-aquilo"})
})
check(contains(techs["planet-discovery-aquilo"].prerequisites, "planet-discovery-rubia"), "Aquilo must follow Rubia")
check(contains(techs["planet-discovery-rubia"].prerequisites, "planet-discovery-muria"), "Rubia follows Muria")
check(not has_cycle(techs), "Aquilo and Rubia stay acyclic")

-- (d) A technology priced in a card gets the technology that unlocks the card.
techs = build({
	technology("space-science-pack"),
	technology("planet-discovery-castra", {"solaris-discovery"}, {"solaris-tech-card"}, {"calidus-tech-card"}),
	technology("solaris-discovery", {"space-science-pack"}),
	technology("nyxaris-discovery", {"space-science-pack"}),
	technology("system-discovery-dea-dia", {"nyxaris-discovery"}),
	technology("planet-discovery-dea-dia", {"system-discovery-dea-dia"}, nil, {"solaris-tech-card"})
})
check(contains(techs["planet-discovery-dea-dia"].prerequisites, "planet-discovery-castra"), "The Solaris card needs Castra")
check(not has_cycle(techs), "Card links stay acyclic")

-- (e) A technology that unlocks the card and is priced in it gets no self-link.
techs = build({
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}, {"solaris-tech-card"})
})
check(#techs["planet-discovery-castra"].prerequisites == 0, "No self-link")

-- (f) A technology priced in a planet pack keeps the research that unlocks the pack.
techs = build({
	technology("space-science-pack"),
	technology("metallurgic-science-pack", {}, {"metallurgic-science-pack"}),
	technology("tungsten-flow", {"space-science-pack"}, nil, {"metallurgic-science-pack"}),
	technology("tungsten-after", {"metallurgic-science-pack"}, nil, {"metallurgic-science-pack"})
})
check(contains(techs["tungsten-flow"].prerequisites, "metallurgic-science-pack"), "The pack research is restored")
check(#techs["tungsten-after"].prerequisites == 1, "An ancestor pack research is not repeated")
check(not has_cycle(techs), "Pack links stay acyclic")

-- (g) A pack whose research needs the card it is part of is dropped from the card recipe.
local function recipe(name, ingredients, enabled)
	local list = {}
	for _, ingredient in ipairs(ingredients) do
		list[#list + 1] = {type = "item", name = ingredient, amount = 1}
	end
	return {type = "recipe", name = name, ingredients = list, enabled = enabled}
end
build({
	technology("space-science-pack"),
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}, {"calidus-tech-card"}),
	technology("vibrant-discovery", {"planet-discovery-castra"}, nil, {"solaris-tech-card"}),
	technology("pack-research", {"vibrant-discovery"}, {"loop-pack"}, {"space-science-pack"}),
	technology("safe-research", {}, {"safe-pack"}, {"space-science-pack"}),
	technology("late-research", {"pack-research", "safe-research"}, nil, {"loop-pack", "safe-pack"})
}, {
	["solaris-tech-card"] = recipe("solaris-tech-card", {"loop-pack", "safe-pack", "space-science-pack"})
})
local solaris = data.raw.recipe["solaris-tech-card"]
local kept = solaris.ingredients or {}
check(#kept == 2, "Only the looping pack is dropped")
check((kept[1] or {}).name == "safe-pack" and (kept[2] or {}).name == "space-science-pack", "The other packs stay")
local removal_logged = false
for _, message in ipairs(logged) do
	removal_logged = removal_logged or string.find(message, "solaris-tech-card no longer needs loop-pack", 1, true) ~= nil
end
check(removal_logged, "The removal is logged")

-- (h) A recipe that is enabled from the start waits for no research: a technology that unlocks it again
-- (Foliax and copper cable) is not a way from a pack to the card. Ribbonia prices technologies in plain items,
-- which puts such items among the packs the cycle search walks through.
build({
	technology("space-science-pack"),
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}, {"calidus-tech-card"}),
	technology("reunlock-cable", {"planet-discovery-castra"}, {"cable"}),
	technology("cable-user", {}, nil, {"cable"}),
	technology("chem-research", {}, {"chem-pack"}, {"space-science-pack"}),
	technology("late-research", {"chem-research"}, nil, {"chem-pack", "safe-pack"})
}, {
	["calidus-tech-card"] = recipe("calidus-tech-card", {"chem-pack", "safe-pack", "space-science-pack"}),
	["chem-pack"] = recipe("chem-pack", {"cable"}, false),
	["cable"] = recipe("cable", {}, true)
})
local calidus = data.raw.recipe["calidus-tech-card"].ingredients
check(#calidus == 3, "An unlock of a recipe that is enabled from the start does not drop a pack from the card")
for _, message in ipairs(logged) do
	check(not string.find(message, "calidus-tech-card no longer needs", 1, true), "No pack is dropped: " .. message)
end

-- (h2) A recipe that several technologies unlock is available after the first of them: a late alternative
-- (Foliax and steel plate) does not make the packs made from it wait for the card.
build({
	technology("space-science-pack"),
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}, {"calidus-tech-card"}),
	technology("steel-processing", {}, {"steel"}),
	technology("late-steel", {"planet-discovery-castra"}, {"steel"}),
	technology("steel-user", {}, nil, {"steel"}),
	technology("chem-research", {}, {"chem-pack"}, {"space-science-pack"}),
	technology("late-research", {"chem-research"}, nil, {"chem-pack", "safe-pack"})
}, {
	["calidus-tech-card"] = recipe("calidus-tech-card", {"chem-pack", "safe-pack", "space-science-pack"}),
	["chem-pack"] = recipe("chem-pack", {"steel"}, false),
	["steel"] = recipe("steel", {}, false)
})
check(#data.raw.recipe["calidus-tech-card"].ingredients == 3, "A late second unlock does not drop a pack from the card")

-- (h3) When every technology that unlocks the recipe waits for the card, the pack does wait for it.
build({
	technology("space-science-pack"),
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}, {"calidus-tech-card"}),
	technology("late-steel", {"planet-discovery-castra"}, {"steel"}),
	technology("later-steel", {"planet-discovery-castra"}, {"steel"}),
	technology("steel-user", {}, nil, {"steel"}),
	technology("chem-research", {}, {"chem-pack"}, {"space-science-pack"}),
	technology("late-research", {"chem-research"}, nil, {"chem-pack", "safe-pack"})
}, {
	["calidus-tech-card"] = recipe("calidus-tech-card", {"chem-pack", "safe-pack", "space-science-pack"}),
	["chem-pack"] = recipe("chem-pack", {"steel"}, false),
	["steel"] = recipe("steel", {}, false)
})
check(#data.raw.recipe["calidus-tech-card"].ingredients == 2, "A pack whose every unlock waits for the card is dropped")

-- (i) A cycle that would take all but one ingredient from a card is not broken: the card keeps its recipe and the
-- log says so, instead of the card turning into its one-pack fallback.
build({
	technology("space-science-pack"),
	technology("planet-discovery-castra", {}, {"solaris-tech-card"}, {"calidus-tech-card"}),
	technology("loop-research", {"planet-discovery-castra"}, {"loop-pack"}, {"space-science-pack"}),
	technology("loop-two-research", {"planet-discovery-castra"}, {"loop-two"}, {"space-science-pack"}),
	technology("late-research", {"loop-research", "loop-two-research"}, nil, {"loop-pack", "loop-two"})
}, {
	["calidus-tech-card"] = recipe("calidus-tech-card", {"loop-pack", "loop-two"}),
	["loop-pack"] = recipe("loop-pack", {}, false),
	["loop-two"] = recipe("loop-two", {}, false)
})
check(#data.raw.recipe["calidus-tech-card"].ingredients == 2, "A card is not stripped below two ingredients")
local reported_error = false
for _, message in ipairs(logged) do
	reported_error = reported_error or (string.find(message, "ERROR: calidus-tech-card needs loop-pack", 1, true) ~= nil
		and string.find(message, "loop-research", 1, true) ~= nil)
end
check(reported_error, "The cycle that is left is logged as an error with its chain")

print("test_seven_system_gates: ok")
