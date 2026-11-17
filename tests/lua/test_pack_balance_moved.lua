---@diagnostic disable: missing-fields, need-check-nil, inject-field, undefined-field
-- Fixes and balance taken over from the pack's fix mod, on a mocked data.raw: Panglia's flesh tooltip, the Cerys
-- recycling of the advanced circuit, the biomass fuel category of Krastorio 2 and the Planetaris colored walls.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path
local support = require("tests.lua.loops_support")
local check = support.check
local loops = require("prototypes.balance.resource_loops")

-- Panglia: the residue smoke of rotting flesh shows in the tooltip.
local flesh_tooltip = require("prototypes.fixes.panglia_planet.flesh_spoil_tooltip")
local raw = support.install({}, {}, {
	item = { biter_dna_sample = { spoil_to_trigger_result = { trigger = { type = "direct", action_delivery = {
		type = "instant", source_effects = {
			{ type = "create-smoke", show_in_tooltip = false, entity_name = "biter_dna_sample_decomposition" },
			{ type = "create-smoke", show_in_tooltip = false, entity_name = "other-smoke" },
		} } } } } },
	["smoke-with-trigger"] = { biter_dna_sample_decomposition = {} },
})
flesh_tooltip.data_final_fixes()
local effects = raw.item.biter_dna_sample.spoil_to_trigger_result.trigger.action_delivery.source_effects
check(effects[1].show_in_tooltip == true and effects[2].show_in_tooltip == false, "Only the residue smoke is shown")
check(support.logged("biter_dna_sample spoil tooltip shows") == 1, "The change is logged")
support.install({}, {}, { item = { biter_dna_sample = {} } })
flesh_tooltip.data_final_fixes()
check(#support.logs == 0, "Without the smoke nothing changes")

-- Cerys: the hand-written circuit recycling is divided by the two circuits Krastorio 2 makes per craft.
local function circuits()
	return {
		["advanced-circuit"] = { results = { { type = "item", name = "advanced-circuit", amount = 2 } } },
		["advanced-circuit-recycling"] = { results = {
			{ type = "item", name = "copper-cable", amount = 1 },
			{ type = "item", name = "electronic-circuit", amount = 1 },
			{ type = "item", name = "kr-electronic-components", amount = 0, extra_count_fraction = 0.5 } } },
	}
end
local static_recycling = require("prototypes.balance.Cerys-Moon-of-Fulgora.static_recycling")
raw = support.install(circuits())
static_recycling.data_final_fixes()
local returned = raw.recipe["advanced-circuit-recycling"].results
check(returned[1].amount == 0 and returned[1].extra_count_fraction == 0.5 and returned[3].extra_count_fraction == 0.25,
	"1 circuit returns 0.5 cable, 0.5 circuit and 0.25 components")
support.logs = {}
static_recycling.data_final_fixes()
check(#support.logs == 0, "A second run changes nothing")
local one = circuits()
one["advanced-circuit"].results[1].amount = 1
raw = support.install(one)
static_recycling.data_final_fixes()
check(raw.recipe["advanced-circuit-recycling"].results[1].amount == 1, "With one circuit per craft the recycling stays")
support.gate(loops, circuits, function(data_raw)
	return data_raw.recipe["advanced-circuit-recycling"].results[3].extra_count_fraction == 0.25
end)
support.no_settings()

-- Krastorio 2: biomass is its own fuel, which chemical burners take and locomotives do not.
rawset(_G, "data", nil)
local biomass_fuel = require("prototypes.balance.Krastorio2.biomass_fuel")
raw = support.install({}, {}, {
	item = { ["kr-biomass"] = { fuel_value = "2MJ", fuel_categories = { "chemical" } } },
	["fuel-category"] = { chemical = {} },
	["burner-generator"] = { furnace = { burner = { type = "burner", fuel_categories = { "chemical" } } } },
	car = { car = { energy_source = { fuel_categories = { "chemical", "kr-vehicle-fuel" } } } },
	locomotive = { locomotive = { energy_source = { type = "burner", fuel_categories = { "chemical" } } } },
	["assembling-machine"] = { assembler = { energy_source = { type = "electric" } } },
})
data.extend = function(_, prototypes)
	for _, prototype in ipairs(prototypes) do
		raw[prototype.type][prototype.name] = prototype
	end
end
biomass_fuel.data_final_fixes()
check(raw["fuel-category"]["kr-biomass"] ~= nil, "The fuel category exists")
check(raw.item["kr-biomass"].fuel_categories[1] == "kr-biomass" and #raw.item["kr-biomass"].fuel_categories == 1,
	"Biomass burns as kr-biomass")
check(raw["burner-generator"].furnace.burner.fuel_categories[2] == "kr-biomass", "A chemical burner takes biomass")
check(raw.car.car.energy_source.fuel_categories[3] == "kr-biomass", "A car takes biomass")
check(#raw.locomotive.locomotive.energy_source.fuel_categories == 1, "A locomotive does not")
check(raw["assembling-machine"].assembler.energy_source.fuel_categories == nil, "An electric machine is left alone")
support.logs = {}
biomass_fuel.data_final_fixes()
check(#support.logs == 0 and #raw.car.car.energy_source.fuel_categories == 3, "A second run changes nothing")

-- Planetaris Dyes: 5 stone walls make 5 colored walls.
local colored_walls = require("prototypes.balance.planetaris-dyes.colored_walls")
raw = support.install({
	["planetaris-red-stone-wall"] = { results = { { type = "item", name = "planetaris-red-stone-wall", amount = 10 } } },
	["planetaris-red-dye"] = { results = { { type = "item", name = "planetaris-red-dye", amount = 10 } } },
})
colored_walls.data_final_fixes()
check(raw.recipe["planetaris-red-stone-wall"].results[1].amount == 5, "A colored wall recipe makes 5")
check(raw.recipe["planetaris-red-dye"].results[1].amount == 10, "The dye recipe is left alone")

rawset(_G, "data", nil)
print("test_pack_balance_moved: ok")
