---@diagnostic disable: missing-fields, lowercase-global, inject-field
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
	if not condition then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(line)
	logs[#logs + 1] = line
end)

local function reset_logs()
	logs = {}
end

local winch = require("prototypes.compatibility.VehicleWagon2.winch")
local no_item_spiders = require("prototypes.fixes.VehicleWagon2.no_item_spiders")
local vehicle_variant_items = require("prototypes.fixes.PlanetsLib.vehicle_variant_items")
local vehicle_wagon_copy = require("prototypes.fixes.tenebris-prime.vehicle_wagon_copy")

-- The winch only adds same-force to the two default any-entity selections.
---@type table
local winch_tool = {
	select = { mode = "any-entity" },
	alt_select = { mode = "any-entity" },
}
rawset(_G, "data", { raw = { ["selection-tool"] = { ["winch-tool"] = winch_tool } } })
rawset(_G, "mods", { VehicleWagon2 = "4.2.3" })
reset_logs()
winch.data_final_fixes()
check(winch_tool.select.mode[1] == "any-entity" and winch_tool.select.mode[2] == "same-force", "select must use any-entity and same-force")
check(winch_tool.alt_select.mode[1] == "any-entity" and winch_tool.alt_select.mode[2] == "same-force", "alt_select must use any-entity and same-force")
check(#logs == 2, "the two winch changes must be logged")

winch_tool = { select = { mode = "any-entity" }, alt_select = { mode = "nothing" } }
rawset(_G, "data", { raw = { ["selection-tool"] = { ["winch-tool"] = winch_tool } } })
rawset(_G, "mods", {})
reset_logs()
winch.data_final_fixes()
check(winch_tool.select.mode == "any-entity" and winch_tool.alt_select.mode == "nothing" and #logs == 0,
	"without VehicleWagon2 the winch must stay untouched")
rawset(_G, "mods", { VehicleWagon2 = "4.2.3" })
winch.data_final_fixes()
check(winch_tool.select.mode[1] == "any-entity" and winch_tool.select.mode[2] == "same-force"
	and winch_tool.alt_select.mode == "nothing", "a non-default winch mode must stay untouched")

-- Spiders with no item and no placeable_by are moved above the wagon limit.
local spiders = {
	no_item = { weight = 1 },
	default_weight = {},
	item_backed = { weight = 1 },
	single_placeable = { weight = 1, placeable_by = { item = "x", count = 1 } },
	array_placeable = { weight = 1, placeable_by = { { item = "x", count = 1 } } },
	already_heavy = { weight = 100000 },
}
local cars = { no_item_car = { weight = 1 } }
rawset(_G, "data", { raw = {
	["spider-vehicle"] = spiders,
	car = cars,
	["item-with-entity-data"] = { spider_item = { place_result = "item_backed" } },
} })
rawset(_G, "mods", { VehicleWagon2 = "4.2.3" })
rawset(_G, "settings", { startup = { ["vehicle-wagon-maximum-weight"] = { value = 75000 } } })
reset_logs()
no_item_spiders.data_final_fixes()
check(spiders.no_item.weight == 75001 and spiders.default_weight.weight == 75001, "unplaceable spiders must exceed the wagon limit")
check(spiders.item_backed.weight == 1, "an item with entity data must protect its spider")
check(spiders.single_placeable.weight == 1 and spiders.array_placeable.weight == 1, "placeable_by must protect single and array forms")
check(spiders.already_heavy.weight == 100000 and cars.no_item_car.weight == 1, "heavy spiders and cars must stay untouched")
check(#logs == 2, "each adjusted spider must be logged")

local no_mod_spider = { weight = 1 }
rawset(_G, "data", { raw = { ["spider-vehicle"] = { no_mod = no_mod_spider } } })
rawset(_G, "mods", {})
no_item_spiders.data_final_fixes()
check(no_mod_spider.weight == 1, "without VehicleWagon2 spiders must stay untouched")
rawset(_G, "mods", { VehicleWagon2 = "4.2.3" })
rawset(_G, "settings", { startup = {} })
no_item_spiders.data_final_fixes()
check(no_mod_spider.weight == 1, "without the maximum-weight setting spiders must stay untouched")
rawset(_G, "settings", { startup = { ["vehicle-wagon-maximum-weight"] = { value = 1e30 } } })
reset_logs()
no_item_spiders.data_final_fixes()
check(no_mod_spider.weight == 1 and #logs == 1, "an unlimited wagon limit must leave spiders unchanged and log once")

-- PlanetsLib vehicle variants inherit the item that places their base entity.
local boat_variant = {}
local existing_variant = { placeable_by = { { item = "existing", count = 1 } } }
local dummy_variant = {}
local unrelated = {}
local fallback_variant = {}
rawset(_G, "data", { raw = {
	car = {
		["indep-boat"] = {},
		["indep-boat-PlanetsLib-muluna"] = boat_variant,
		["indep-boat-PlanetsLib-fulgora"] = existing_variant,
		["plain-boat"] = unrelated,
		["placeable-base"] = { placeable_by = { item = "base-item", count = 1 } },
		["placeable-base-PlanetsLib-muluna"] = fallback_variant,
	},
	["spider-vehicle"] = {
		["spidertron-enhancements-dummy-x"] = {},
		["spidertron-enhancements-dummy-x-PlanetsLib-muluna"] = dummy_variant,
	},
	item = {
		z_boat = { place_result = "indep-boat" },
		a_boat = { place_result = "indep-boat" },
	},
	ammo = { boat_ammo = { place_result = "indep-boat" } },
} })
reset_logs()
vehicle_variant_items.data_final_fixes()
check(boat_variant.placeable_by and boat_variant.placeable_by[1].item == "a_boat"
	and boat_variant.placeable_by[1].count == 1, "a variant must use the alphabetically first item for its base")
check(existing_variant.placeable_by[1].item == "existing", "a variant with placeable_by must stay unchanged")
check(dummy_variant.placeable_by == nil, "a variant whose base has no item must stay unchanged")
check(unrelated.placeable_by == nil, "an entity without a PlanetsLib suffix must stay unchanged")
check(fallback_variant.placeable_by[1].item == "base-item" and #logs == 2,
	"a variant must fall back to the base placeable_by item")

-- The unusable Tenebris wagon recipe is hidden and loses its technology unlock.
---@type table
local recipe = { enabled = true }
---@type table
local effects = {
	{ type = "unlock-recipe", recipe = "bioluminescent-vehicle-wagon" },
	{ type = "unlock-recipe", recipe = "neighboring-recipe" },
	{ type = "unlock-recipe", recipe = "bioluminescent-vehicle-wagon" },
}
rawset(_G, "data", { raw = {
	recipe = { ["bioluminescent-vehicle-wagon"] = recipe },
	technology = { bioinfusor = { effects = effects } },
} })
rawset(_G, "mods", { VehicleWagon2 = "4.2.3" })
reset_logs()
vehicle_wagon_copy.data_final_fixes()
check(recipe.hidden == true and recipe.enabled == false, "the Tenebris vehicle wagon recipe must be hidden and disabled")
check(#effects == 1 and effects[1].recipe == "neighboring-recipe", "only the Tenebris vehicle wagon unlock must be removed")
check(#logs == 1, "the recipe change must be logged")

recipe = { enabled = true }
effects = { { type = "unlock-recipe", recipe = "bioluminescent-vehicle-wagon" } }
rawset(_G, "data", { raw = {
	recipe = { ["bioluminescent-vehicle-wagon"] = recipe },
	technology = { bioinfusor = { effects = effects } },
} })
rawset(_G, "mods", {})
vehicle_wagon_copy.data_final_fixes()
check(recipe.hidden == nil and recipe.enabled == true and #effects == 1, "without VehicleWagon2 the Tenebris recipe must stay intact")
rawset(_G, "mods", { VehicleWagon2 = "4.2.3" })
rawset(_G, "data", { raw = { recipe = {}, technology = {} } })
vehicle_wagon_copy.data_final_fixes()

print("test_vehicle_wagon: ok")
