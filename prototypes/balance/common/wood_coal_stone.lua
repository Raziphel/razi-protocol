local wood_coal_stone = {}

-- Wood, coal, carbon and stone go round through Krastorio 2 matter (10 wood = 1 matter, a coal or a stone 0.35, a
-- carbon 0.35) and through recipes of Hyarion, moon-eneas, calciner, Arig and Pelagos that give more than they take
-- in matter, or that multiply a carbon they only give back. Each recipe below is brought to at most what it takes
-- (kr-matter-to-wood of K2 and wood-spoiling of Pelagos stay as they are in the matter table):
-- - pyrolysis-advanced (moon-eneas): 8 wood -> 4 coal, 10 crude oil, 2 carbon is 3.4 times its input in matter; it
--   takes 32 wood and no productivity;
-- - calciner-wood-carbonization (calciner) and planetaris-compression-wood-coal (Arig): 8 wood for a coal, no
--   productivity (they gave a coal for 2 and 3 wood, 0.2 matter for 0.35);
-- - planetaris-lig-carbon-wood-chemistry (Hyarion): 2 carbon -> 1 wood, not 5;
-- - planetaris-coal-to-stone-particle-manipulation (Hyarion): 3 coal -> 3 stone, not 5 (the same matter value);
-- - burnt-spoilage (base): its carbon is a catalyst of the spoilage (6 spoilage per carbon, and Pelagos makes 40
--   spoilage from 5 wood), so productivity must not multiply it;
-- - pyrolysis-basic (moon-eneas): 4 wood -> a coal, 10 wood from a matter, 2.5 coal buy 0.875 matter, and the furnace
--   bonus makes it more than the matter: no productivity;
-- - wood-spoiling (Pelagos): 5 wood -> 40 spoilage, burnt in the base recipe for 6.7 carbon (2.3 matter for the 0.5
--   of the wood, x4.7), and with the productivity of the recipe x11.8. The carbon tweak alone does not close it, so:
--   8 spoilage for the 5 wood (1.6 a wood: 0.93 of the wood comes back through carbon and matter) and no
--   productivity.
local function recipe_named(name)
	return data.raw.recipe[name]
end

local function take(name, item, from, to)
	local recipe = recipe_named(name)
	for _, ingredient in pairs(recipe and recipe.ingredients or {}) do
		if ingredient.name == item and ingredient.amount == from then
			ingredient.amount = to
			log("razi-protocol: " .. name .. " takes " .. to .. " " .. item .. ", not " .. from)
			return true
		end
	end

	return false
end

local function give(name, item, from, to)
	local recipe = recipe_named(name)
	for _, product in pairs(recipe and recipe.results or {}) do
		if product.name == item and product.amount == from then
			product.amount = to
			for _, key in pairs({ "ignored_by_productivity", "ignored_by_stats" }) do
				if product[key] == from then
					product[key] = to
				end
			end
			log("razi-protocol: " .. name .. " gives " .. to .. " " .. item .. ", not " .. from)
			return true
		end
	end

	return false
end

local function no_productivity(name)
	local recipe = recipe_named(name)
	if recipe and recipe.maximum_productivity ~= 0 then
		recipe.maximum_productivity = 0
		log("razi-protocol: " .. name .. " takes no productivity")
	end
end

function wood_coal_stone.data_final_fixes()
	if take("pyrolysis-advanced", "wood", 8, 32) then
		no_productivity("pyrolysis-advanced")
	end
	if take("calciner-wood-carbonization", "wood", 2, 8) then
		no_productivity("calciner-wood-carbonization")
	end
	if take("planetaris-compression-wood-coal", "wood", 3, 8) then
		no_productivity("planetaris-compression-wood-coal")
	end
	no_productivity("pyrolysis-basic")
	if give("wood-spoiling", "spoilage", 40, 8) then
		no_productivity("wood-spoiling")
	end
	give("planetaris-lig-carbon-wood-chemistry", "wood", 5, 1)
	give("planetaris-coal-to-stone-particle-manipulation", "stone", 5, 3)

	local spoilage = recipe_named("burnt-spoilage")
	for _, product in pairs(spoilage and spoilage.results or {}) do
		if product.name == "carbon" and product.ignored_by_productivity == nil then
			product.ignored_by_productivity = product.amount
			log("razi-protocol: burnt-spoilage keeps its carbon out of productivity")
		end
	end
end

return wood_coal_stone
