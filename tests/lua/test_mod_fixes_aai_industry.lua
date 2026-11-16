---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- Keep AAI Industry recipes reachable with Krastorio 2 Spaced Out, without duplicate lab unlocks.
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

local fix = require("prototypes.fixes.Krastorio2-spaced-out.aai_industry_unlocks")

local function unlock(recipe)
	return {type = "unlock-recipe", recipe = recipe}
end

local function world(technologies, installed)
	logs = {}
	rawset(_G, "mods", installed == false and {} or {["aai-industry"] = "0.7.5"})
	rawset(_G, "data", {raw = {
		recipe = {["kr-grow-wood-with-sand"] = {}, lab = {}},
		technology = technologies,
	}})
	return data.raw.technology
end

local technologies = world({
	["kr-greenhouse"] = {effects = {}},
	["kr-laboratory"] = {hidden = true, effects = {unlock("lab")}},
	["electric-lab"] = {effects = {unlock("lab")}},
})
fix.data_final_fixes()
check(#technologies["kr-greenhouse"].effects == 1
	and technologies["kr-greenhouse"].effects[1].recipe == "kr-grow-wood-with-sand",
	"kr-greenhouse opens the wood-from-sand recipe")
check(#technologies["kr-laboratory"].effects == 0, "hidden kr-laboratory no longer opens lab")
check(#technologies["electric-lab"].effects == 1 and technologies["electric-lab"].effects[1].recipe == "lab",
	"electric-lab keeps its lab unlock")
check(#logs == 2, "both AAI and K2SO repairs are logged")

-- A recipe with any existing unlock does not get a duplicate.
technologies = world({
	["kr-greenhouse"] = {effects = {}},
	other = {effects = {unlock("kr-grow-wood-with-sand")} },
})
fix.data_final_fixes()
check(#technologies["kr-greenhouse"].effects == 0 and #logs == 0,
	"an existing wood recipe unlock is preserved")

-- A visible kr-laboratory or a hidden kr-laboratory without another visible lab unlock is left alone.
technologies = world({
	["kr-laboratory"] = {hidden = false, effects = {unlock("lab")}},
	["electric-lab"] = {effects = {unlock("lab")}},
})
fix.data_final_fixes()
check(#technologies["kr-laboratory"].effects == 1 and #logs == 0,
	"visible kr-laboratory keeps its unlock")
technologies = world({
	["kr-laboratory"] = {hidden = true, effects = {unlock("lab")}},
	["other-hidden"] = {hidden = true, effects = {unlock("lab")}},
})
fix.data_final_fixes()
check(#technologies["kr-laboratory"].effects == 1 and #logs == 0,
	"hidden lab unlocks do not count as another visible unlock")

-- Without AAI Industry the K2SO prototypes stay untouched.
technologies = world({
	["kr-greenhouse"] = {effects = {}},
	["kr-laboratory"] = {hidden = true, effects = {unlock("lab")}},
	["electric-lab"] = {effects = {unlock("lab")}},
}, false)
fix.data_final_fixes()
check(#technologies["kr-greenhouse"].effects == 0 and #technologies["kr-laboratory"].effects == 1 and #logs == 0,
	"without AAI Industry nothing changes")

print("test_mod_fixes_aai_industry ok")
