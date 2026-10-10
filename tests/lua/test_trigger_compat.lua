-- Regression fixtures for K2SO item/fluids research trigger renames.
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(condition, message)
	if not condition then error(message, 2) end
end

rawset(_G, "mods", {["Krastorio2-spaced-out"] = "2.0.17"})
rawset(_G, "data", {raw = {
	recipe = {
		["k2-oxygen"] = {results = {{type = "fluid", name = "kr-oxygen", amount = 100}}},
		["k2-hydrogen"] = {result = "kr-hydrogen"},
		["old-ammonia"] = {results = {{type = "fluid", name = "ammonia", amount = 1}}},
		["new-ammonia"] = {results = {{type = "fluid", name = "kr-ammonia", amount = 1}}},
		["legacy-variant"] = {normal = {
			results = {{type = "item", name = "kr-uranium-rifle-magazine", amount = 1}}
		}}
	},
	technology = {
		["needs-oxygen"] = {research_trigger = {type = "craft-fluid", fluid = "oxygen"}},
		["needs-hydrogen"] = {research_trigger = {type = "craft-item", item = "hydrogen"}},
		["keep-ammonia"] = {research_trigger = {type = "craft-fluid", fluid = "ammonia"}},
		["upgrade-uranium-ammo"] = {
			research_trigger = {type = "craft-item", item = "uranium-rounds-magazine"}
		}
	}
}})
package.loaded["prototypes.compat.renamed_research_triggers"] = nil
local fix = require("prototypes.compat.renamed_research_triggers")
fix.data_final_fixes()
local technologies = data.raw.technology
check(technologies["needs-oxygen"].research_trigger.fluid == "kr-oxygen",
	"Missed K2 fluid output")
check(technologies["needs-hydrogen"].research_trigger.item == "kr-hydrogen",
	"Missed legacy single-result recipe")
check(technologies["keep-ammonia"].research_trigger.fluid == "ammonia",
	"Overwrote a still-producible original fluid")
check(technologies["upgrade-uranium-ammo"].research_trigger.item == "kr-uranium-rifle-magazine",
	"Missed legacy recipe variant output")

print("Research trigger compatibility fixtures passed")
