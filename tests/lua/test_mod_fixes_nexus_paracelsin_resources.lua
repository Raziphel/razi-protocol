---@diagnostic disable: missing-fields, need-check-nil, inject-field, undefined-field
-- Reconcile Nexus's older Paracelsin resource keys after the Paracelsin renames.
-- Run from the mod root with the library bootstrap: tests/run.sh
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local logs = {}
rawset(_G, "log", function(line)
	logs[#logs + 1] = line
end)

local fix = require("prototypes.fixes.Nexus.paracelsin_resources")

local function world(planet, resources)
	logs = {}
	if not resources then
		resources = {
			["calcium-crystals"] = {},
			["cryovolcanic-vent"] = {},
		}
	end
	rawset(_G, "data", {raw = {
		planet = planet and {paracelsin = planet} or {},
		resource = resources,
		["autoplace-control"] = {calcium_crystals = {}, cryovolcanic_vent = {}},
	}})
	return planet
end

local function check_logs(expected, message)
	check(#logs == #expected, message .. ": wrong number of log lines")
	for index, line in ipairs(expected) do
		check(logs[index] == line, message .. ": " .. tostring(logs[index]))
	end
end

local function old_map_gen_settings()
	return {
		autoplace_settings = {entity = {settings = {
			vaterite = {frequency = 1},
			["water-cryovolcano"] = {frequency = 2},
		}}},
		property_expression_names = {
			["entity:vaterite:probability"] = "old-probability",
			["entity:vaterite:richness"] = "old-richness",
			["entity:water-cryovolcano:probability"] = "old-vent-probability",
			["entity:water-cryovolcano:richness"] = "old-vent-richness",
		},
		autoplace_controls = {
			vaterite = {frequency = 1},
			water_cryovolcano = {frequency = 2},
		},
	}
end

-- Paracelsin 1.12.1 still defines vaterite but has renamed water-cryovolcano.
local planet = world({map_gen_settings = old_map_gen_settings()}, {
	vaterite = {},
	["calcium-crystals"] = {},
	["cryovolcanic-vent"] = {},
})
fix.data_final_fixes()
local settings = planet.map_gen_settings
check(settings.autoplace_settings.entity.settings.vaterite.frequency == 1
	and settings.autoplace_settings.entity.settings["calcium-crystals"] == nil,
	"an existing vaterite resource is left alone")
check(settings.autoplace_settings.entity.settings["water-cryovolcano"] == nil
	and settings.autoplace_settings.entity.settings["cryovolcanic-vent"].frequency == 2,
	"the missing cryovolcano resource is renamed independently")
check(settings.property_expression_names["entity:vaterite:probability"] == "old-probability"
	and settings.property_expression_names["entity:vaterite:richness"] == "old-richness"
	and settings.property_expression_names["entity:calcium-crystals:probability"] == nil
	and settings.property_expression_names["entity:calcium-crystals:richness"] == nil,
	"existing vaterite expressions are left alone")
check(settings.property_expression_names["entity:water-cryovolcano:probability"] == nil
	and settings.property_expression_names["entity:cryovolcanic-vent:probability"] == "old-vent-probability"
	and settings.property_expression_names["entity:water-cryovolcano:richness"] == nil
	and settings.property_expression_names["entity:cryovolcanic-vent:richness"] == "old-vent-richness",
	"cryovolcanic vent expressions are renamed independently")
check(settings.autoplace_controls.vaterite.frequency == 1
	and settings.autoplace_controls.calcium_crystals == nil,
	"the existing vaterite control is left alone")
check(settings.autoplace_controls.water_cryovolcano == nil
	and settings.autoplace_controls.cryovolcanic_vent.frequency == 2,
	"the cryovolcanic vent control is renamed independently")
check_logs({
	"razi-protocol: paracelsin autoplace_settings.entity.settings: water-cryovolcano renamed to cryovolcanic-vent",
	"razi-protocol: paracelsin property_expression_names: entity:water-cryovolcano:probability renamed to entity:cryovolcanic-vent:probability",
	"razi-protocol: paracelsin property_expression_names: entity:water-cryovolcano:richness renamed to entity:cryovolcanic-vent:richness",
	"razi-protocol: paracelsin autoplace_controls: water_cryovolcano renamed to cryovolcanic_vent"
}, "the 1.12.1 resources are repaired independently")

planet = world({map_gen_settings = old_map_gen_settings()})
fix.data_final_fixes()
settings = planet.map_gen_settings
check(settings.autoplace_settings.entity.settings.vaterite == nil
	and settings.autoplace_settings.entity.settings["calcium-crystals"].frequency == 1,
	"vaterite entity autoplace setting is renamed")
check(settings.autoplace_settings.entity.settings["water-cryovolcano"] == nil
	and settings.autoplace_settings.entity.settings["cryovolcanic-vent"].frequency == 2,
	"cryovolcanic vent entity autoplace setting is renamed")
check(settings.property_expression_names["entity:vaterite:probability"] == nil
	and settings.property_expression_names["entity:calcium-crystals:probability"] == "old-probability",
	"vaterite probability expression is renamed")
check(settings.property_expression_names["entity:vaterite:richness"] == nil
	and settings.property_expression_names["entity:calcium-crystals:richness"] == "old-richness",
	"vaterite richness expression is renamed")
check(settings.property_expression_names["entity:water-cryovolcano:probability"] == nil
	and settings.property_expression_names["entity:cryovolcanic-vent:probability"] == "old-vent-probability",
	"cryovolcanic vent probability expression is renamed")
check(settings.property_expression_names["entity:water-cryovolcano:richness"] == nil
	and settings.property_expression_names["entity:cryovolcanic-vent:richness"] == "old-vent-richness",
	"cryovolcanic vent richness expression is renamed")
check(settings.autoplace_controls.vaterite == nil and settings.autoplace_controls.calcium_crystals.frequency == 1,
	"vaterite autoplace control is renamed")
check(settings.autoplace_controls.water_cryovolcano == nil
	and settings.autoplace_controls.cryovolcanic_vent.frequency == 2,
	"cryovolcanic vent autoplace control is renamed")
check_logs({
	"razi-protocol: paracelsin autoplace_settings.entity.settings: vaterite renamed to calcium-crystals",
	"razi-protocol: paracelsin property_expression_names: entity:vaterite:probability renamed to entity:calcium-crystals:probability",
	"razi-protocol: paracelsin property_expression_names: entity:vaterite:richness renamed to entity:calcium-crystals:richness",
	"razi-protocol: paracelsin autoplace_controls: vaterite renamed to calcium_crystals",
	"razi-protocol: paracelsin autoplace_settings.entity.settings: water-cryovolcano renamed to cryovolcanic-vent",
	"razi-protocol: paracelsin property_expression_names: entity:water-cryovolcano:probability renamed to entity:cryovolcanic-vent:probability",
	"razi-protocol: paracelsin property_expression_names: entity:water-cryovolcano:richness renamed to entity:cryovolcanic-vent:richness",
	"razi-protocol: paracelsin autoplace_controls: water_cryovolcano renamed to cryovolcanic_vent"
}, "renamed keys are logged with their destination names")

-- An already occupied destination is preserved, and only the stale source key is removed.
planet = world({map_gen_settings = old_map_gen_settings()})
settings = planet.map_gen_settings
settings.autoplace_settings.entity.settings.vaterite = "old"
	settings.autoplace_settings.entity.settings["calcium-crystals"] = "kept"
	settings.autoplace_settings.entity.settings["water-cryovolcano"] = "old-vent"
	settings.autoplace_settings.entity.settings["cryovolcanic-vent"] = "kept-vent"
settings.property_expression_names = {
	["entity:vaterite:probability"] = "old-probability",
	["entity:calcium-crystals:probability"] = "kept-probability",
	["entity:vaterite:richness"] = "old-richness",
	["entity:calcium-crystals:richness"] = "kept-richness",
	["entity:water-cryovolcano:probability"] = "old-vent-probability",
	["entity:cryovolcanic-vent:probability"] = "kept-vent-probability",
	["entity:water-cryovolcano:richness"] = "old-vent-richness",
	["entity:cryovolcanic-vent:richness"] = "kept-vent-richness",
}
settings.autoplace_controls.vaterite = "old"
settings.autoplace_controls.calcium_crystals = "kept"
settings.autoplace_controls.water_cryovolcano = "old-vent"
settings.autoplace_controls.cryovolcanic_vent = "kept-vent"
fix.data_final_fixes()
check(settings.autoplace_settings.entity.settings.vaterite == nil
	and settings.autoplace_settings.entity.settings["calcium-crystals"] == "kept",
	"existing vaterite entity setting is not overwritten")
check(settings.autoplace_settings.entity.settings["water-cryovolcano"] == nil
	and settings.autoplace_settings.entity.settings["cryovolcanic-vent"] == "kept-vent",
	"existing cryovolcanic vent entity setting is not overwritten")
check(settings.property_expression_names["entity:vaterite:probability"] == nil
	and settings.property_expression_names["entity:calcium-crystals:probability"] == "kept-probability"
	and settings.property_expression_names["entity:vaterite:richness"] == nil
	and settings.property_expression_names["entity:calcium-crystals:richness"] == "kept-richness",
	"existing vaterite property expressions are not overwritten")
check(settings.property_expression_names["entity:water-cryovolcano:probability"] == nil
	and settings.property_expression_names["entity:cryovolcanic-vent:probability"] == "kept-vent-probability"
	and settings.property_expression_names["entity:water-cryovolcano:richness"] == nil
	and settings.property_expression_names["entity:cryovolcanic-vent:richness"] == "kept-vent-richness",
	"existing cryovolcanic vent property expressions are not overwritten")
check(settings.autoplace_controls.vaterite == nil and settings.autoplace_controls.calcium_crystals == "kept",
	"existing vaterite autoplace control is not overwritten")
check(settings.autoplace_controls.water_cryovolcano == nil
	and settings.autoplace_controls.cryovolcanic_vent == "kept-vent",
	"existing cryovolcanic vent autoplace control is not overwritten")
check_logs({
	"razi-protocol: paracelsin autoplace_settings.entity.settings: vaterite removed, calcium-crystals is already set",
	"razi-protocol: paracelsin property_expression_names: entity:vaterite:probability removed, entity:calcium-crystals:probability is already set",
	"razi-protocol: paracelsin property_expression_names: entity:vaterite:richness removed, entity:calcium-crystals:richness is already set",
	"razi-protocol: paracelsin autoplace_controls: vaterite removed, calcium_crystals is already set",
	"razi-protocol: paracelsin autoplace_settings.entity.settings: water-cryovolcano removed, cryovolcanic-vent is already set",
	"razi-protocol: paracelsin property_expression_names: entity:water-cryovolcano:probability removed, entity:cryovolcanic-vent:probability is already set",
	"razi-protocol: paracelsin property_expression_names: entity:water-cryovolcano:richness removed, entity:cryovolcanic-vent:richness is already set",
	"razi-protocol: paracelsin autoplace_controls: water_cryovolcano removed, cryovolcanic_vent is already set"
}, "occupied destination keys are logged as removed")

-- Missing planet and missing map settings are harmless.
world(nil)
fix.data_final_fixes()
world({})
fix.data_final_fixes()
check(#logs == 0, "missing planet map settings are skipped")

print("test_mod_fixes_nexus_paracelsin_resources ok")
