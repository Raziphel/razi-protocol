---@diagnostic disable: missing-fields
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(value, message)
	if not value then error(message, 2) end
end

local logs = {}
rawset(_G, "log", function(message) logs[#logs + 1] = message end)

local function logged(text)
	local count = 0
	for _, line in ipairs(logs) do
		if line:find(text, 1, true) then count = count + 1 end
	end
	return count
end

local setting_name = "razi-hide-redundant-assembler-tiers"
local progression = require("prototypes.compatibility.common.redundant_progression")

---@return any
local function fixture()
	logs = {}
	local raw = {
		["assembling-machine"] = {
			["planetaris-assembling-machine-4"] = {type = "assembling-machine"},
			["assembling-machine-4"] = {type = "assembling-machine"},
		},
		item = {
			["planetaris-assembling-machine-4"] = {place_result = "planetaris-assembling-machine-4"},
			["assembling-machine-4"] = {place_result = "assembling-machine-4"},
		},
		recipe = {
			["planetaris-assembling-machine-4"] = {enabled = true},
			["assembling-machine-4"] = {enabled = true},
			["promethium-transport-belt"] = {},
			["other-recipe"] = {},
		},
		technology = {
			["planetaris-automation-4"] = {effects = {
				{type = "unlock-recipe", recipe = "planetaris-assembling-machine-4"},
			}},
			["automation-4"] = {
				effects = {{type = "unlock-recipe", recipe = "assembling-machine-4"}},
				prerequisites = {"planetaris-automation-4"},
			},
			["promethium-transport-belt"] = {
				effects = {{type = "unlock-recipe", recipe = "promethium-transport-belt"}},
				prerequisites = {"automation-4"},
			},
			["mixed-tech"] = {effects = {
				{type = "unlock-recipe", recipe = "assembling-machine-4"},
				{type = "unlock-recipe", recipe = "other-recipe"},
			}},
			["mixed-child"] = {effects = {}, prerequisites = {"mixed-tech"}},
		},
	}
	rawset(_G, "data", {raw = raw})
	rawset(_G, "mods", { ["planetaris-hyarion"] = "1", LithiumBattery = "1" })
	rawset(_G, "settings", {startup = { [setting_name] = {value = true} }})
	return raw
end

local raw = fixture()
progression.data_final_fixes()

for _, name in ipairs({"automation-4", "planetaris-automation-4"}) do
	local technology = raw.technology[name]
	check(technology.hidden == true and technology.hidden_in_factoriopedia == true,
		"Technology " .. name .. " stayed visible")
	check(not technology.effects or #technology.effects == 0, "Technology " .. name .. " still has effects")
	check(logged("razi-protocol: technology " .. name .. " hidden: it only unlocked the hidden machine") == 1,
		"Expected one hidden-technology log for " .. name)
end

for _, name in ipairs({"planetaris-assembling-machine-4", "assembling-machine-4"}) do
	local item = raw.item[name]
	local recipe = raw.recipe[name]
	check(item.hidden == true and item.hidden_in_factoriopedia == true, "Item " .. name .. " stayed visible")
	check(recipe.hidden == true and recipe.hidden_in_factoriopedia == true and recipe.enabled == false,
		"Recipe " .. name .. " stayed visible or enabled")
end

local belt = raw.technology["promethium-transport-belt"]
check(belt.hidden ~= true and belt.hidden_in_factoriopedia ~= true, "A dependent technology was hidden")
check(#belt.prerequisites == 1 and belt.prerequisites[1] == "automation-4",
	"The dependent technology's prerequisites changed")

local mixed = raw.technology["mixed-tech"]
check(mixed.hidden ~= true and mixed.hidden_in_factoriopedia ~= true, "A technology with another effect was hidden")
check(#mixed.effects == 1 and mixed.effects[1].recipe == "other-recipe",
	"The unrelated unlock effect was removed")

raw = fixture()
settings.startup[setting_name].value = false
progression.data_final_fixes()
for name, technology in pairs(raw.technology) do
	check(technology.hidden ~= true and technology.hidden_in_factoriopedia ~= true,
		"Technology " .. name .. " was hidden while the setting was off")
end
check(#logs == 0, "The disabled setting logged a change")

logs = {}
rawset(_G, "data", {raw = {technology = {}, recipe = {}}})
rawset(_G, "mods", { ["planetaris-hyarion"] = "1", LithiumBattery = "1" })
rawset(_G, "settings", {startup = { [setting_name] = {value = true} }})
progression.data_final_fixes()
check(#logs == 0, "The module logged without a redundant machine")

print("test_redundant_progression: ok")
