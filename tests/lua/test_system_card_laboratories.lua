-- Tiering of system cards across existing laboratories (compat/system_card_laboratories.lua) on a mocked data.raw.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_system_card_laboratories.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local card_names = {
	"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card", "vibrant-tech-card",
	"vespera-tech-card", "beetlejuice-tech-card", "umbra-tech-card", "deep-space-tech-card"
}

local function contains(lab, input)
	for _, name in ipairs(lab.inputs) do
		if name == input then return true end
	end
	return false
end

local function count(lab, input)
	local n = 0
	for _, name in ipairs(lab.inputs) do
		if name == input then n = n + 1 end
	end
	return n
end

---@return table<string, table>
local function build(with_thermodynamics)
	local tools = {}
	for _, name in ipairs(card_names) do tools[name] = {type = "tool", name = name} end
	for _, name in ipairs({"automation-science-pack", "chemical-science-pack", "utility-science-pack"}) do
		tools[name] = {type = "tool", name = name}
	end
	---@type table<string, table>
	local labs = {
		lab = {type = "lab", name = "lab", inputs = {"automation-science-pack", "solaris-tech-card"}},
		biolab = {type = "lab", name = "biolab", inputs = {"automation-science-pack"}},
		["kr-advanced-lab"] = {type = "lab", name = "kr-advanced-lab",
			inputs = {"automation-science-pack", "chemical-science-pack", "deep-space-tech-card"}},
		["kr-singularity-lab"] = {type = "lab", name = "kr-singularity-lab",
			inputs = {"automation-science-pack", "chemical-science-pack", "beetlejuice-tech-card",
				"beetlejuice-tech-card"}},
		["omega-lab"] = {type = "lab", name = "omega-lab",
			inputs = {"automation-science-pack", "chemical-science-pack", "utility-science-pack"}},
		-- A lab of an unrelated mod is never touched.
		["foreign-lab"] = {type = "lab", name = "foreign-lab", inputs = {"automation-science-pack", "deep-space-tech-card"}}
	}
	if with_thermodynamics then
		labs["thermodynamics-lab"] = {type = "lab", name = "thermodynamics-lab",
			inputs = {"automation-science-pack", "chemical-science-pack", "vibrant-tech-card"}}
	end
	rawset(_G, "log", function(_) end)
	rawset(_G, "data", {raw = {lab = labs, tool = tools, technology = {
		-- Every pack of this technology is accepted by omega-lab only after the pass.
		["mixed-vibrant-research"] = {type = "technology", name = "mixed-vibrant-research",
			unit = {ingredients = {{"vibrant-tech-card", 1}, {"chemical-science-pack", 1}}}},
		["utility-deep-research"] = {type = "technology", name = "utility-deep-research",
			unit = {ingredients = {{"deep-space-tech-card", 1}, {"utility-science-pack", 1}}}}
	}, recipe = {}}})
	return labs
end

---@type table<string, table>
local labs = build(true)
local module = require("prototypes.compat.system_card_laboratories")
module.data_final_fixes()

check(not contains(labs.lab, "solaris-tech-card"), "Basic laboratory must stop at Calidus")
check(contains(labs.lab, "calidus-tech-card"), "Basic laboratory takes the Calidus card")
check(contains(labs.biolab, "solaris-tech-card") and contains(labs.biolab, "nyxaris-tech-card"),
	"Biolab handles the second tier")
check(not contains(labs.biolab, "vibrant-tech-card"), "Biolab must not take the mid-tier")
check(not contains(labs["kr-advanced-lab"], "vibrant-tech-card"), "Advanced lab must not swallow the mid-tier")
check(not contains(labs["kr-advanced-lab"], "deep-space-tech-card"), "Advanced lab must not take Deep Space")
check(contains(labs["thermodynamics-lab"], "vibrant-tech-card")
	and contains(labs["thermodynamics-lab"], "vespera-tech-card"),
	"Moshine's native lab handles the middle system cards")
check(not contains(labs["thermodynamics-lab"], "beetlejuice-tech-card"), "Thermodynamics lab stops at the middle tier")
check(contains(labs["kr-singularity-lab"], "beetlejuice-tech-card")
	and contains(labs["kr-singularity-lab"], "umbra-tech-card"),
	"Native singularity lab handles the outer frontier")
check(count(labs["kr-singularity-lab"], "beetlejuice-tech-card") == 1, "No duplicate lab inputs")
check(not contains(labs["kr-singularity-lab"], "deep-space-tech-card"), "Singularity lab stops before Deep Space")
check(contains(labs["omega-lab"], "deep-space-tech-card"), "Existing omega lab handles Deep Space")
check(contains(labs["omega-lab"], "utility-science-pack"), "Native packs of a lab are kept")
check(contains(labs["foreign-lab"], "deep-space-tech-card"), "Labs of other mods are not touched")
check(not data.raw.lab["razi-astral-lab"] and not data.raw.item, "No fabricated labs or items")
check(next(data.raw.recipe) == nil, "Lab recipes are not touched")

-- A technology whose packs no lab accepts is rescued in the nearest lab that takes its native packs.
check(contains(labs["omega-lab"], "deep-space-tech-card") and contains(labs["omega-lab"], "utility-science-pack"),
	"Deep Space + utility research has a lab")
check(contains(labs["thermodynamics-lab"], "vibrant-tech-card") and contains(labs["thermodynamics-lab"], "chemical-science-pack"),
	"Vibrant + chemical research has a lab")

-- Second run changes nothing.
local snapshot = table.concat(labs["omega-lab"].inputs, ",")
module.data_final_fixes()
check(table.concat(labs["omega-lab"].inputs, ",") == snapshot, "Second pass must be a no-op")

-- Without the thermodynamics lab the advanced K2SO lab takes the middle tier.
labs = build(false)
module.data_final_fixes()
check(contains(labs["kr-advanced-lab"], "vibrant-tech-card") and contains(labs["kr-advanced-lab"], "vespera-tech-card"),
	"Advanced lab takes the middle tier when the thermodynamics lab is missing")
check(not contains(labs["kr-advanced-lab"], "beetlejuice-tech-card"), "Advanced lab stops at the middle tier")

-- Rescue: no lab holds both Deep Space and utility packs, so the nearest lab that takes the
-- utility pack (tier 5 first, then below) receives the card instead of leaving the research stuck.
labs = build(true)
labs["omega-lab"].inputs = {"automation-science-pack", "chemical-science-pack"}
labs["kr-singularity-lab"].inputs = {"automation-science-pack", "chemical-science-pack", "utility-science-pack"}
module.data_final_fixes()
check(contains(labs["kr-singularity-lab"], "deep-space-tech-card"),
	"Rescue gives the card to a lab that accepts the other packs of the technology")
check(not contains(labs["omega-lab"], "utility-science-pack"), "Rescue never adds a native pack to a lab")
print("Native labs: tiered system-card inputs, no new entities and no recipe changes passed")
