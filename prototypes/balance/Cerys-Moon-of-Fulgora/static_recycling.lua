-- With its setting cerys-enforce-vanilla-recycling-recipes (on by default), Cerys 4.25.0 writes some recycling recipes
-- by hand (compat/static-recycling.lua). For Krastorio 2 the advanced circuit returns 1 copper cable, 1 electronic
-- circuit and 0.5 electronic components (:66-72). That is a quarter of a recipe that makes one circuit, but Krastorio 2
-- makes two from 4 circuits, 4 cables and 2 components (prototypes/updates/base/recipes.lua): recycling returns half of
-- the input. In an electromagnetic plant (+50 % base productivity, five module slots) crafting and recycling then gives
-- more circuits than it uses, for ever.
--
-- The hand-written results are divided by the number of circuits the recipe makes, while they are still exactly the
-- ones Cerys writes, so 1 circuit returns 0.5 cable, 0.5 circuit and 0.25 components, a quarter of its share.
local static_recycling = {}

local CERYS_RESULTS = {
	["copper-cable"] = 1,
	["electronic-circuit"] = 1,
	["kr-electronic-components"] = 0.5,
}

local function total(product)
	return (product.amount or 0) + (product.extra_count_fraction or 0)
end

local function made(recipe, item_name)
	for _, product in pairs(recipe.results or {}) do
		if product.name == item_name then
			return total(product)
		end
	end

	return 0
end

local function is_cerys_static(results)
	local count = 0
	for _, product in pairs(results or {}) do
		if CERYS_RESULTS[product.name] ~= total(product) then
			return false
		end
		count = count + 1
	end

	return count == 3
end

function static_recycling.data_final_fixes()
	local recipes = data.raw.recipe or {}
	local recycling = recipes["advanced-circuit-recycling"]
	local recipe = recipes["advanced-circuit"]
	local per_craft = recipe and made(recipe, "advanced-circuit") or 0
	if not (recycling and per_craft > 1 and is_cerys_static(recycling.results)) then
		return
	end

	for _, product in pairs(recycling.results or {}) do
		local share = total(product) / per_craft
		product.amount = math.floor(share)
		product.extra_count_fraction = share - product.amount
		if product.extra_count_fraction == 0 then
			product.extra_count_fraction = nil
		end
	end
	log("razi-protocol: advanced-circuit-recycling divided by " .. per_craft .. " (Cerys static recycling)")
end

return static_recycling
