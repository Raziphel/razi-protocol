---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
	if not value then error(message, 2) end
end

local obsolete = "xy-electrochemical-research-data"
local replacement = "electrochemical-science-pack"

local function setup(active_mods, items)
	rawset(_G, "mods", active_mods)
	rawset(_G, "data", {raw = {
		item = items,
		tool = {},
		lab = {
			["omega-lab"] = {inputs = {"automation-science-pack", obsolete,
				replacement, obsolete}},
			lab = {inputs = {"automation-science-pack"}}
		}
	}})
	package.loaded["prototypes.compat.corrundum_k2so_lab_inputs"] = nil
	return require("prototypes.compat.corrundum_k2so_lab_inputs")
end

local compat = setup({
	["corrundum-krastorio-compatibility-plus"] = "1.1.2",
	["xy-k2so-enhancements-nulls-fork"] = "0.8.6"
}, {[replacement] = {}})
compat.data_final_fixes()

local inputs = data.raw.lab["omega-lab"].inputs
check(#inputs == 2, "Replacement left duplicate omega-lab inputs")
check(inputs[1] == "automation-science-pack" and inputs[2] == replacement,
	"Obsolete XY research input was not replaced by Corrundum science")
check(#data.raw.lab.lab.inputs == 1,
	"Unaffected lab inputs changed")

compat.data_final_fixes()
check(#data.raw.lab["omega-lab"].inputs == 2,
	"Second compatibility pass changed the repaired inputs")

local inactive = setup({
	["xy-k2so-enhancements-nulls-fork"] = "0.8.6"
}, {[replacement] = {}})
inactive.data_final_fixes()
check(data.raw.lab["omega-lab"].inputs[2] == obsolete,
	"Compatibility pass ran without Corrundum Compatibility+")

local old_item_survives = setup({
	["corrundum-krastorio-compatibility-plus"] = "1.1.2",
	["xy-k2so-enhancements-nulls-fork"] = "0.8.6"
}, {[obsolete] = {}, [replacement] = {}})
old_item_survives.data_final_fixes()
check(data.raw.lab["omega-lab"].inputs[2] == obsolete,
	"Compatibility pass replaced an existing input")

local f = assert(io.open("data-final-fixes.lua", "r"))
local source = f:read("*a")
f:close()
check(source:find(
	'require("prototypes.compat.corrundum_k2so_lab_inputs").data_final_fixes()',
	1, true), "Corrundum lab repair is not wired into data-final-fixes")

print("Corrundum K2SO lab input compatibility passed")
