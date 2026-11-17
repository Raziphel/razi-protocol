---@diagnostic disable: missing-fields, need-check-nil, inject-field
-- Eneas with integrate-lignumis removes a Lignumis robotics technology; nothing may still require it.
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

local fix = require("prototypes.fixes.moon-eneas.lignumis_robotics")

local INSTALLED = {["moon-eneas"] = "1.0.10", lignumis = "2.12.4"}

-- The tree after Eneas ran its Lignumis patch: the copper robotics technology is gone.
local function world(technologies, installed)
	logs = {}
	rawset(_G, "mods", installed or INSTALLED)
	rawset(_G, "data", {raw = {technology = technologies}})
	return technologies
end

local function eneas_tree()
	return {
		["wood-science-pack"] = {prerequisites = {}},
		["basic-construction-robotics-gold"] = {prerequisites = {"wood-science-pack"}},
		["automation-science-pack"] = {prerequisites = {}},
		["logistic-science-pack"] = {prerequisites = {"automation-science-pack"}},
		["basic-roboport"] = {prerequisites = {"basic-construction-robotics-copper", "logistic-science-pack"}},
	}
end

local function unknown_prerequisites(technologies)
	local unknown = {}
	for name, technology in pairs(technologies) do
		for _, prerequisite in ipairs(technology.prerequisites or {}) do
			if not technologies[prerequisite] then
				unknown[#unknown + 1] = name .. " -> " .. prerequisite
			end
		end
	end
	return table.concat(unknown, ", ")
end

local technologies = world(eneas_tree())
fix.data_final_fixes()
check(unknown_prerequisites(technologies) == "", "every prerequisite exists, got " .. unknown_prerequisites(technologies))
check(table.concat(technologies["basic-roboport"].prerequisites, ",")
	== "basic-construction-robotics-gold,automation-science-pack,logistic-science-pack",
	"basic-roboport requires what the copper robotics required, got "
	.. table.concat(technologies["basic-roboport"].prerequisites, ","))
check(#logs == 1, "the change is logged")

-- A prerequisite that is already there is not added twice.
technologies = eneas_tree()
technologies["basic-roboport"].prerequisites = {"automation-science-pack", "basic-construction-robotics-copper"}
world(technologies)
fix.data_final_fixes()
check(table.concat(technologies["basic-roboport"].prerequisites, ",")
	== "automation-science-pack,basic-construction-robotics-gold", "no duplicate prerequisites")

-- Without integrate-lignumis the technology exists and the tree stays as it is.
technologies = eneas_tree()
technologies["basic-construction-robotics-copper"] = {prerequisites = {"basic-construction-robotics-gold"}}
world(technologies)
fix.data_final_fixes()
check(table.concat(technologies["basic-roboport"].prerequisites, ",")
	== "basic-construction-robotics-copper,logistic-science-pack" and #logs == 0,
	"an existing copper robotics technology is left alone")

-- Without Eneas nothing changes.
technologies = world(eneas_tree(), {lignumis = "2.12.4"})
fix.data_final_fixes()
check(technologies["basic-roboport"].prerequisites[1] == "basic-construction-robotics-copper" and #logs == 0,
	"without Eneas nothing changes")

print("test_mod_fixes_eneas_lignumis_robotics ok")
