-- Infinite research on system cards (prototypes/balance/common/infinite_research_cards.lua)
-- on a mocked data.raw. The expected values come from the design: five levels on packs, then one card of the earliest
-- system that holds the packs, the other packs kept.
-- Run from the mod root with the library bootstrap:
--   LUA_INIT=@tests/lua/razi_lib_bootstrap.lua RAZI_LIB_PATH=<RaziLib> lua5.2 tests/lua/test_infinite_research_cards.lua
package.path = "./?.lua;./?/init.lua;" .. package.path

local function check(ok, message)
	if not ok then
		error(message, 2)
	end
end

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, entry in pairs(value) do
		out[copy(key)] = copy(entry)
	end
	return out
end
rawset(table, "deepcopy", copy)

local logged = {}
rawset(_G, "log", function(message)
	logged[#logged + 1] = message
end)

local module = require("prototypes.balance.common.infinite_research_cards")

-- Names of the continuations.
local Cards = module
check(Cards.continuation("foo") == "razi-cards-foo-6", "a name without a level starts at level 1: continuation at 6")
check(Cards.continuation("foo-bar-1") == "razi-cards-foo-bar-6", "level 1 in the name continues at 6")
check(Cards.continuation("worker-robots-speed-6") == "razi-cards-worker-robots-speed-11", "level 6 continues at 11")
local base, level = Cards.split("a-b-12")
check(base == "a-b" and level == 12, "only the last number is the level")
base, level = Cards.split("kr-imersite-productivity")
check(base == "kr-imersite-productivity" and level == 1, "no number: level 1")

-- Fixture: the eight cards as the mod makes them, a lab per tier and a few researches.
local cards = {
	"calidus-tech-card", "solaris-tech-card", "nyxaris-tech-card", "vibrant-tech-card",
	"vespera-tech-card", "beetlejuice-tech-card", "umbra-tech-card", "deep-space-tech-card"
}
local card_ingredients = {
	["calidus-tech-card"] = {"automation-science-pack", "logistic-science-pack", "chemical-science-pack"},
	["solaris-tech-card"] = {"calidus-tech-card", "metallurgic-science-pack"},
	["nyxaris-tech-card"] = {"calidus-tech-card", "agricultural-science-pack"},
	["vibrant-tech-card"] = {"solaris-tech-card", "nyxaris-tech-card", "electromagnetic-science-pack"},
	["vespera-tech-card"] = {"solaris-tech-card", "nyxaris-tech-card", "cryogenic-science-pack"},
	["beetlejuice-tech-card"] = {"vibrant-tech-card", "vespera-tech-card", "golden-science-pack"},
	["umbra-tech-card"] = {"vibrant-tech-card", "vespera-tech-card", "bioluminescent-science-pack"},
	["deep-space-tech-card"] = {"beetlejuice-tech-card", "umbra-tech-card", "promethium-science-pack"}
}
local card_unlocks = {
	["calidus-tech-card"] = {"space-science-pack"},
	["solaris-tech-card"] = {"planet-discovery-castra"},
	["nyxaris-tech-card"] = {"planet-discovery-moshine"},
	["vibrant-tech-card"] = {"planet-discovery-ribbonia"},
	["vespera-tech-card"] = {"planet-discovery-muria"},
	["beetlejuice-tech-card"] = {"planet-discovery-cubium"},
	["umbra-tech-card"] = {"planet-discovery-tenebris"},
	-- two researches open the last card; the one that sorts first needs the other
	["deep-space-tech-card"] = {"a-singularity-theory", "promethium-882-research"}
}
local effects = {{type = "mining-drill-productivity-bonus", modifier = 0.1}}

local function research(name, packs, extra)
	local ingredients = {}
	for _, pack in ipairs(packs) do
		ingredients[#ingredients + 1] = {pack[1] or pack, pack[2] or 1}
	end
	local result = {
		type = "technology", name = name, prerequisites = {"earlier"},
		icons = {{icon = "__base__/graphics/technology/" .. name .. ".png", icon_size = 256}},
		effects = copy(effects), upgrade = true, max_level = "infinite",
		unit = {count_formula = "1000*(L-1)", time = 60, ingredients = ingredients}
	}
	for key, value in pairs(extra or {}) do
		result[key] = value
	end
	return result
end

local function build(list, lab_extra)
	local raw = {technology = {}, tool = {}, recipe = {}, lab = {}}
	local inputs = {}
	for _, card in ipairs(cards) do
		raw.tool[card] = {type = "tool", name = card, icon = "__razi-protocol__/graphics/icons/tech-cards/" .. card .. ".png", icon_size = 256}
		local ingredients = {}
		for _, name in ipairs(card_ingredients[card]) do
			ingredients[#ingredients + 1] = {type = "item", name = name, amount = 1}
		end
		raw.recipe[card] = {type = "recipe", name = card, enabled = false, ingredients = ingredients,
			results = {{type = "item", name = card, amount = 1}}}
		-- the recipe of several cards at once is no recipe of the card
		raw.recipe["multiplex-" .. card] = {type = "recipe", name = "multiplex-" .. card, enabled = false,
			ingredients = {{type = "item", name = "iron-plate", amount = 5}}, results = {{type = "item", name = card, amount = 4}}}
		inputs[#inputs + 1] = card
		for _, unlock in ipairs(card_unlocks[card]) do
			raw.technology[unlock] = raw.technology[unlock] or {type = "technology", name = unlock, prerequisites = {},
				effects = {}, unit = {count = 1, time = 1, ingredients = {{"automation-science-pack", 1}}}}
			local effects_of = raw.technology[unlock].effects
			effects_of[#effects_of + 1] = {type = "unlock-recipe", recipe = card}
		end
	end
	raw.technology["a-singularity-theory"].prerequisites = {"promethium-882-research"}
	for _, pack in ipairs({"automation-science-pack", "logistic-science-pack", "chemical-science-pack", "metallurgic-science-pack",
		"agricultural-science-pack", "electromagnetic-science-pack", "cryogenic-science-pack", "golden-science-pack",
		"bioluminescent-science-pack", "promethium-science-pack", "kr-advanced-tech-card"}) do
		inputs[#inputs + 1] = pack
	end
	for _, name in ipairs(lab_extra or {}) do
		inputs[#inputs + 1] = name
	end
	raw.lab.lab = {type = "lab", name = "lab", inputs = inputs}
	for _, definition in ipairs(list) do
		raw.technology[definition.name] = definition
	end
	rawset(_G, "data", {raw = raw, extend = function(self, prototypes)
		for _, prototype in ipairs(prototypes) do
			self.raw[prototype.type][prototype.name] = prototype
		end
	end})
	rawset(_G, "settings", {startup = {["razi-infinite-research-cards"] = {value = true}}})
	return raw
end

local function contains(list, wanted)
	for _, entry in ipairs(list or {}) do
		if (type(entry) == "table" and (entry.name or entry[1]) or entry) == wanted then
			return true
		end
	end
	return false
end

local function amount(list, wanted)
	for _, entry in ipairs(list or {}) do
		if (entry.name or entry[1]) == wanted then
			return entry.amount or entry[2]
		end
	end
end

local raw = build({
	-- Vibrant is the earliest card with the packs of Calidus, Solaris, Nyxaris and Vibrant; the K2 card stays at 2
	research("mixed-productivity", {"automation-science-pack", "logistic-science-pack", "chemical-science-pack",
		"metallurgic-science-pack", "agricultural-science-pack", "electromagnetic-science-pack", {"kr-advanced-tech-card", 2}}),
	-- starts at level 6; only Calidus packs
	research("red-damage-6", {"automation-science-pack", "chemical-science-pack"}),
	-- Vibrant pack alone: its card needs the Solaris and Nyxaris cards, so they are no matter for the choice
	research("blue-speed-2", {"electromagnetic-science-pack"}),
	-- Beetlejuice and Umbra are not within each other: the card of Deep Space
	research("deep-effect", {"golden-science-pack", "bioluminescent-science-pack"}),
	-- already a system card
	research("card-effect", {"solaris-tech-card", "metallurgic-science-pack"}),
	-- no pack of a system
	research("kr-effect", {"kr-advanced-tech-card"}),
	research("hidden-effect", {"automation-science-pack"}, {hidden = true}),
	research("disabled-effect", {"automation-science-pack"}, {enabled = false}),
	research("finite-effect", {"automation-science-pack"}, {max_level = 5}),
	research("trigger-effect", {"automation-science-pack"}, {unit = false, research_trigger = {type = "craft-item", item = "iron-plate"}}),
	-- a pack that no laboratory takes
	research("labless-effect", {"automation-science-pack", "orphan-science-pack"}),
	-- the first research of a name that the continuation of another one already has
	research("taken-effect", {"automation-science-pack"}),
	{type = "technology", name = "razi-cards-taken-effect-6", prerequisites = {}, effects = {}, max_level = 3,
		unit = {count = 1, time = 1, ingredients = {{"automation-science-pack", 1}}}}
})

module.data_final_fixes()
local techs = raw.technology

-- The first five levels stay on the packs.
check(techs["mixed-productivity"].max_level == 5, "mixed-productivity ends at level 5 (1 + 4)")
check(techs["red-damage-6"].max_level == 10, "red-damage-6 ends at level 10 (6 + 4)")
check(techs["blue-speed-2"].max_level == 6, "blue-speed-2 ends at level 6 (2 + 4)")
check(#techs["mixed-productivity"].unit.ingredients == 7 and techs["mixed-productivity"].unit.ingredients[1][1] == "automation-science-pack",
	"the research below the continuation keeps its packs")

-- The continuation.
local mixed = techs["razi-cards-mixed-productivity-6"] or error("mixed-productivity continues at level 6")
check(mixed.max_level == "infinite" and mixed.upgrade == true, "the continuation is infinite and an upgrade")
check(mixed.unit.count_formula == "1000*(L-1)" and mixed.unit.time == 60, "formula and time stay")
check(#mixed.effects == 1 and mixed.effects[1].modifier == 0.1 and mixed.effects ~= techs["mixed-productivity"].effects,
	"the same effects, in a table of their own")
check(#mixed.unit.ingredients == 2, "a card and the K2 card, nothing else")
check(mixed.unit.ingredients[1][1] == "vibrant-tech-card" and mixed.unit.ingredients[1][2] == 1, "one Vibrant card for each unit")
check(amount(mixed.unit.ingredients, "kr-advanced-tech-card") == 2, "the pack outside the cards keeps its amount")
check(#mixed.prerequisites == 2 and contains(mixed.prerequisites, "mixed-productivity")
	and contains(mixed.prerequisites, "planet-discovery-ribbonia"),
	"it needs the research it continues and the one that unlocks the Vibrant card")
check(#mixed.icons == 2 and mixed.icons[2].icon:find("vibrant-tech-card", 1, true) and mixed.icons[2].floating,
	"the card is on the icon, over the icon of the research")
check(mixed.icons[2].scale * mixed.icons[2].icon_size == 96 and mixed.icons[2].shift[1] > 0 and mixed.icons[2].shift[2] > 0,
	"the card is 96 pixels, at the lower right")
check(techs["mixed-productivity"].icons[2] == nil, "the icon of the research itself is not changed")
check(mixed.localised_name[1] == "?" and mixed.localised_name[2][1] == "technology-name.mixed-productivity"
	and mixed.localised_name[3][1] == "technology-name.mixed-productivity",
	"the name is the one of the research it continues")
check(mixed.localised_description[2][1] == "technology-description.mixed-productivity", "so is the description")

local red = techs["razi-cards-red-damage-11"] or error("red-damage-6 continues at level 11")
check(red.unit.ingredients[1][1] == "calidus-tech-card" and #red.unit.ingredients == 1,
	"only Calidus packs: the Calidus card, nothing else")
check(#red.prerequisites == 2 and contains(red.prerequisites, "red-damage-6") and contains(red.prerequisites, "space-science-pack"),
	"the Calidus card is unlocked by the space science pack research")

local blue = techs["razi-cards-blue-speed-7"] or error("blue-speed-2 continues at level 7")
check(blue.unit.ingredients[1][1] == "vibrant-tech-card", "the pack of Vibrant is a Vibrant card")

local deep = techs["razi-cards-deep-effect-6"] or error("deep-effect continues at level 6")
check(deep.unit.ingredients[1][1] == "deep-space-tech-card", "Beetlejuice and Umbra packs together: Deep Space")
check(contains(deep.prerequisites, "promethium-882-research") and not contains(deep.prerequisites, "a-singularity-theory"),
	"of two researches that unlock the last card the earlier one")

-- What stays alone.
for _, name in ipairs({"card-effect", "kr-effect", "hidden-effect", "disabled-effect", "finite-effect", "trigger-effect"}) do
	check(techs["razi-cards-" .. name .. "-6"] == nil, name .. " gets no continuation")
	check(techs[name].max_level == "infinite" or name == "finite-effect", name .. " keeps its max_level")
end
check(techs["finite-effect"].max_level == 5, "a finite research is not touched")
check(techs["labless-effect"].max_level == "infinite" and techs["razi-cards-labless-effect-6"] == nil,
	"a research that no laboratory could take with the card stays as it is")
check(techs["taken-effect"].max_level == "infinite" and techs["razi-cards-taken-effect-6"].max_level == 3,
	"a name that is taken stays taken")
local count = 0
for name in pairs(techs) do
	if name:find("^razi%-cards%-") then
		count = count + 1
	end
end
check(count == 5, "five continuations (and the one that was there), found " .. count)

-- The same call again changes nothing: the continuations exist, the originals have a level cap and are no longer infinite.
local total = 0
for _ in pairs(techs) do
	total = total + 1
end
module.data_final_fixes()
local after = 0
for _ in pairs(techs) do
	after = after + 1
end
check(after == total, "a second pass makes no research")

-- A pack of a card that was not in the final recipe is not a pack of the card.
local trimmed = build({research("late-effect", {"automation-science-pack", "metallurgic-science-pack"})})
trimmed.recipe["solaris-tech-card"].ingredients = {{type = "item", name = "calidus-tech-card", amount = 1}}
module.data_final_fixes()
check(trimmed.technology["razi-cards-late-effect-6"].unit.ingredients[1][1] == "calidus-tech-card"
	and #trimmed.technology["razi-cards-late-effect-6"].unit.ingredients == 2,
	"the packs come from the final card recipes: the Solaris card no longer holds the metallurgic pack, which stays")

-- A research in plain icon fields gets icons.
local plain = build({research("plain-effect", {"automation-science-pack"}, {icons = false, icon = "__base__/plain.png", icon_size = 256})})
plain.technology["plain-effect"].icons = nil
module.data_final_fixes()
local plain_continuation = plain.technology["razi-cards-plain-effect-6"] or error("plain-effect continues at level 6")
check(plain_continuation.icon == nil and #plain_continuation.icons == 2
	and plain_continuation.icons[1].icon == "__base__/plain.png", "icon and icon_size become icons")
check(plain_continuation.icons[1].icon_size == 256, "the icon_size of the research goes with its icon")

-- An icon without icon_size is 64 (the default of IconData, for a technology as well): Igrys gives its copper plate
-- research the icon of the item and no size, and a layer of 256 over that image fails the game at start.
local sizeless = build({research("sizeless-effect", {"automation-science-pack"},
	{icons = false, icon = "__base__/graphics/icons/copper-plate.png"})})
sizeless.technology["sizeless-effect"].icons = nil
module.data_final_fixes()
local sizeless_continuation = sizeless.technology["razi-cards-sizeless-effect-6"]
	or error("sizeless-effect continues at level 6")
check(sizeless_continuation.icons[1].icon_size == 64, "an icon without icon_size stays at 64 in the continuation")

-- A card whose recipe is open from the start needs no research for it; one that nothing opens is no card.
local open_card = build({research("open-effect", {"automation-science-pack"})})
open_card.recipe["calidus-tech-card"].enabled = true
module.data_final_fixes()
local open_continuation = open_card.technology["razi-cards-open-effect-6"] or error("open-effect continues at level 6")
check(#open_continuation.prerequisites == 1 and open_continuation.prerequisites[1] == "open-effect",
	"a card open from the start adds no prerequisite")
local locked = build({research("locked-effect", {"automation-science-pack"})})
locked.technology["space-science-pack"].effects = {}
module.data_final_fixes()
check(locked.technology["razi-cards-locked-effect-6"] == nil and locked.technology["locked-effect"].max_level == "infinite",
	"a card that nothing unlocks leaves the research as it is")

-- With razi-auto-tech-cards the research costs the card of each pack: that card stands for the pack, the card of a pack
-- outside the system cards stays, and the laboratory has to take it.
local auto = build({research("auto-effect", {"razi-automation-science-pack-tech-card", "razi-metallurgic-science-pack-tech-card",
	{"razi-orphan-science-pack-tech-card", 3}})}, {"razi-orphan-science-pack-tech-card"})
module.data_final_fixes()
local auto_continuation = auto.technology["razi-cards-auto-effect-6"] or error("auto-effect continues at level 6")
check(#auto_continuation.unit.ingredients == 2 and auto_continuation.unit.ingredients[1][1] == "solaris-tech-card"
	and amount(auto_continuation.unit.ingredients, "razi-orphan-science-pack-tech-card") == 3,
	"the cards of the packs of a system are one system card, the card of another pack stays")

-- An own name is kept.
local named = build({research("named-effect", {"automation-science-pack"}, {localised_name = {"mod-text.named"}})})
module.data_final_fixes()
check(named.technology["razi-cards-named-effect-6"].localised_name[1] == "mod-text.named", "a name the research has is the name")

-- Setting off: nothing at all.
local off = build({research("off-effect", {"automation-science-pack"})})
settings.startup["razi-infinite-research-cards"].value = false -- luacheck: ignore 122 (the fixture switches the setting off)
local snapshot = copy(off)
module.data_final_fixes()
local function equal(a, b)
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for key, value in pairs(a) do
		if not equal(value, b[key]) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end
check(equal(snapshot, off), "with the setting off the data stays as it was")

print("ok")
