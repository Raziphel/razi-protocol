---@diagnostic disable: undefined-field
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

if not table.deepcopy then
	local function deepcopy(value)
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for key, child in pairs(value) do
			copy[deepcopy(key)] = deepcopy(child)
		end
		return copy
	end
	rawset(table, "deepcopy", deepcopy) -- luacheck: ignore 122
end

local technologies = {}
local items = {}
local function add_technology(name)
	technologies[name] = {
		icon = "__base__/graphics/technology/automation.png",
		icon_size = 256,
		prerequisites = {},
		unit = {count = 100, ingredients = {{"automation-science-pack", 1}}, time = 30},
	}
end

for _, name in ipairs({
	"stellar-discovery-solar-system-edge",
	"razi-intergalactic-transceiver-signal",
	"slp-dyson-sphere",
	"discovery-aegis-outer",
	"promethium-science-pack",
	"razi-network-extreme-lattice",
	"slp-dyson-sphere-grounded",
	"ds-energy-loader-mk2",
	"radar",
}) do
	add_technology(name)
end

for _, name in ipairs({
	"slp-ds-satellite", "holmium-plate", "tungsten-plate", "processing-unit",
	"low-density-structure", "superconductor", "lithium-plate", "kr-rare-metals",
	"optical-cable", "craptonite-frame", "chitosan", "zinc-plate", "electric-coil",
	"rare-earth-powder", "promethium-science-pack", "kr-cryogenic-research-data",
	"kr-electromagnetic-research-data", "kr-agricultural-research-data",
	"planet-crucible-science-pack", "pulsar-science-pack", "supermagnet", "gold-plate",
	"kr-energy-control-unit", "kr-singularity-tech-card", "deep-space-tech-card",
	"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card", "vibrant-tech-card",
	"vespera-tech-card", "beetlejuice-tech-card", "umbra-tech-card",
	"antimatter-science-pack",
}) do
	items[name] = {icon = "__base__/graphics/icons/iron-plate.png", icon_size = 64}
end

rawset(_G, "data", {raw = {technology = technologies, item = items}})
function data:extend(prototypes)
	for _, prototype in ipairs(prototypes) do
		self.raw[prototype.type] = self.raw[prototype.type] or {}
		check(not self.raw[prototype.type][prototype.name], "duplicate prototype " .. prototype.name)
		self.raw[prototype.type][prototype.name] = prototype
	end
end

local convergence = require("prototypes.technology.convergence")
convergence.data_final_fixes()
require("prototypes.technology.convergence_witness").data_final_fixes()

local commission = assert(technologies[convergence.commission], "missing first Convergence technology")
local synchronization = assert(technologies[convergence.authorization], "missing second Convergence technology")
local ignition = assert(technologies[convergence.ignition], "missing third Convergence technology")
local witness = assert(technologies["razi-convergence-witness-network"], "missing witness technology")

local function has(values, expected)
	for _, value in ipairs(values or {}) do
		if value == expected then
			return true
		end
	end
	return false
end

check(#convergence.shipments == 5, "expected five native shipment milestones")
check(has(commission.prerequisites, "stellar-discovery-solar-system-edge"), "commission needs its stellar-discovery prerequisite")
check(has(commission.prerequisites, "slp-dyson-sphere"), "commission needs the Dyson prerequisite")
check(has(commission.prerequisites, "discovery-aegis-outer"), "commission needs the Aegis prerequisite")
check(has(synchronization.prerequisites, convergence.commission), "synchronization must follow commission")
check(has(synchronization.prerequisites, "promethium-science-pack"), "synchronization needs Promethium research")
check(has(synchronization.prerequisites, "razi-network-extreme-lattice"), "synchronization needs the native extreme lattice when available")
check(has(ignition.prerequisites, convergence.authorization), "ignition must follow synchronization")
check(has(ignition.prerequisites, "slp-dyson-sphere-grounded"), "ignition needs grounded Dyson research")
check(has(ignition.prerequisites, "ds-energy-loader-mk2"), "ignition needs the native energy loader")
check(has(ignition.prerequisites, witness.name), "ignition must follow the witness milestone")
check(has(witness.prerequisites, convergence.authorization), "witness milestone must follow synchronization")
check(commission.unit.count == 2400 and synchronization.unit.count == 4200
	and ignition.unit.count == 5000 and witness.unit.count == 3200,
	"Convergence research costs changed")
for _, prototype in ipairs({commission, synchronization, ignition, witness}) do
	check(#prototype.effects == 0, prototype.name .. " must not add effects")
	check(prototype.essential == true, prototype.name .. " must be marked essential")
end

local technology_count = 0
for _ in pairs(technologies) do
	technology_count = technology_count + 1
end
convergence.data_final_fixes()
require("prototypes.technology.convergence_witness").data_final_fixes()
local after_repeat = 0
for _ in pairs(technologies) do
	after_repeat = after_repeat + 1
end
check(after_repeat == technology_count, "repeated data-final-fixes added duplicate technologies")
check(data.raw.recipe == nil, "Convergence technology prototypes must not add recipes")

print("Convergence prototypes: three technologies and witness node passed")
