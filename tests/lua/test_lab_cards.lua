-- System tech cards (compat/lab_cards.lua) on a mocked data.raw, without a Factorio binary.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_lab_cards.lua
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

local function build(options)
	local raw = {tool = {}, item = {}, recipe = {}, technology = {}, lab = {},
		["item-group"] = {}, ["item-subgroup"] = {}}
	rawset(_G, "data", {raw = raw})
	data.extend = function(_, prototypes)
		for _, prototype in ipairs(prototypes) do
			raw[prototype.type] = raw[prototype.type] or {}
			raw[prototype.type][prototype.name] = prototype
		end
	end
	rawset(_G, "log", function(_) end)

	for _, name in ipairs(options.packs) do
		raw.tool[name] = {type = "tool", name = name}
	end
	for _, name in ipairs(options.technologies) do
		raw.technology[name] = {type = "technology", name = name, effects = {}}
	end
	raw.lab.lab = {type = "lab", name = "lab", inputs = {"automation-science-pack"}}
	raw.lab.biolab = {type = "lab", name = "biolab", inputs = {"automation-science-pack"}}
	if options.science_group then
		raw["item-group"].science = {type = "item-group", name = "science"}
	end

	package.loaded["prototypes.compat.lab_cards"] = nil
	require("prototypes.compat.lab_cards").data_final_fixes()
	return raw
end

local function amounts(recipe)
	local result = {}
	for _, ingredient in ipairs(recipe.ingredients) do
		result[ingredient.name] = ingredient.amount
	end
	return result
end

local function contains(list, value)
	for _, entry in ipairs(list) do
		if entry == value then
			return true
		end
	end
	return false
end

local full_packs = {
	"automation-science-pack", "logistic-science-pack", "military-science-pack",
	"chemical-science-pack", "production-science-pack", "utility-science-pack",
	"space-science-pack", "metallurgic-science-pack", "tungsten-science-pack",
	"agricultural-science-pack", "electromagnetic-science-pack",
	"battlefield-science-pack", "insulation-science-pack", "thermodynamic-science-pack",
	"apicultural-science-pack", "ribbonia-alien-science-pack",
	"acidworking-science-pack", "cryogenic-science-pack",
	"biorecycling-science-pack", "rubia-biofusion-science-pack",
	"golden-science-pack", "bioluminescent-science-pack",
	"gas-manipulation-science-pack", "planet-crucible-science-pack",
	"promethium-science-pack", "planetaris-compression-science-pack",
	"planetaris-polishing-science-pack", "planetaris-bioengineering-science-pack",
	"planetaris-pathological-science-pack", "planetaris-refraction-science-pack"
}
local technologies = {
	"space-science-pack", "planet-discovery-castra", "planet-discovery-moshine",
	"planet-discovery-ribbonia", "planet-discovery-muria", "planet-discovery-cubium",
	"planet-discovery-tenebris", "razi-singularity-theory"
}

-- All packs present: eight cards with recipes, unlocks and the nested tree.
local raw = build({packs = full_packs, technologies = technologies, science_group = true})
for _, name in ipairs(card_names) do
	check(raw.tool[name], name .. " item is missing")
	check(raw.recipe[name], name .. " recipe is missing")
	check(raw.recipe[name].enabled == false, name .. " recipe must start disabled")
	check(raw.tool[name].subgroup == "system-tech-card", name .. " must sit in the card subgroup")
end
check(raw["item-subgroup"]["system-tech-card"].group == "science", "Science group is used when present")

check(raw.recipe["calidus-tech-card"].energy_required == 10, "Calidus craft time")
check(raw.recipe["vespera-tech-card"].energy_required == 16, "Vespera craft time")
check(raw.recipe["umbra-tech-card"].energy_required == 22, "Umbra craft time")
check(raw.recipe["deep-space-tech-card"].energy_required == 28, "Deep Space craft time")

local vespera = amounts(raw.recipe["vespera-tech-card"])
check(vespera["acidworking-science-pack"] == 1, "Vespera takes the acidworking pack")
check(vespera["solaris-tech-card"] == 1 and vespera["nyxaris-tech-card"] == 1,
	"Vespera needs Solaris and Nyxaris cards")
