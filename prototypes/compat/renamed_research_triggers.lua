local renamed_research_triggers = {}

-- Krastorio2-spaced-out renames oxygen, hydrogen, chlorine, sand, glass,
-- silicon, lithium and ammonia to their kr- versions in every recipe
-- (prototypes/final-fixes/enforce-k2-items.lua), but not in research triggers.
-- A trigger that still waits for the old name can never complete. On Vesta,
-- s1_ammonia_chilled_plate waits for 16000 crafted ammonia while
-- ske_ammonia_vesta makes kr-ammonia, which blocks s1_electrolysis,
-- ske_heating_conductor and everything after them. K2SO pull request #144
-- renames the triggers too; until it is released, do the same here.
--
-- moon-eneas researches upgrade-uranium-ammo by crafting
-- uranium-rounds-magazine, which Krastorio 2 replaces by
-- kr-uranium-rifle-magazine. The trigger takes the K2 magazine, as K2SO does
-- for the rifle ammo of the base game.
local renamed = {}
for _, name in ipairs({"oxygen", "hydrogen", "chlorine", "sand", "glass", "silicon", "lithium", "ammonia"}) do
	renamed[name] = "kr-" .. name
end
renamed["uranium-rounds-magazine"] = "kr-uranium-rifle-magazine"

local function made_by_a_recipe()
	local made = {}
	for _, recipe in pairs(data.raw.recipe or {}) do
		for _, product in pairs(recipe.results or {}) do
			if product.name then
				made[product.name] = true
			end
		end
	end

	return made
end

function renamed_research_triggers.data_final_fixes()
	if not mods["Krastorio2-spaced-out"] then
		return
	end

	local made = made_by_a_recipe()

	for _, technology in pairs(data.raw.technology or {}) do
		local trigger = technology.research_trigger
		if trigger then
			for _, key in ipairs({"item", "fluid"}) do
				local target = trigger[key]
				if type(target) == "string" and renamed[target] and not made[target] and made[renamed[target]] then
					trigger[key] = renamed[target]
				end
			end
		end
	end
end

return renamed_research_triggers
