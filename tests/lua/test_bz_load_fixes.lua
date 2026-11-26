package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function make_arig_world(options)
	options = options or {}
	local recipes = {
		["planetaris-advanced-solar-panel"] = {
			ingredients = {
				{ type = "item", name = "iron-plate", amount = 4 },
				{ type = "item", name = "lead-expansion-bolt", amount = 8 },
			},
		},
		["planetaris-water-harvester"] = {
			ingredients = {
				{ type = "item", name = "lead-expansion-bolt", amount = 8 },
			},
		},
	}
	if options.lead_plate_amount then
		table.insert(recipes["planetaris-advanced-solar-panel"].ingredients,
			{ type = "item", name = "lead-plate", amount = options.lead_plate_amount })
	end
	if options.missing_recipe then
		recipes[options.missing_recipe] = nil
	end

	local mods = {}
	if not options.no_arig then
		mods["planetaris-arig"] = "1.1.47"
	end
	if not options.no_bzlead then
		mods.bzlead = "2.0.29"
	end
	local logs = {}
	rawset(_G, "data", { raw = {
		item = options.bolt_item and { ["lead-expansion-bolt"] = {} } or {},
		recipe = recipes,
	} })
	rawset(_G, "mods", mods)
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	return { recipes = recipes, logs = logs }
end

local function find_ingredient(recipe, name)
	for _, ingredient in ipairs(recipe.ingredients or {}) do
		if ingredient.name == name then
			return ingredient
		end
	end
end

local function make_muria_world(options)
	options = options or {}
	local before = { type = "unlock-recipe", recipe = "existing-before" }
	local missing = { type = "unlock-recipe", recipe = "casting-lead-expansion-bolt" }
	local middle = { type = "unlock-recipe", recipe = "existing-middle" }
	local after = { type = "unlock-recipe", recipe = "existing-after" }
	local effects = { before, missing, middle, after }
	local mods = {}
	if not options.no_muria then
		mods.Muria = "1.11.5"
	end
	if not options.no_bzlead then
		mods.bzlead = "2.0.29"
	end
	local recipes = {}
	if options.recipe_exists then
		recipes["casting-lead-expansion-bolt"] = {}
	end
	local logs = {}
	rawset(_G, "data", { raw = {
		recipe = recipes,
		technology = { foundry = { effects = effects } },
	} })
	rawset(_G, "mods", mods)
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	return { effects = effects, references = { before, missing, middle, after }, logs = logs }
end

local arig = require("prototypes.fixes.planetaris-arig.lead_expansion_bolt")
local muria = require("prototypes.fixes.Muria.lead_bolt_unlock")

local world = make_arig_world({ lead_plate_amount = 5 })
arig.data()
local solar = world.recipes["planetaris-advanced-solar-panel"]
local water = world.recipes["planetaris-water-harvester"]
check(find_ingredient(solar, "lead-plate").amount == 13, "the solar panel combines 8 bolts with 5 lead plates")
check(find_ingredient(solar, "lead-expansion-bolt") == nil, "the solar panel no longer needs the bolt")
check(find_ingredient(water, "lead-plate").amount == 8, "the water harvester converts its 8 bolts to lead plates")
check(find_ingredient(water, "lead-expansion-bolt") == nil, "the water harvester no longer needs the bolt")
check(#world.logs == 2 and world.logs[1] == "razi-protocol: bz: planetaris-advanced-solar-panel: lead-expansion-bolt -> lead-plate"
	and world.logs[2] == "razi-protocol: bz: planetaris-water-harvester: lead-expansion-bolt -> lead-plate",
	"each changed Arig recipe is logged")
arig.data()
check(#world.logs == 2, "the Arig fix is idempotent")

world = make_arig_world({ bolt_item = true })
local solar_ingredients = world.recipes["planetaris-advanced-solar-panel"].ingredients
arig.data()
check(find_ingredient(world.recipes["planetaris-advanced-solar-panel"], "lead-expansion-bolt") ~= nil
	and #world.logs == 0 and solar_ingredients[2].name == "lead-expansion-bolt",
	"an existing bolt item leaves Arig recipes untouched")

world = make_arig_world({ no_bzlead = true })
arig.data()
check(find_ingredient(world.recipes["planetaris-water-harvester"], "lead-expansion-bolt") ~= nil and #world.logs == 0,
	"without bzlead Arig recipes stay untouched")

world = make_arig_world({ no_arig = true })
arig.data()
check(find_ingredient(world.recipes["planetaris-water-harvester"], "lead-expansion-bolt") ~= nil and #world.logs == 0,
	"without Arig recipes stay untouched")

world = make_arig_world({ missing_recipe = "planetaris-advanced-solar-panel" })
arig.data()
check(world.recipes["planetaris-advanced-solar-panel"] == nil
	and find_ingredient(world.recipes["planetaris-water-harvester"], "lead-plate").amount == 8
	and #world.logs == 1,
	"a missing Arig recipe is skipped while the other is fixed")

world = make_muria_world()
muria.data_final_fixes()
check(#world.effects == 3 and world.effects[1] == world.references[1]
	and world.effects[2] == world.references[3] and world.effects[3] == world.references[4],
	"Muria's missing unlock is removed while neighboring effects keep their order")
check(#world.logs == 1
	and world.logs[1] == "razi-protocol: bz: foundry: dropped the unlock of missing casting-lead-expansion-bolt",
	"the removed Muria unlock is logged")

world = make_muria_world({ recipe_exists = true })
muria.data_final_fixes()
check(#world.effects == 4 and world.effects[2] == world.references[2] and #world.logs == 0,
	"an existing casting recipe keeps Muria's unlock")

world = make_muria_world({ no_muria = true })
muria.data_final_fixes()
check(#world.effects == 4 and world.effects[2] == world.references[2] and #world.logs == 0,
	"without Muria its technology effects stay untouched")

world = make_muria_world({ no_bzlead = true })
muria.data_final_fixes()
check(#world.effects == 4 and world.effects[2] == world.references[2] and #world.logs == 0,
	"without bzlead its technology effects stay untouched")

print("test_bz_load_fixes: ok")