check(not vespera["muriatic-science-pack"], "The old muriatic name must not be used")

-- System cards stay at one; outer-system packs follow regional_science_amount.
local umbra = amounts(raw.recipe["umbra-tech-card"])
check(umbra["vibrant-tech-card"] == 1 and umbra["vespera-tech-card"] == 1,
	"Predecessor cards are one each")
check(umbra["bioluminescent-science-pack"] == 2 and umbra["planet-crucible-science-pack"] == 2,
	"Outer-system packs come two at a time")
local beetlejuice = amounts(raw.recipe["beetlejuice-tech-card"])
check(beetlejuice["golden-science-pack"] == 2 and beetlejuice["vibrant-tech-card"] == 1,
	"Beetlejuice mixes one card per predecessor and two packs")
local solaris = amounts(raw.recipe["solaris-tech-card"])
check(solaris["calidus-tech-card"] == 1 and solaris["tungsten-science-pack"] == 1,
	"Inner frontier packs stay single")
-- Pathological and refraction science need Fulgora, so they belong to the Vibrant card, not Solaris.
check(solaris["planetaris-polishing-science-pack"] == 1, "Solaris keeps the other Planetaris packs")
check(not solaris["planetaris-pathological-science-pack"] and not solaris["planetaris-refraction-science-pack"],
	"Solaris must not need Fulgora's science")
local vibrant = amounts(raw.recipe["vibrant-tech-card"])
check(vibrant["planetaris-pathological-science-pack"] == 1 and vibrant["planetaris-refraction-science-pack"] == 1,
	"Vibrant takes the Fulgora-bound Planetaris packs")
local deep = amounts(raw.recipe["deep-space-tech-card"])
check(deep["beetlejuice-tech-card"] == 1 and deep["umbra-tech-card"] == 1
	and deep["promethium-science-pack"] == 2, "Deep Space ingredients")

local function unlocks(technology, recipe)
	for _, effect in ipairs(raw.technology[technology].effects) do
		if effect.type == "unlock-recipe" and effect.recipe == recipe then
			return true
		end
	end
	return false
end
check(unlocks("planet-discovery-muria", "vespera-tech-card"), "Muria discovery unlocks Vespera")
check(unlocks("planet-discovery-tenebris", "umbra-tech-card"), "Tenebris discovery unlocks Umbra")
check(unlocks("planet-discovery-cubium", "beetlejuice-tech-card"), "Cubium discovery unlocks Beetlejuice")

-- Labs: every card but Deep Space goes to regular labs, without duplicates.
for _, lab in pairs(raw.lab) do
	for _, name in ipairs(card_names) do
		if name == "deep-space-tech-card" then
			check(not contains(lab.inputs, name), "Deep Space stays out of regular labs")
		else
			check(contains(lab.inputs, name), name .. " missing from " .. lab.name)
		end
	end
	local seen = {}
	for _, input in ipairs(lab.inputs) do
		check(not seen[input], "Duplicate lab input " .. input)
		seen[input] = true
	end
end

-- Without the packs the fallback ingredients take over.
raw = build({packs = {"space-science-pack"}, technologies = technologies})
check(raw.recipe["calidus-tech-card"], "Calidus is built from the vanilla pack")
local solaris_fallback = amounts(raw.recipe["solaris-tech-card"])
check(solaris_fallback["calidus-tech-card"] == 1, "Solaris falls back to the Calidus card")
local vespera_fallback = amounts(raw.recipe["vespera-tech-card"])
check(vespera_fallback["solaris-tech-card"] == 1 and vespera_fallback["nyxaris-tech-card"] == 1,
	"Vespera falls back to its two predecessor cards")
check(raw["item-subgroup"]["system-tech-card"].group == "intermediate-products",
	"Without Science Tab the subgroup uses the vanilla group")

-- No packs at all: no cards, no errors.
raw = build({packs = {}, technologies = {}})
check(next(raw.recipe) == nil, "No ingredients means no recipes")

print("test_lab_cards: ok")
