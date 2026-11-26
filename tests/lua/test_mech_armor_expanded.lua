package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function deep_copy(value, seen)
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return seen[value]
	end

	local copy = {}
	seen[value] = copy
	for key, child in pairs(value) do
		copy[deep_copy(key, seen)] = deep_copy(child, seen)
	end
	return copy
end

local function deep_equal(left, right, seen)
	if type(left) ~= type(right) then
		return false
	end
	if type(left) ~= "table" then
		return left == right
	end

	seen = seen or {}
	if seen[left] == right then
		return true
	end
	seen[left] = right
	for key, value in pairs(left) do
		if not deep_equal(value, right[key], seen) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function resistance(damage_type, decrease, percent)
	local result = { type = damage_type }
	if decrease ~= nil then
		result.decrease = decrease
	end
	if percent ~= nil then
		result.percent = percent
	end
	return result
end

local function make_world(options)
	options = options or {}
	local cards = {
		"vibrant-tech-card",
		"beetlejuice-tech-card",
		"deep-space-tech-card",
	}
	local tools = {}
	for _, card in ipairs(cards) do
		tools[card] = {}
	end
	if options.missing_card then
		tools[options.missing_card] = nil
	end

	local technology = {
		["mech-armor-mk2"] = {
			prerequisites = { "mech-armor" },
			unit = { count = 2500, ingredients = { { "space-science-pack", 1 } } },
		},
		["mech-armor-mk3"] = {
			prerequisites = { "mech-armor-mk2" },
			unit = { count = 5000, ingredients = { { "space-science-pack", 1 } } },
		},
		["mech-armor-mk4"] = {
			prerequisites = { "mech-armor-mk3" },
			unit = { count = 10000, ingredients = { { "space-science-pack", 1 } } },
		},
		["planet-discovery-ribbonia"] = { prerequisites = {} },
		["planet-discovery-cubium"] = { prerequisites = {} },
		["razi-singularity-theory"] = { prerequisites = {} },
	}
	if options.missing_gate then
		technology[options.missing_gate] = nil
	end
	if options.gate_after_tier then
		technology["planet-discovery-cubium"].prerequisites = { "mech-armor-mk3" }
	end
	if options.no_mk4 then
		technology["mech-armor-mk4"] = nil
	end

	local base_resistances = {
		resistance("physical", 10, 50),
		resistance("explosion", 60, 50),
		resistance("acid", 0, 70),
		resistance("fire", 10, 70),
		resistance("kr-radioactive", 6, 60),
		resistance("arcane", 5, 25),
		resistance("promethium-physical", nil, 50),
		resistance("drowning", nil, 50),
	}
	local tier_resistances = {
		["mech-armor-mk2"] = {
			resistance("physical", 15, 50),
			resistance("explosion", 20, 60),
			resistance("acid", 15, 50),
			resistance("fire", 20, 70),
			resistance("electric", 15, 70),
			resistance("impact", 20, 60),
			resistance("poison", 15, 50),
			resistance("arcane", 7.5, 25),
			resistance("promethium-physical", nil, 50),
			resistance("drowning", nil, 50),
		},
		["mech-armor-mk3"] = {
			resistance("physical", 30, 70),
			resistance("explosion", 50, 75),
			resistance("acid", 30, 75),
			resistance("fire", 50, 80),
			resistance("electric", 30, 80),
			resistance("impact", 40, 80),
			resistance("poison", 30, 75),
			resistance("cold", 30, 85),
			resistance("arcane", 15, 35),
			resistance("promethium-physical", nil, 70),
			resistance("drowning", nil, 50),
		},
		["mech-armor-mk4"] = {
			resistance("physical", 50, 95),
			resistance("explosion", 100, 95),
			resistance("acid", 50, 95),
			resistance("fire", 100, 95),
			resistance("electric", 95, 95),
			resistance("impact", 80, 95),
			resistance("poison", 50, 95),
			resistance("cold", 50, 95),
			resistance("arcane", 25, 47.5),
			resistance("promethium-physical", nil, 95),
			resistance("drowning", nil, 50),
		},
	}

	local armors = {
		["mech-armor"] = {
			equipment_grid = "huge-equipment-grid",
			resistances = base_resistances,
		},
		["mech-armor-mk2"] = {
			equipment_grid = "mech-armor-mk2-grid",
			inventory_size_bonus = 60,
			resistances = tier_resistances["mech-armor-mk2"],
		},
		["mech-armor-mk3"] = {
			equipment_grid = "mech-armor-mk3-grid",
			inventory_size_bonus = 100,
			resistances = tier_resistances["mech-armor-mk3"],
		},
		["mech-armor-mk4"] = {
			equipment_grid = "mech-armor-mk4-grid",
			inventory_size_bonus = 150,
			resistances = tier_resistances["mech-armor-mk4"],
		},
	}
	local grids = {
		["huge-equipment-grid"] = {
			width = 10,
			height = 12,
			equipment_categories = { "armor", "flying", "flying", "maraxsis-armor-category" },
		},
		["mech-armor-mk2-grid"] = {
			width = 10,
			height = 16,
			equipment_categories = { "armor", "maraxsis-armor-category" },
		},
		["mech-armor-mk3-grid"] = {
			width = 10,
			height = 18,
			equipment_categories = { "armor", "maraxsis-armor-category" },
		},
		["mech-armor-mk4-grid"] = {
			width = 10,
			height = 20,
			equipment_categories = { "armor", "maraxsis-armor-category" },
		},
	}
	if options.no_mk4 then
		armors["mech-armor-mk4"] = nil
	end

	local damage_types = { toxic = {} }
	if options.no_toxic then
		damage_types.toxic = nil
	end
	local raw = {
		armor = armors,
		["equipment-grid"] = grids,
		technology = technology,
		tool = tools,
		item = {},
		["damage-type"] = damage_types,
		["character-corpse"] = {
			["character-corpse"] = {
				armor_picture_mapping = {
					["mech-armor"] = 4,
					["mech-armor-mk3"] = 7,
				},
			},
		},
	}
	if not options.no_military then
		raw.item["military-mk2-science-pack"] = {}
	end

	local logs = {}
	rawset(_G, "data", { raw = raw })
	rawset(_G, "mods", options.no_mod and {} or { ["mech-armor-expanded"] = "1.2.1" })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	return { raw = raw, logs = logs }
