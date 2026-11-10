-- Names of the research that goes on after the first levels of an infinite research on system cards
-- (prototypes/balance/common/infinite_research_cards.lua). The data stage makes them, the migration of a 2.x save looks them up.
local infinite_research_names = {}

-- Levels a research keeps on the packs, counted from its first.
infinite_research_names.span = 5

-- "foo-3" is the research "foo" from level 3 on, a name without a number starts at level 1.
function infinite_research_names.split(name)
	local base, level = name:match("^(.-)%-(%d+)$")
	if base and base ~= "" then
		return base, tonumber(level)
	end
	return name, 1
end

-- The name of the research that goes on after the five levels of `name`, which the save keeps from then on.
function infinite_research_names.continuation(name)
	local base, level = infinite_research_names.split(name)
	return "razi-cards-" .. base .. "-" .. level + infinite_research_names.span
end

return infinite_research_names
