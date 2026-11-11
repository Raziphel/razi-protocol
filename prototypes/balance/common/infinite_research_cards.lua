-- Infinite research on system cards. A decision about price, so it sits with the balance: the packs of a system are
-- paid with the card of that system once the card is within reach.
--
-- An infinite research that costs a pack of some system card (Calidus, Solaris, Nyxaris, Vibrant, Vespera,
-- Beetlejuice, Umbra, Deep Space) keeps its first five levels on the packs: from the level in its name (1 without
-- one) to that level plus four. From the sixth on it continues as `razi-cards-<name>-<level>` with the same effects,
-- formula and time, and it costs one card of the earliest system whose packs cover the card packs of the research,
-- for each unit, in place of those packs. Packs that no card contains stay at the amount they had. Per unit this is
-- dearer in packs than before (a card is a pack of every planet of its system) and simpler to supply: one item in place
-- of up to fourteen. The continuation needs the research it continues and the research that unlocks the card recipe.
--
-- The packs of a card come from the recipes as they are after all other passes, not from a list: a pack that a card
-- takes in is covered too. A research that costs a system card already is left alone. The pass is the last one, after
-- the repairs of other mods and the cards of the packs (razi-auto-tech-cards): a repair of a research that was copied
-- before it would not reach the copy. With the setting razi-infinite-research-cards off nothing changes.
local Graph = require("__razi_lib__/lib/technology_graph")
local Names = require("lib.infinite_research_names")
local Labs = require("prototypes.industry.cards.system_card_laboratories")

local infinite_research_cards = {}

infinite_research_cards.setting = "razi-infinite-research-cards"
-- Levels a research keeps on the packs, counted from its first.
infinite_research_cards.span = Names.span

-- The icon of the card sits at the lower right of the icon of the research: 96/256 of its width, its centre 70/256
-- of the width right and down from the centre. Scale and shift of an icon layer are in GUI units, in which a
-- technology icon is expected_icon_size / 2 = 128 wide whatever the size of its file (a first layer without a scale
-- fills it); the sizes in pixels of a 256 icon made the card twice as large and pushed it over the edge.
local label_part = 96 / 256
local shift_part = 70 / 256
local technology_icon_units = 128

-- "foo-3" is the research "foo" from level 3 on, a name without a number starts at level 1.
infinite_research_cards.split = Names.split

-- The name of the research that goes on after the five levels of `name`, which the save keeps from then on.
infinite_research_cards.continuation = Names.continuation

local function ingredient_name(entry)
	return entry.name or entry[1]
end

local function visible(technology)
	return technology.hidden ~= true and technology.enabled ~= false
end

local function science(name)
	return (data.raw.tool or {})[name] or (data.raw.item or {})[name]
end

-- Packs of each card, the packs of the cards it takes in included: card name -> {pack name -> true}.
local function card_packs()
	local recipes = data.raw.recipe or {}
	local packs = {}
	for _, card in ipairs(Labs.cards) do
		-- the recipe that makes one card from one of each pack carries the name of the card
		local recipe = recipes[card]
		if science(card) and recipe then
			local set = {}
			for _, entry in ipairs(recipe.ingredients or {}) do
				local name = ingredient_name(entry)
				if packs[name] then
					for pack in pairs(packs[name]) do
						set[pack] = true
					end
				else
					set[name] = true
				end
			end
			packs[card] = set
		end
	end
	return packs
end

local function covers(set, wanted)
	for pack in pairs(wanted) do
		if not set[pack] then
			return false
		end
	end
	return true
end

