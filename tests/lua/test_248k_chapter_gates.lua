package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function make_world(options)
	options = options or {}
	local tools = {
		["solaris-tech-card"] = {},
		["vibrant-tech-card"] = {},
		["deep-space-tech-card"] = {},
		["fi_ki_science"] = {},
		["fu_ki_science"] = {},
		["fu_space_probe_science"] = {},
		["automation-science-pack"] = {},
		["logistic-science-pack"] = {},
	}
	if options.missing_card then
		tools[options.missing_card] = nil
	end

	local technology = {
		["planet-discovery-castra"] = { prerequisites = {} },
		["planet-discovery-ribbonia"] = { prerequisites = {} },
		["razi-singularity-theory"] = { prerequisites = {} },
		["el_early_tech"] = { prerequisites = {} },
		["fi_stage_tech"] = {
			prerequisites = { "el_early_tech" },
			unit = { ingredients = { { "automation-science-pack", 1 } } },
		},
		["fi_x"] = {
			prerequisites = { "fi_stage_tech" },
			unit = { ingredients = { { name = "logistic-science-pack", amount = 2 } } },
		},
		["fi_ki_science"] = {
			prerequisites = {},
			unit = { ingredients = { { "automation-science-pack", 1 } } },
		},
		["fi_research_trigger"] = { prerequisites = {}, research_trigger = { type = "craft-item" } },
		["fi_hidden"] = { hidden = true, prerequisites = {}, unit = { ingredients = {} } },
		["fi_disabled"] = { enabled = false, prerequisites = {}, unit = { ingredients = {} } },
		["fi_cycle_tech"] = { prerequisites = {}, unit = { ingredients = {} } },
		["fu_ki_tech"] = {
			prerequisites = { "fi_ki_science" },
			unit = { ingredients = { { "automation-science-pack", 1 } } },
		},
		["fu_x"] = {
			prerequisites = { "fu_ki_tech" },
			unit = { ingredients = { { "automation-science-pack", 1 }, { "vibrant-tech-card", 1 } } },
		},
		["gr_stage_tech"] = {
			prerequisites = { "el_early_tech" },
			unit = { ingredients = { { "automation-science-pack", 1 } } },
		},
		["gr_x"] = {
			prerequisites = { "gr_stage_tech" },
			unit = { ingredients = { { "automation-science-pack", 1 } } },
		},
		["el_unchanged"] = {
			prerequisites = {},
			unit = { ingredients = { { "automation-science-pack", 1 } } },
		},
	}
	if options.missing_gate then
		technology[options.missing_gate] = nil
	end
	if options.cycle then
		technology["planet-discovery-castra"].prerequisites = { "fi_cycle_tech" }
	end

	local labs = {
		["biolab"] = { inputs = {} },
		["kr-advanced-lab"] = { inputs = {} },
		["thermodynamics-lab"] = { inputs = {} },
		["pressure-lab"] = { inputs = {} },
		["kr-singularity-lab"] = { inputs = {} },
		["lab"] = { inputs = {} },
		["fu_lab"] = { inputs = {} },
		["gr_lab"] = { inputs = {} },
	}
	if options.no_thermodynamics_lab then
		labs["thermodynamics-lab"] = nil
	end

	local logs = {}
	rawset(_G, "data", { raw = { tool = tools, technology = technology, lab = labs } })
	rawset(_G, "mods", options.no_mod and {} or { ["248k-Redux"] = "2.1.51" })
	rawset(_G, "log", function(message)
		logs[#logs + 1] = message
	end)
	return {
		technology = technology,
		tools = tools,
		labs = labs,
		logs = logs,
	}
end

local function has_prerequisite(technology, name)
	for _, prerequisite in ipairs(technology.prerequisites or {}) do
		if prerequisite == name then
			return true
		end
	end
	return false
end

local function ingredient_count(technology, name)
	local count = 0
	for _, ingredient in ipairs(technology.unit and technology.unit.ingredients or {}) do
		if (ingredient.name or ingredient[1]) == name then
			count = count + 1
		end
	end
	return count
end

local function has_input(lab, name)
	for _, input in ipairs(lab and lab.inputs or {}) do
		if input == name then
			return true
		end
	end
	return false
end

local chapter_gates = require("prototypes.compatibility.248k-Redux.chapter_gates")
local lab_inputs = require("prototypes.compatibility.248k-Redux.lab_inputs")
local world = make_world({ cycle = true })
local techs, labs, logs = world.technology, world.labs, world.logs
chapter_gates.data_final_fixes()
lab_inputs.data_final_fixes()

check(ingredient_count(techs["fi_stage_tech"], "solaris-tech-card") == 1, "fission card added")
check(ingredient_count(techs["fi_stage_tech"], "automation-science-pack") == 1, "vanilla pack preserved")
check(ingredient_count(techs["fi_x"], "solaris-tech-card") == 1, "child fission card added")
check(ingredient_count(techs["fi_x"], "logistic-science-pack") == 1, "named vanilla pack preserved")
check(has_prerequisite(techs["fi_stage_tech"], "planet-discovery-castra"), "fission root follows Castra")
check(not has_prerequisite(techs["fi_x"], "planet-discovery-castra"), "fission child keeps its stage prerequisite")
check(has_prerequisite(techs["fu_ki_tech"], "planet-discovery-ribbonia"), "fusion root with fission prerequisite follows Ribbonia")
check(ingredient_count(techs["fu_ki_tech"], "vibrant-tech-card") == 1, "fusion card added")
check(ingredient_count(techs["fu_x"], "vibrant-tech-card") == 1, "existing fusion card is not duplicated")
check(has_prerequisite(techs["gr_stage_tech"], "razi-singularity-theory"), "gravitation root follows singularity theory")
check(ingredient_count(techs["gr_stage_tech"], "deep-space-tech-card") == 1, "gravitation card added")
check(not has_prerequisite(techs["el_unchanged"], "planet-discovery-castra"), "electronic technology stays unchanged")
check(ingredient_count(techs["el_unchanged"], "solaris-tech-card") == 0, "electronic cost stays unchanged")
check(ingredient_count(techs["fi_research_trigger"], "solaris-tech-card") == 0, "research trigger is not changed")
check(ingredient_count(techs["fi_hidden"], "solaris-tech-card") == 0, "hidden technology is not changed")
check(ingredient_count(techs["fi_disabled"], "solaris-tech-card") == 0, "disabled technology is not changed")
check(not has_prerequisite(techs["fi_cycle_tech"], "planet-discovery-castra"), "cyclic gate is skipped")

chapter_gates.data_final_fixes()
lab_inputs.data_final_fixes()
check(ingredient_count(techs["fi_stage_tech"], "solaris-tech-card") == 1, "second call does not duplicate fission card")
check(ingredient_count(techs["fu_x"], "vibrant-tech-card") == 1, "second call does not duplicate fusion card")
check(#techs["fi_stage_tech"].prerequisites == 2, "second call does not duplicate fission gate")

for _, lab_name in ipairs({ "biolab", "kr-advanced-lab", "thermodynamics-lab", "pressure-lab", "kr-singularity-lab" }) do
	check(has_input(labs[lab_name], "fi_ki_science"), "fission KI input in " .. lab_name)
end
check(not has_input(labs.lab, "fi_ki_science"), "base lab stays unchanged")
check(not has_input(labs.fu_lab, "fu_ki_science"), "248k fusion lab stays unchanged")
check(not has_input(labs.gr_lab, "fu_space_probe_science"), "248k gravitation lab stays unchanged")
for _, lab_name in ipairs({ "thermodynamics-lab", "pressure-lab", "kr-singularity-lab" }) do
	check(has_input(labs[lab_name], "fu_ki_science"), "fusion KI input in " .. lab_name)
	check(has_input(labs[lab_name], "fu_space_probe_science"), "space probe input in " .. lab_name)
end
check(not has_input(labs["kr-advanced-lab"], "fu_ki_science"), "fusion inputs use thermodynamics lab when present")
check(#logs > 0, "modification logs emitted")

local missing_gate_world = make_world({ missing_gate = "planet-discovery-ribbonia" })
techs = missing_gate_world.technology
chapter_gates.data_final_fixes()
check(ingredient_count(techs["fu_ki_tech"], "vibrant-tech-card") == 0, "missing Ribbonia gate leaves fusion cost unchanged")
check(not has_prerequisite(techs["fu_ki_tech"], "planet-discovery-ribbonia"), "missing Ribbonia gate leaves fusion prerequisites unchanged")

local missing_card_world = make_world({ missing_card = "deep-space-tech-card" })
techs = missing_card_world.technology
chapter_gates.data_final_fixes()
check(ingredient_count(techs["gr_stage_tech"], "deep-space-tech-card") == 0, "missing Deep Space card leaves gravitation cost unchanged")
check(not has_prerequisite(techs["gr_stage_tech"], "razi-singularity-theory"), "missing Deep Space card leaves gravitation prerequisites unchanged")

local fallback_world = make_world({ no_thermodynamics_lab = true })
labs = fallback_world.labs
lab_inputs.data_final_fixes()
check(has_input(labs["kr-advanced-lab"], "fi_ki_science"), "fallback lab gets fission KI input")
check(has_input(labs["kr-advanced-lab"], "fu_ki_science"), "fallback lab gets fusion KI input")
check(has_input(labs["kr-advanced-lab"], "fu_space_probe_science"), "fallback lab gets space probe input")

local missing_science_world = make_world()
missing_science_world.tools["fu_ki_science"] = nil
labs = missing_science_world.labs
lab_inputs.data_final_fixes()
check(not has_input(labs["thermodynamics-lab"], "fu_ki_science"), "missing science tool is skipped")

local vanilla_world = make_world({ no_mod = true })
techs, labs = vanilla_world.technology, vanilla_world.labs
chapter_gates.data_final_fixes()
lab_inputs.data_final_fixes()
check(ingredient_count(techs["fi_stage_tech"], "solaris-tech-card") == 0, "no 248k mod means no chapter costs")
check(not has_prerequisite(techs["fi_stage_tech"], "planet-discovery-castra"), "no 248k mod means no chapter gates")
check(not has_input(labs.biolab, "fi_ki_science"), "no 248k mod means no lab inputs")

print("test_248k_chapter_gates: ok")
