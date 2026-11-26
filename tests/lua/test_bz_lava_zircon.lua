---@diagnostic disable: undefined-field
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function make_world(options)
	options = options or {}
	local raw = {
		item = options.no_zircon and {} or { zircon = {} },
		recipe = {
			["stone-from-lava"] = {
				name = "stone-from-lava",
				categories = { "metallurgy" },
				results = { { type = "item", name = "stone", amount = 25 } },
			},
			["molten-iron-from-lava"] = {
				name = "molten-iron-from-lava",
				categories = { "metallurgy" },
				results = {
					{ type = "fluid", name = "molten-iron", amount = 500 },
					{ type = "item", name = "stone", amount = 10 },
				},
			},
			["molten-copper-from-lava"] = {
				name = "molten-copper-from-lava",
				categories = { "metallurgy" },
				results = {
					{ type = "fluid", name = "molten-copper", amount = 250 },
					{ type = "item", name = "stone", amount = 15 },
				},
			},
			["molten-lead-from-lava"] = {
				name = "molten-lead-from-lava",
				categories = { "metallurgy" },
				results = {
					{ type = "fluid", name = "molten-lead", amount = 500 },
					{ type = "item", name = "stone", amount = 10 },
				},
			},
			["already-has-zircon-from-lava"] = {
				name = "already-has-zircon-from-lava",
				categories = { "metallurgy" },
				results = {
					{ type = "item", name = "stone", amount = 20 },
					{ type = "item", name = "zircon", amount = 10 },
				},
			},
			["wrong-category-from-lava"] = {
				name = "wrong-category-from-lava",
				categories = { "crafting" },
				results = { { type = "item", name = "stone", amount = 20 } },
			},
			["probabilistic-stone-from-lava"] = {
				name = "probabilistic-stone-from-lava",
				categories = { "metallurgy" },
				results = { { type = "item", name = "stone", amount = 20, probability = 0.5 } },
			},
			["ranged-stone-from-lava"] = {
				name = "ranged-stone-from-lava",
				categories = { "metallurgy" },
				results = { { type = "item", name = "stone", amount_min = 2, amount_max = 20 } },
			},
			["single-stone-from-lava"] = {
				name = "single-stone-from-lava",
				categories = { "metallurgy" },
				results = { { type = "item", name = "stone", amount = 1 } },
			},
		},
	}
	if options.no_recipes then
		raw.recipe = nil
	end

	local logs = {}
	rawset(_G, "mods", options.no_bzzirconium and {} or { bzzirconium = "2.1.14" })
	rawset(_G, "data", { raw = raw })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	return { raw = raw, logs = logs }
end

local lava_zircon = require("prototypes.fixes.bzzirconium.lava_zircon")

local world = make_world()
lava_zircon.data_final_fixes()
local recipes = world.raw.recipe
check(recipes["stone-from-lava"].results[1].amount == 13
	and recipes["stone-from-lava"].results[2].name == "zircon"
	and recipes["stone-from-lava"].results[2].amount == 12
	and recipes["stone-from-lava"].main_product == "stone",
	"stone-from-lava splits 25 stone into 13 stone and 12 zircon, keeping stone as main product")
check(recipes["molten-copper-from-lava"].results[1].type == "fluid"
	and recipes["molten-copper-from-lava"].results[1].name == "molten-copper"
	and recipes["molten-copper-from-lava"].results[1].amount == 250
	and recipes["molten-copper-from-lava"].results[2].amount == 8
	and recipes["molten-copper-from-lava"].results[3].name == "zircon"
	and recipes["molten-copper-from-lava"].results[3].amount == 7
	and recipes["molten-copper-from-lava"].main_product == nil,
	"molten-copper-from-lava preserves its fluid and splits stone without setting a main product")
check(recipes["molten-iron-from-lava"].results[1].type == "fluid"
	and recipes["molten-iron-from-lava"].results[1].name == "molten-iron"
	and recipes["molten-iron-from-lava"].results[1].amount == 500
	and recipes["molten-iron-from-lava"].results[2].name == "stone"
	and recipes["molten-iron-from-lava"].results[2].amount == 5
	and recipes["molten-iron-from-lava"].results[3].name == "zircon"
	and recipes["molten-iron-from-lava"].results[3].amount == 5
	and recipes["molten-iron-from-lava"].main_product == nil,
	"molten-iron-from-lava preserves its fluid and splits stone without setting a main product")
check(recipes["molten-lead-from-lava"].results[1].type == "fluid"
	and recipes["molten-lead-from-lava"].results[1].name == "molten-lead"
	and recipes["molten-lead-from-lava"].results[1].amount == 500
	and recipes["molten-lead-from-lava"].results[2].name == "stone"
	and recipes["molten-lead-from-lava"].results[2].amount == 5
	and recipes["molten-lead-from-lava"].results[3].name == "zircon"
	and recipes["molten-lead-from-lava"].results[3].amount == 5
	and recipes["molten-lead-from-lava"].main_product == nil,
	"molten-lead-from-lava preserves its fluid and splits stone without setting a main product")
check(recipes["already-has-zircon-from-lava"].results[1].amount == 20
	and #recipes["already-has-zircon-from-lava"].results == 2,
	"a recipe that already has zircon is unchanged")
check(recipes["wrong-category-from-lava"].results[1].amount == 20,
	"a recipe outside metallurgy is unchanged")
check(recipes["probabilistic-stone-from-lava"].results[1].amount == 20
	and recipes["probabilistic-stone-from-lava"].results[1].probability == 0.5,
	"a probabilistic stone result is unchanged")
check(recipes["ranged-stone-from-lava"].results[1].amount_min == 2
	and recipes["ranged-stone-from-lava"].results[1].amount_max == 20,
	"a ranged stone result is unchanged")
check(recipes["single-stone-from-lava"].results[1].amount == 1,
	"a stone result below two is unchanged")
local expected_logs = {
	["razi-protocol: bz: stone-from-lava: stone 25 -> stone 13 + zircon 12"] = true,
	["razi-protocol: bz: molten-iron-from-lava: stone 10 -> stone 5 + zircon 5"] = true,
	["razi-protocol: bz: molten-copper-from-lava: stone 15 -> stone 8 + zircon 7"] = true,
	["razi-protocol: bz: molten-lead-from-lava: stone 10 -> stone 5 + zircon 5"] = true,
}
for _, message in ipairs(world.logs) do
	expected_logs[message] = nil
end
check(#world.logs == 4 and next(expected_logs) == nil,
	"each eligible lava recipe change is logged with its split")

lava_zircon.data_final_fixes()
check(recipes["stone-from-lava"].results[1].amount == 13
	and #recipes["stone-from-lava"].results == 2
	and #world.logs == 4,
	"a repeated call does not split or log the same recipe again")

world = make_world({ no_bzzirconium = true })
lava_zircon.data_final_fixes()
recipes = world.raw.recipe
check(recipes["stone-from-lava"].results[1].amount == 25 and #world.logs == 0,
	"recipes stay unchanged without bzzirconium")
world = make_world({ no_zircon = true })
lava_zircon.data_final_fixes()
recipes = world.raw.recipe
check(recipes["stone-from-lava"].results[1].amount == 25 and #world.logs == 0,
	"recipes stay unchanged when the zircon item is absent")
world = make_world({ no_recipes = true })
lava_zircon.data_final_fixes()
check(#world.logs == 0, "an absent recipe table is safe")

print("test_bz_lava_zircon: ok")
