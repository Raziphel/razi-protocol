---@diagnostic disable: missing-fields
-- Repairs of mistakes in the data of required mods (prototypes/fixes/): the ice box of Corrundum, the Muluna hard drive
-- and burner roboport, the description of an Arig technology, the connectors of the Dyson sphere, the upgrade chain of the
-- hyper belts, the galvanization pack of Cubium, the nutrients of Apia and the electrochemical plant, on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_mod_fixes_data_errors.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
	if not value then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(message) logs[#logs + 1] = message end)

local function logged(text)
	local count = 0
	for _, line in ipairs(logs) do
		if line:find(text, 1, true) then
			count = count + 1
		end
	end

	return count
end

local mod_list = {}
local item_types = {item = 1, capsule = 2}

---@return any
local function fresh()
	logs = {}
	local raw = {}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", mod_list)
	rawset(_G, "defines", {prototypes = {item = item_types}})
	return raw
end

local fixes = require("prototypes.fixes.init")

-- Nothing of the mods is installed: every repair is quiet and does not fail.
---@type any
local raw = fresh()
fixes.data_final_fixes()
check(#logs == 0, "A repair logged without its prototypes")
check(next(raw) == nil, "A repair created a prototype type")
raw = fresh()
for _, name in ipairs({"recipe", "technology", "capsule", "item", "roboport", "assembling-machine", "electric-energy-interface",
	"loader-1x1", "transport-belt", "underground-belt", "splitter"}) do
	raw[name] = {}
end
fixes.data_final_fixes()
check(#logs == 0, "A repair logged on empty prototype tables")

-- planet-muluna hard_drive_time
local hard_drive_time = require("prototypes.fixes.planet-muluna.hard_drive_time")
raw = fresh()
raw.recipe = {["muluna-basic-hard-drive"] = {energy_require = 5}}
hard_drive_time.data_final_fixes()
check(raw.recipe["muluna-basic-hard-drive"].energy_required == 5 and raw.recipe["muluna-basic-hard-drive"].energy_require == nil,
	"The craft time was not moved to energy_required")
check(logged("muluna-basic-hard-drive takes 5 s") == 1 and logs[1]:find("^razi%-protocol: "), "Expected one line that starts with the mod name")
hard_drive_time.data_final_fixes()
check(logged("takes 5 s") == 1, "The repeated run touched the recipe again")
raw.recipe["muluna-basic-hard-drive"] = {energy_require = 5, energy_required = 2}
hard_drive_time.data_final_fixes()
check(raw.recipe["muluna-basic-hard-drive"].energy_required == 2, "A craft time that Muluna fixed was changed")
raw.recipe["muluna-basic-hard-drive"] = {energy_require = 8}
hard_drive_time.data_final_fixes()
check(raw.recipe["muluna-basic-hard-drive"].energy_required == nil, "Another typo value was changed")
raw = fresh()
hard_drive_time.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without the recipe")

-- planet-muluna burner_roboport_minable
local burner_minable = require("prototypes.fixes.planet-muluna.burner_roboport_minable")
raw = fresh()
raw.item = {["muluna-burner-roboport"] = {}}
raw["assembling-machine"] = {
	["muluna-burner-roboport"] = {minable = {result = "muluna-burner-roboport"}},
	["muluna-burner-roboport-logistic-mode"] = {minable = {mining_time = 0.1, result = "roboport"}},
	["muluna-burner-roboport-construction-mode"] = {minable = {result = "muluna-burner-roboport"}},
}
raw.roboport = {
	["muluna-burner-roboport-logistic-mode-roboport"] = {minable = {result = "roboport"}},
	["muluna-burner-roboport-construction-mode-roboport"] = {},
	["roboport"] = {minable = {result = "roboport"}},
}
burner_minable.data_final_fixes()
check(raw["assembling-machine"]["muluna-burner-roboport-logistic-mode"].minable.result == "muluna-burner-roboport"
	and raw["assembling-machine"]["muluna-burner-roboport-logistic-mode"].minable.mining_time == 0.1, "The mode did not mine into the burner roboport")
check(raw.roboport["muluna-burner-roboport-logistic-mode-roboport"].minable.result == "muluna-burner-roboport", "The hidden roboport did not mine into the burner roboport")
check(raw["assembling-machine"]["muluna-burner-roboport-construction-mode"].minable.result == "muluna-burner-roboport", "A result that was right was changed")
check(raw.roboport["roboport"].minable.result == "roboport", "The vanilla roboport was changed")
check(raw.roboport["muluna-burner-roboport-construction-mode-roboport"].minable == nil, "A roboport without minable got one")
check(logged("mines into the burner roboport") == 2 and logs[1]:find("^razi%-protocol: "), "Expected a line for each of the two entities that were wrong")
burner_minable.data_final_fixes()
check(logged("mines into the burner roboport") == 2, "The repeated run touched the entities again")
raw = fresh()
raw["assembling-machine"] = {["muluna-burner-roboport-logistic-mode"] = {minable = {result = "roboport"}}}
burner_minable.data_final_fixes()
check(raw["assembling-machine"]["muluna-burner-roboport-logistic-mode"].minable.result == "roboport" and #logs == 0,
	"The result changed to an item that does not exist")

-- planetaris-arig rail_support_description
local rail_description = require("prototypes.fixes.planetaris-arig.rail_support_description")
raw = fresh()
local arig_line = {"", {"technology-description.rail-support-foundations"}, "", {"technology-description.rail-support-foundations-addon"}}
raw.technology = {["rail-support-foundations"] = {localized_description = arig_line}}
rail_description.data_final_fixes()
check(raw.technology["rail-support-foundations"].localised_description == arig_line, "The description was not moved")
check(raw.technology["rail-support-foundations"].localized_description == nil, "The misspelt key stayed")
check(logged("rail-support-foundations shows the Arig line") == 1 and logs[1]:find("^razi%-protocol: "), "Expected one line that starts with the mod name")
rail_description.data_final_fixes()
check(logged("rail-support-foundations") == 1, "The repeated run touched the technology again")
raw.technology = {["rail-support-foundations"] = {localized_description = arig_line, localised_description = {"mine"}}}
rail_description.data_final_fixes()
check(raw.technology["rail-support-foundations"].localised_description[1] == "mine", "A description that was set was replaced")
raw = fresh()
raw.technology = {}
rail_description.data_final_fixes()
check(next(raw.technology) == nil and #logs == 0, "Something changed without the technology")

-- slp-dyson-sphere-reworked-fork connector_priority
local connector_priority = require("prototypes.fixes.slp-dyson-sphere-reworked-fork.connector_priority")
raw = fresh()
raw["electric-energy-interface"] = {
	["ds-energy-small-loader"] = {energy_source = {usage_priority = "tertiary"}},
	["ds-energy-loader-mk1"] = {energy_source = {usage_priority = "tertiary"}},
	["ds-energy-loader-mk2"] = {energy_source = {usage_priority = "secondary-output"}},
	["other-interface"] = {energy_source = {usage_priority = "tertiary"}},
	["ds-energy-no-source"] = {},
}
connector_priority.data_final_fixes()
check(raw["electric-energy-interface"]["ds-energy-small-loader"].energy_source.usage_priority == "primary-output", "The small loader kept the accumulator priority")
check(raw["electric-energy-interface"]["ds-energy-loader-mk1"].energy_source.usage_priority == "primary-output", "A connector kept the accumulator priority")
check(raw["electric-energy-interface"]["ds-energy-loader-mk2"].energy_source.usage_priority == "secondary-output", "A priority that was set was changed")
check(raw["electric-energy-interface"]["other-interface"].energy_source.usage_priority == "tertiary", "An interface of another mod was changed")
check(logged("usage_priority = primary-output") == 2 and logs[1]:find("^razi%-protocol: "), "Expected a line for each of the two connectors")
connector_priority.data_final_fixes()
check(logged("usage_priority = primary-output") == 2, "The repeated run touched the connectors again")

-- xy-k2so-enhancements-nulls-fork upgrade_chain
local upgrade_chain = require("prototypes.fixes.xy-k2so-enhancements-nulls-fork.upgrade_chain")
raw = fresh()
raw["loader-1x1"] = {
	["kr-advanced-loader"] = {next_upgrade = "kr-superior-loader", fast_replaceable_group = "loader"},
	["kr-hyper-loader"] = {fast_replaceable_group = "loader"},
}
raw["transport-belt"] = {
	["planetaris-hyper-transport-belt"] = {fast_replaceable_group = "transport-belt"},
	["kr-superior-transport-belt"] = {fast_replaceable_group = "transport-belt"},
}
raw["underground-belt"] = {
	["planetaris-hyper-underground-belt"] = {next_upgrade = "kr-superior-underground-belt", fast_replaceable_group = "underground-belt"},
	["kr-superior-underground-belt"] = {fast_replaceable_group = "underground-belt"},
}
raw.splitter = {
	["planetaris-hyper-splitter"] = {fast_replaceable_group = "splitter"},
	["kr-superior-splitter"] = {fast_replaceable_group = "other-group"},
}
upgrade_chain.data_final_fixes()
check(raw["loader-1x1"]["kr-advanced-loader"].next_upgrade == "kr-hyper-loader", "The advanced loader does not upgrade to the hyper loader")
check(raw["transport-belt"]["planetaris-hyper-transport-belt"].next_upgrade == "kr-superior-transport-belt", "The hyper belt does not upgrade to superior")
check(raw["underground-belt"]["planetaris-hyper-underground-belt"].next_upgrade == "kr-superior-underground-belt", "A correct link was rewritten")
check(raw.splitter["planetaris-hyper-splitter"].next_upgrade == nil, "A link between different replace groups was made")
check(logged("upgrades to") == 2 and logs[1]:find("^razi%-protocol: "), "Expected a line for each of the two links that were wrong, got " .. logged("upgrades to"))
upgrade_chain.data_final_fixes()
check(logged("upgrades to") == 2, "The repeated run touched the links again")
raw = fresh()
raw["transport-belt"] = {["planetaris-hyper-transport-belt"] = {}}
upgrade_chain.data_final_fixes()
check(raw["transport-belt"]["planetaris-hyper-transport-belt"].next_upgrade == nil and #logs == 0, "A link was made to a belt that does not exist")

-- k2so-cubium-compatibility-fork galvanization_notes
local galvanization_notes = require("prototypes.fixes.k2so-cubium-compatibility-fork.galvanization_notes")
raw = fresh()
raw.recipe = {["galvanization-science-pack-cubic"] = {results = {
	{type = "item", name = "galvanization-science-pack", amount = 1},
	{type = "item", name = "kr-note-1", amount = 1000},
	{type = "item", name = "dormant-microcube", amount = 1},
}}}
galvanization_notes.data_final_fixes()
---@type any
local results = raw.recipe["galvanization-science-pack-cubic"].results
check(#results == 2 and results[1].name == "galvanization-science-pack" and results[2].name == "dormant-microcube", "The notes were not removed, or something else was")
check(logged("no longer returns kr-note-1") == 1 and logs[1]:find("^razi%-protocol: "), "Expected one line that starts with the mod name")
galvanization_notes.data_final_fixes()
check(logged("no longer returns") == 1, "The repeated run touched the recipe again")
raw.recipe["galvanization-science-pack-cubic"].results = {{type = "item", name = "kr-note-1", amount = 5}}
galvanization_notes.data_final_fixes()
check(#raw.recipe["galvanization-science-pack-cubic"].results == 1, "A different number of notes was removed")
raw = fresh()
raw.recipe = {}
galvanization_notes.data_final_fixes()
check(#logs == 0, "Something changed without the recipe")

-- apia nutrients_refresh
local nutrients_refresh = require("prototypes.fixes.apia.nutrients_refresh")
raw = fresh()
raw.item = {
	nutrients = {fuel_categories = {"nutrients"}},
	["old-nutrients"] = {fuel_category = "nutrients"},
	["bacteria"] = {fuel_categories = {"chemical"}},
}
raw.capsule = {["nutrient-bar"] = {fuel_categories = {"chemical", "nutrients"}}}
raw.recipe = {
	["nutrients-refresh-freshness"] = {},
	["old-nutrients-refresh-freshness"] = {},
	["bacteria-refresh-freshness"] = {},
	["nutrient-bar-refresh-freshness"] = {},
}
raw.technology = {
	one = {effects = {
		{type = "unlock-recipe", recipe = "nutrients-refresh-freshness"},
		{type = "unlock-recipe", recipe = "bacteria-refresh-freshness"},
		{type = "nothing"},
		{type = "unlock-recipe", recipe = "nutrient-bar-refresh-freshness"},
	}},
	two = {},
}
nutrients_refresh.data_final_fixes()
check(raw.recipe["nutrients-refresh-freshness"] == nil and raw.recipe["old-nutrients-refresh-freshness"] == nil
	and raw.recipe["nutrient-bar-refresh-freshness"] == nil, "A recipe of nutrients stayed")
check(raw.recipe["bacteria-refresh-freshness"] ~= nil, "The recipe of an item that is not nutrients was removed")
check(#raw.technology.one.effects == 2 and raw.technology.one.effects[1].recipe == "bacteria-refresh-freshness"
	and raw.technology.one.effects[2].type == "nothing", "The unlocks were not taken out, or others were")
check(logged("(apia skips nutrients)") == 3 and logs[1]:find("^razi%-protocol: "), "Expected a line for each of the three recipes, got " .. logged("(apia skips nutrients)"))
nutrients_refresh.data_final_fixes()
check(logged("(apia skips nutrients)") == 3, "The repeated run touched the recipes again")
raw = fresh()
nutrients_refresh.data_final_fixes()
check(next(raw) == nil and #logs == 0, "Something changed without recipes")

print("test_mod_fixes_data_errors: ok")