end

local function apply_modules()
	require("prototypes.compatibility.mech-armor-expanded.chapter_gates").data_final_fixes()
	require("prototypes.compatibility.mech-armor-expanded.base_armor_links").data_final_fixes()
	require("prototypes.balance.mech-armor-expanded.armor_tiers").data_final_fixes()
end

local function has_prerequisite(technology, name)
	for _, prerequisite in ipairs(technology.prerequisites or {}) do
		if prerequisite == name then
			return true
		end
	end
	return false
end

local function ingredient_totals(technology, name)
	local count, amount = 0, 0
	for _, ingredient in ipairs(technology.unit and technology.unit.ingredients or {}) do
		if (ingredient.name or ingredient[1]) == name then
			count = count + 1
			amount = amount + (ingredient.amount or ingredient[2] or 0)
		end
	end
	return count, amount
end

local function log_contains(logs, text)
	for _, message in ipairs(logs) do
		if message:find(text, 1, true) then
			return true
		end
	end
	return false
end

local function check_resistances(actual, expected, tier_name)
	local by_type = {}
	for _, resistance_entry in ipairs(actual or {}) do
		check(not by_type[resistance_entry.type], tier_name .. " has duplicate " .. resistance_entry.type)
		by_type[resistance_entry.type] = resistance_entry
	end
	for damage_type, wanted in pairs(expected) do
		local found = by_type[damage_type]
		if not found then
			error(tier_name .. " has " .. damage_type, 2)
		end
		check(found.decrease == wanted.decrease, tier_name .. " " .. damage_type .. " decrease")
		check(found.percent == wanted.percent, tier_name .. " " .. damage_type .. " percent")
	end
	local count = 0
	for _ in pairs(expected) do
		count = count + 1
	end
	check(#(actual or {}) == count, tier_name .. " resistance type count")
	for damage_type in pairs(by_type) do
		check(expected[damage_type] ~= nil, tier_name .. " has no extra " .. damage_type)
	end
end

local expected_resistances = {
	["mech-armor-mk2"] = {
		physical = { decrease = 15, percent = 50 },
		explosion = { decrease = 60, percent = 60 },
		acid = { decrease = 15, percent = 70 },
		fire = { decrease = 20, percent = 70 },
		electric = { decrease = 15, percent = 70 },
		impact = { decrease = 20, percent = 60 },
		poison = { decrease = 15, percent = 50 },
		toxic = { decrease = 15, percent = 50 },
		["kr-radioactive"] = { decrease = 6, percent = 60 },
		arcane = { decrease = 7.5, percent = 25 },
		["promethium-physical"] = { percent = 50 },
		drowning = { percent = 50 },
	},
	["mech-armor-mk3"] = {
		physical = { decrease = 30, percent = 70 },
		explosion = { decrease = 60, percent = 75 },
		acid = { decrease = 30, percent = 75 },
		fire = { decrease = 50, percent = 80 },
		electric = { decrease = 30, percent = 80 },
		impact = { decrease = 40, percent = 80 },
		poison = { decrease = 30, percent = 75 },
		toxic = { decrease = 30, percent = 75 },
		cold = { decrease = 30, percent = 80 },
		["kr-radioactive"] = { decrease = 6, percent = 60 },
		arcane = { decrease = 15, percent = 35 },
		["promethium-physical"] = { percent = 70 },
		drowning = { percent = 50 },
	},
	["mech-armor-mk4"] = {
		physical = { decrease = 50, percent = 80 },
		explosion = { decrease = 60, percent = 80 },
		acid = { decrease = 50, percent = 80 },
		fire = { decrease = 60, percent = 80 },
		electric = { decrease = 60, percent = 80 },
		impact = { decrease = 60, percent = 80 },
		poison = { decrease = 50, percent = 80 },
		toxic = { decrease = 50, percent = 80 },
		cold = { decrease = 50, percent = 80 },
		["kr-radioactive"] = { decrease = 6, percent = 60 },
		arcane = { decrease = 25, percent = 47.5 },
		["promethium-physical"] = { percent = 80 },
		drowning = { percent = 50 },
	},
}

local vanilla = make_world({ no_mod = true })
local vanilla_before = deep_copy(vanilla.raw)
apply_modules()
check(deep_equal(vanilla.raw, vanilla_before), "without mech-armor-expanded, prototypes stay unchanged")
check(#vanilla.logs == 0, "without mech-armor-expanded, log stays empty")

local full = make_world()
apply_modules()
local log_prefix = "razi-protocol: mech-armor-expanded: "
check(#full.logs > 0, "prototype changes are logged")
for _, message in ipairs(full.logs) do
	check(message:sub(1, #log_prefix) == log_prefix, "log message uses the mech-armor-expanded prefix")
end
check(log_contains(full.logs, "mech-armor-mk2 uses vibrant-tech-card and military-mk2-science-pack"),
	"MK2 log includes the military pack when it is present")
local expected_cards = {
	["mech-armor-mk2"] = "vibrant-tech-card",
	["mech-armor-mk3"] = "beetlejuice-tech-card",
	["mech-armor-mk4"] = "deep-space-tech-card",
}
local expected_gates = {
	["mech-armor-mk2"] = "planet-discovery-ribbonia",
	["mech-armor-mk3"] = "planet-discovery-cubium",
	["mech-armor-mk4"] = "razi-singularity-theory",
}
local expected_counts = { ["mech-armor-mk2"] = 2500, ["mech-armor-mk3"] = 5000, ["mech-armor-mk4"] = 10000 }
local expected_dimensions = {
	["mech-armor-mk2"] = { width = 10, height = 14, inventory = 60 },
	["mech-armor-mk3"] = { width = 10, height = 16, inventory = 80 },
	["mech-armor-mk4"] = { width = 10, height = 18, inventory = 100 },
}
for _, name in ipairs({ "mech-armor-mk2", "mech-armor-mk3", "mech-armor-mk4" }) do
	local technology = full.raw.technology[name]
	local card_count, card_amount = ingredient_totals(technology, expected_cards[name])
	check(card_count == 1 and card_amount == 1, name .. " chapter card ×1")
	check(has_prerequisite(technology, expected_gates[name]), name .. " chapter gate")
	check(technology.unit.count == expected_counts[name], name .. " research count preserved")

	local armor = full.raw.armor[name]
	if not armor then
		error(name .. " armor prototype is missing", 2)
	end
	local grid = full.raw["equipment-grid"][armor.equipment_grid]
	if not grid then
		error(name .. " grid prototype is missing", 2)
	end
	local dimensions = expected_dimensions[name]
	check(grid.width == dimensions.width and grid.height == dimensions.height, name .. " grid dimensions")
	check(armor.inventory_size_bonus == dimensions.inventory, name .. " inventory bonus")
	local has_radioactive = false
	for _, resistance_entry in ipairs(armor.resistances or {}) do
		if resistance_entry.type == "kr-radioactive" then
			has_radioactive = true
		end
	end
	check(has_radioactive, name .. " keeps kr-radioactive")
	check_resistances(armor.resistances, expected_resistances[name], name)

	local categories = grid.equipment_categories
	check(deep_equal(categories, { "armor", "maraxsis-armor-category", "flying" }), name .. " equipment categories")
end
local military_count, military_amount = ingredient_totals(full.raw.technology["mech-armor-mk2"], "military-mk2-science-pack")
check(military_count == 1 and military_amount == 1, "MK2 military pack ×1")
for _, name in ipairs({ "mech-armor-mk3", "mech-armor-mk4" }) do
	local count = ingredient_totals(full.raw.technology[name], "military-mk2-science-pack")
	check(count == 0, name .. " has no military MK2 pack")
end
local corpse_mapping = full.raw["character-corpse"]["character-corpse"].armor_picture_mapping
check(corpse_mapping["mech-armor-mk2"] == 4, "MK2 corpse image inherits mech armor")
check(corpse_mapping["mech-armor-mk3"] == 7, "existing MK3 corpse image is preserved")
check(corpse_mapping["mech-armor-mk4"] == 4, "MK4 corpse image inherits mech armor")

local full_before_repeat = deep_copy(full.raw)
apply_modules()
check(deep_equal(full.raw, full_before_repeat), "repeated calls are idempotent")

local missing_card = make_world({ missing_card = "beetlejuice-tech-card" })
local mk3_before_missing_card = deep_copy(missing_card.raw.technology["mech-armor-mk3"])
apply_modules()
check(deep_equal(missing_card.raw.technology["mech-armor-mk3"], mk3_before_missing_card), "missing card leaves MK3 technology unchanged")
check(ingredient_totals(missing_card.raw.technology["mech-armor-mk2"], "vibrant-tech-card") == 1, "MK2 is processed when MK3 card is missing")
check(ingredient_totals(missing_card.raw.technology["mech-armor-mk4"], "deep-space-tech-card") == 1, "MK4 is processed when MK3 card is missing")
check(log_contains(missing_card.logs, "mech-armor-mk3 left as is, no beetlejuice-tech-card"), "missing card is logged")

local missing_gate = make_world({ missing_gate = "planet-discovery-cubium" })
local mk3_before_missing_gate = deep_copy(missing_gate.raw.technology["mech-armor-mk3"])
apply_modules()
check(deep_equal(missing_gate.raw.technology["mech-armor-mk3"], mk3_before_missing_gate), "missing gate leaves MK3 technology unchanged")
check(log_contains(missing_gate.logs, "mech-armor-mk3 left as is, no planet-discovery-cubium"), "missing gate is logged")

local no_military = make_world({ no_military = true })
apply_modules()
check(ingredient_totals(no_military.raw.technology["mech-armor-mk2"], "vibrant-tech-card") == 1, "MK2 card remains when military item is missing")
check(ingredient_totals(no_military.raw.technology["mech-armor-mk2"], "military-mk2-science-pack") == 0, "missing military item is skipped")
check(has_prerequisite(no_military.raw.technology["mech-armor-mk2"], "planet-discovery-ribbonia"), "MK2 gate remains when military item is missing")
check(not log_contains(no_military.logs, "military-mk2-science-pack"), "log does not mention a missing military pack")

local no_toxic = make_world({ no_toxic = true })
apply_modules()
for _, name in ipairs({ "mech-armor-mk2", "mech-armor-mk3", "mech-armor-mk4" }) do
	local armor = no_toxic.raw.armor[name]
	if not armor then
		error(name .. " armor prototype is missing", 2)
	end
	for _, resistance_entry in ipairs(armor.resistances or {}) do
		check(resistance_entry.type ~= "toxic", name .. " has no toxic resistance when the damage type is absent")
	end
end

local no_mk4 = make_world({ no_mk4 = true })
apply_modules()
check(no_mk4.raw.armor["mech-armor-mk4"] == nil, "missing MK4 armor is skipped")
check(no_mk4.raw.technology["mech-armor-mk4"] == nil, "missing MK4 technology is skipped")
check(ingredient_totals(no_mk4.raw.technology["mech-armor-mk2"], "vibrant-tech-card") == 1, "MK2 still processes when MK4 is absent")
check(ingredient_totals(no_mk4.raw.technology["mech-armor-mk3"], "beetlejuice-tech-card") == 1, "MK3 still processes when MK4 is absent")

local gate_after_tier = make_world({ gate_after_tier = true })
apply_modules()
local mk3_count = ingredient_totals(gate_after_tier.raw.technology["mech-armor-mk3"], "beetlejuice-tech-card")
check(mk3_count == 1, "MK3 card is added when its gate would loop")
check(not has_prerequisite(gate_after_tier.raw.technology["mech-armor-mk3"], "planet-discovery-cubium"), "cyclic MK3 gate is skipped")
check(log_contains(gate_after_tier.logs, "gate planet-discovery-cubium already implied or would loop"), "cyclic gate outcome is logged")

print("test_mech_armor_expanded: ok")
