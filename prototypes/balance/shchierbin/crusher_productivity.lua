local crusher_productivity = {}

-- The vanadium crusher of Shchierbin has +40 % base productivity and takes the crushing category
-- (prototypes/entity/crusher.lua:46-52), where the vanilla asteroid reprocessing recipes are: 1 chunk returns 0.8 on
-- average, times 1.4 is 1.12, so chunks, legendary ones too, multiply for ever. The base effect of a machine applies
-- even to a recipe with allow_productivity = false (bonus_progress 0.8 after two crafts), but not past
-- maximum_productivity. Every crushing recipe that does not allow productivity gets maximum_productivity = 0: the
-- loop is closed and the crusher keeps its bonus for asteroid crushing.
function crusher_productivity.data_final_fixes()
	local capped = 0
	for _, recipe in pairs(data.raw.recipe) do
		for _, category in pairs(recipe.categories or {}) do
			if category == "crushing" and recipe.allow_productivity ~= true and recipe.maximum_productivity ~= 0 then
				recipe.maximum_productivity = 0
				capped = capped + 1
			end
		end
	end
	log("razi-protocol: crushing recipes without productivity capped at maximum_productivity = 0: " .. capped)
end

return crusher_productivity
