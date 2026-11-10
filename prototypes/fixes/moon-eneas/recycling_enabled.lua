local recycling_enabled = {}

-- moon-eneas 1.0.10 enables every "recycling" recipe from the start, for its early steam recycler, and switches only
-- scrap-recycling back off (prototypes/patches/tech.lua:28-32 and :35-38). Recycling recipes that can also be
-- hand-crafted and that a technology unlocks are the same kind as scrap-recycling: the nuclear scrap of Cerys, the
-- destabilized cube matter of Cubium, the spaceship scrap of Frozeta, the scrap of Nulla and of Balack, all disabled
-- until their technology. Left enabled, they sit in the hand-crafting menu from the start; they stay behind their
-- technologies.
function recycling_enabled.data_final_fixes()
	local unlocked = {}
	for _, technology in pairs(data.raw.technology or {}) do
		for _, effect in pairs(technology.effects or {}) do
			if effect.type == "unlock-recipe" then
				unlocked[effect.recipe] = true
			end
		end
	end

	for name, recipe in pairs(data.raw.recipe or {}) do
		local recycling, hand_crafting = false, false
		for _, category in pairs(recipe.categories or {}) do
			recycling = recycling or category == "recycling"
			hand_crafting = hand_crafting or category == "hand-crafting"
		end

		if recycling and hand_crafting and unlocked[name] and recipe.enabled ~= false then
			recipe.enabled = false
			log("razi-protocol: " .. name .. " is disabled until a technology unlocks it")
		end
	end
end

return recycling_enabled
