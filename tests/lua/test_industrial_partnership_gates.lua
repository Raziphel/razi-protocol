package.path = "./?.lua;./?/init.lua;" .. package.path

local Graph = require("__razi_lib__/lib/technology_graph")
local module_name = "prototypes.technology.industrial_partnership_gates"
local logs = {}

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function node(parents, ingredients, effects)
	return {
		prerequisites = parents or {},
		unit = { ingredients = ingredients or { { "space-science-pack", 1 } } },
		effects = effects or {},
	}
end

local function fixture(mode)
	rawset(_G, "settings", {
		startup = { ["razi-planetary-interdependence"] = { value = mode } },
	})
	logs = {}
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)

	local techs = {
		["solaris-discovery"] = node(),
		["nyxaris-discovery"] = node(),
		["vibrant-discovery"] = node({ "solaris-discovery", "nyxaris-discovery" }),
		["vespera-discovery"] = node({ "solaris-discovery", "nyxaris-discovery" }),
		["beetlejuice-discovery"] = node({ "vibrant-discovery", "vespera-discovery" }),
		["umbra-discovery"] = node({ "vibrant-discovery", "vespera-discovery" }),
		["planet-discovery-vulcanus"] = node({ "solaris-discovery" }),
		["planet-discovery-gleba"] = node({ "nyxaris-discovery" }),
		["planet-discovery-paracelsin"] = node({ "vibrant-discovery" }),
		["planet-discovery-rubia"] = node({ "vespera-discovery" }),
		foundry = node(),
		["razi-bio-rare-metal-casting"] = node({ "planet-discovery-vulcanus", "planet-discovery-gleba", "foundry" }),
		["razi-network-bond-paracelsin-coils"] = node({ "planet-discovery-paracelsin" }),
		["razi-orbital-catapult"] = node({ "planet-discovery-rubia" }),
	}
	rawset(_G, "data", { raw = { technology = techs } })
	package.loaded[module_name] = nil
	return techs, require(module_name)
end

local function reaches_gate(techs, gate, candidate)
	return Graph.reaches(techs, gate, candidate)
end

for _, mode in ipairs({ "balanced", "deep" }) do
	local techs, partnerships = fixture(mode)
	partnerships.data_final_fixes()
	for _, gate in ipairs({ "vibrant-discovery", "vespera-discovery" }) do
		check(reaches_gate(techs, gate, "razi-bio-rare-metal-casting"),
			mode .. " must place the early workshop before " .. gate)
	end
	for _, gate in ipairs({ "beetlejuice-discovery", "umbra-discovery" }) do
		check(reaches_gate(techs, gate, "razi-network-bond-paracelsin-coils")
			and reaches_gate(techs, gate, "razi-orbital-catapult"),
			mode .. " must place both branch projects before " .. gate)
	end
	local counts = {}
	for name, tech in pairs(techs) do
		counts[name] = #tech.prerequisites
	end
	partnerships.data_final_fixes()
	for name, tech in pairs(techs) do
		check(#tech.prerequisites == counts[name], "Repeated registration duplicated links on " .. name)
	end
end

local off, off_module = fixture("off")
off_module.data_final_fixes()
for _, gate in ipairs({ "vibrant-discovery", "vespera-discovery" }) do
	check(not reaches_gate(off, gate, "razi-bio-rare-metal-casting"), "Off mode added an early partnership")
end
for _, gate in ipairs({ "beetlejuice-discovery", "umbra-discovery" }) do
	check(not reaches_gate(off, gate, "razi-network-bond-paracelsin-coils")
		and not reaches_gate(off, gate, "razi-orbital-catapult"), "Off mode added an outer partnership")
end

local missing_source, missing_source_module = fixture("balanced")
missing_source["razi-network-bond-paracelsin-coils"].prerequisites = { "planet-discovery-rubia" }
missing_source_module.data_final_fixes()
check(not reaches_gate(missing_source, "beetlejuice-discovery", "razi-network-bond-paracelsin-coils"),
	"A branch project without its own discovery must be skipped")
check(reaches_gate(missing_source, "beetlejuice-discovery", "razi-orbital-catapult"),
	"A valid project from the other branch must still be linked")

local optional_world, optional_world_module = fixture("balanced")
optional_world["razi-network-bond-paracelsin-coils"].prerequisites = {
	"planet-discovery-paracelsin", "rabbasca-underground-survey",
}
optional_world["rabbasca-underground-survey"] = node({ "planet-discovery-vulcanus" }, nil, {
	{ type = "unlock-space-location", space_location = "rabbasca-underground" },
})
optional_world_module.data_final_fixes()
check(not reaches_gate(optional_world, "beetlejuice-discovery", "razi-network-bond-paracelsin-coils"),
	"A project whose closure opens Rabbasca Underground must be skipped")
local saw_world_skip = false
for _, message in ipairs(logs) do
	if message:find("%[Razi/partnerships%] skip razi%-network%-bond%-paracelsin%-coils: requires optional world rabbasca%-underground") then
		saw_world_skip = true
	end
end
check(saw_world_skip, "Skipping an optional world must be logged")

local optional_pack, optional_pack_module = fixture("balanced")
optional_pack["razi-network-bond-paracelsin-coils"].prerequisites = {
	"planet-discovery-paracelsin", "rabbasca-pack-research",
}
optional_pack["rabbasca-pack-research"] = node({ "planet-discovery-vulcanus" }, {
	{ "athletic-science-pack", 1 },
})
optional_pack_module.data_final_fixes()
check(not reaches_gate(optional_pack, "beetlejuice-discovery", "razi-network-bond-paracelsin-coils"),
	"A project whose closure uses Rabbasca science must be skipped")
local saw_pack_skip = false
for _, message in ipairs(logs) do
	if message:find("%[Razi/partnerships%] skip razi%-network%-bond%-paracelsin%-coils: uses optional science pack athletic%-science%-pack") then
		saw_pack_skip = true
	end
end
check(saw_pack_skip, "Skipping an optional science pack must be logged")

local cyclic, cyclic_module = fixture("balanced")
cyclic["razi-bio-rare-metal-casting"].prerequisites = { "vibrant-discovery" }
cyclic_module.data_final_fixes()
check(not reaches_gate(cyclic, "vibrant-discovery", "razi-bio-rare-metal-casting"),
	"A project behind its gate must be skipped")
check(Graph.find_cycle(cyclic) == nil, "Skipping a project behind its gate must leave the graph acyclic")

local missing_candidate, missing_candidate_module = fixture("balanced")
missing_candidate["razi-bio-rare-metal-casting"] = nil
missing_candidate_module.data_final_fixes()
check(not reaches_gate(missing_candidate, "vibrant-discovery", "razi-bio-rare-metal-casting"),
	"A missing candidate must be ignored")

local missing_gate, missing_gate_module = fixture("balanced")
missing_gate["vibrant-discovery"] = nil
missing_gate_module.data_final_fixes()
check(not reaches_gate(missing_gate, "vespera-discovery", "razi-bio-rare-metal-casting"),
	"A missing paired gate must suppress that phase without errors")

print("Industrial partnership gates, optional worlds, modes and cycle safety passed")