-- The research that unlocks the recipe of the card; of several the earliest, one that needs none of the others.
-- Returns nil, true when the recipe is open from the start, and nil, false when nothing unlocks it.
local function unlock_of(card, technologies)
	if data.raw.recipe[card].enabled ~= false then
		return nil, true
	end
	local found = {}
	for _, name in ipairs(Graph.unlock_index(technologies)[card] or {}) do
		if visible(technologies[name]) then
			found[#found + 1] = name
		end
	end
	for _, name in ipairs(found) do
		local earliest = true
		for _, other in ipairs(found) do
			if other ~= name and Graph.reaches(technologies, name, other) then
				earliest = false
			end
		end
		if earliest then
			return name, true
		end
	end
	return nil, false
end

-- Whether one laboratory takes all of the packs.
local function lab_takes(names)
	for _, lab in pairs(data.raw.lab or {}) do
		local inputs = {}
		for _, input in ipairs(lab.inputs or {}) do
			inputs[input] = true
		end
		local all = true
		for _, name in ipairs(names) do
			if not inputs[name] then
				all = false
				break
			end
		end
		if all then
			return true
		end
	end
	return false
end

local function icons_with_label(technology, card)
	local source = science(card)
	local icons
	if technology.icons then
		icons = table.deepcopy(technology.icons)
	else
		-- icon_size defaults to 64 for a technology as well: Igrys gives its copper plate research the 64 icon of the item
		icons = {{icon = technology.icon, icon_size = technology.icon_size or 64}}
	end
	local first = icons[1]
	local width = first.scale and (first.icon_size or 64) * first.scale or technology_icon_units
	local label_size = width * label_part
	local label_shift = width * shift_part
	for _, layer in ipairs(source.icons or {{icon = source.icon, icon_size = source.icon_size}}) do
		local size = layer.icon_size or source.icon_size or 64
		local scale = label_size / size * (layer.scale or 1)
		local shift = layer.shift or {0, 0}
		icons[#icons + 1] = {
			icon = layer.icon,
			icon_size = size,
			scale = scale,
			shift = {label_shift + shift[1] * scale, label_shift + shift[2] * scale},
			tint = layer.tint,
			floating = true
		}
	end
	return icons
end

-- The game reads the name of a leveled research without its level; a description may not exist.
local function reference(kind, technology, base)
	return technology["localised_" .. kind] or {"?", {"technology-" .. kind .. "." .. technology.name},
		{"technology-" .. kind .. "." .. base}, kind == "name" and base or ""}
end

local function split_research(technology, card, unlock, kept)
	local base, first = infinite_research_cards.split(technology.name)
	local copy = table.deepcopy(technology)
	copy.name = infinite_research_cards.continuation(technology.name)
	copy.max_level = "infinite"
	copy.upgrade = true
	copy.icon = nil
	copy.icon_size = nil
	copy.icons = icons_with_label(technology, card)
	copy.localised_name = reference("name", technology, base)
	copy.localised_description = reference("description", technology, base)
	-- the unlocking research is nil when the recipe of the card is open from the start
	copy.prerequisites = {technology.name, unlock}
	copy.unit.ingredients = {{card, 1}}
	for _, entry in ipairs(kept) do
		copy.unit.ingredients[#copy.unit.ingredients + 1] = entry
	end
	technology.max_level = first + infinite_research_cards.span - 1
	data:extend({copy})
	log("razi-protocol: " .. technology.name .. " ends at level " .. technology.max_level .. "; " .. copy.name
		.. " goes on from level " .. first + infinite_research_cards.span .. " for " .. card)
end

function infinite_research_cards.data_final_fixes()
	if not settings.startup[infinite_research_cards.setting].value then
		return
	end
	local technologies = data.raw.technology or {}
	local packs = card_packs()
	local in_cards = {}
	for _, set in pairs(packs) do
		for pack in pairs(set) do
			in_cards[pack] = true
		end
	end
	local names = {}
	for name in pairs(technologies) do
		names[#names + 1] = name
	end
	table.sort(names)
	for _, name in ipairs(names) do
		local technology = technologies[name]
		local unit = technology.unit
		if technology.max_level == "infinite" and unit and not technology.research_trigger and visible(technology) then
			local wanted, kept, has_card = {}, {}, false
			for _, entry in ipairs(unit.ingredients or {}) do
				local pack = ingredient_name(entry)
				-- with razi-auto-tech-cards the research costs the card of a pack, which stands for the pack
				local source = pack:match("^razi%-(.+)%-tech%-card$") or pack
				if packs[pack] then
					has_card = true
				elseif in_cards[source] then
					wanted[source] = true
				else
					kept[#kept + 1] = table.deepcopy(entry)
				end
			end
			-- a pack of a system is there, and no system card yet
			if next(wanted) and not has_card then
				local card
				for _, candidate in ipairs(Labs.cards) do
					if packs[candidate] and covers(packs[candidate], wanted) then
						card = candidate
						break
					end
				end
				local continuation = infinite_research_cards.continuation(name)
				if not card then
					log("razi-protocol: " .. name .. " keeps its packs: no system card contains all of them")
				elseif technologies[continuation] then
					log("razi-protocol: " .. name .. " keeps its packs: " .. continuation .. " exists")
				elseif not (technology.icons or technology.icon) then
					log("razi-protocol: " .. name .. " keeps its packs: it has no icon to put the card on")
				else
					local unlock, reachable = unlock_of(card, technologies)
					local ingredients = {card}
					for _, entry in ipairs(kept) do
						ingredients[#ingredients + 1] = ingredient_name(entry)
					end
					if not reachable then
						log("razi-protocol: " .. name .. " keeps its packs: nothing unlocks " .. card)
					elseif not lab_takes(ingredients) then
						log("razi-protocol: " .. name .. " keeps its packs: no laboratory takes " .. table.concat(ingredients, ", "))
					else
						split_research(technology, card, unlock, kept)
					end
				end
			end
		end
	end
end

return infinite_research_cards
