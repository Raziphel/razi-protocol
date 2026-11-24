-- castra-prime 0.9.5 moves every recipe that makes ammo, a thrown capsule or military science into a copy of its category,
-- "castra-<category>" (prototypes/recipe-updates.lua:25-45, from data-updates.lua), and gives the copy to every
-- assembling-machine that has the original category (:132-143) and to its forge (:145-153). Furnaces are left out, so a
-- recipe of a furnace-only category moves to the forge alone. Foliax' Nature's Bounty recipes (scrap-recycling-basic,
-- -advanced and -final, prototypes/bounty.lua:130-160) have such a result and run in the Arcane Infuser, a furnace with
-- "foliax-recycling" (prototypes/entity.lua:1361): the infuser rejects the bounty and only the forge can process it.
-- The furnaces with "foliax-recycling" get its copy here, as Castra does for assembling machines. Only this category: a
-- furnace takes any recipe of its categories that matches its input, and the copy of "hand-crafting", which the steam
-- recycler of Lignumis has, holds Carna's equipment recipes.
local furnace_categories = {}

local PREFIX = "castra-"
local CATEGORIES = {"foliax-recycling"}

local function contains(list, value)
	for _, item in pairs(list) do
		if item == value then
			return true
		end
	end
	return false
end

function furnace_categories.data_final_fixes()
	local categories = data.raw["recipe-category"]
	if not (mods and mods["castra-prime"] and categories) then
		return
	end

	for name, furnace in pairs(data.raw.furnace or {}) do
		local own = furnace.crafting_categories or {}
		local original = {}
		for _, category in ipairs(own) do
			original[#original + 1] = category
		end
		for _, category in ipairs(original) do
			local copy = PREFIX .. category
			if contains(CATEGORIES, category) and categories[copy] and not contains(own, copy) then
				own[#own + 1] = copy
				log("razi-protocol: furnace " .. name .. " crafts " .. copy
					.. ", where Castra Prime moved the recipes of " .. category)
			end
		end
	end
end

return furnace_categories
