local hidden_splitters = {}

-- lane-balancers 1.3.0 makes a lane splitter from each splitter it knows, the advanced and the superior splitter of
-- Krastorio 2 included (data.lua:201-212, recipe from the splitter recipe at data.lua:27-52). Krastorio2-spaced-out
-- hides the advanced splitter, its item and its technology, but the advanced lane splitter stays visible, and Ribbonia
-- unlocks it with its lane splitter technology: a recipe that needs an item no one can make. The recipe of a lane
-- splitter whose splitter is hidden is hidden too, with its unlocks, and the upgrade planner goes past it. The item and
-- the entity stay as they are: the game refuses a hidden item as the mining result of an entity in an upgrade chain.
function hidden_splitters.data_final_fixes()
	local lane_splitters = data.raw["lane-splitter"] or {}
	local removed = {}

	for name, lane_splitter in pairs(lane_splitters) do
		local recipe = data.raw.recipe and data.raw.recipe[name]
		local ingredients = recipe and recipe.ingredients or {}
		local ingredient = #ingredients == 1 and ingredients[1] or nil
		local splitter_name = ingredient and ingredient.name --[[@as string?]]
		local splitter_item = splitter_name and data.raw.item and data.raw.item[splitter_name] or nil

		if recipe and ingredient and splitter_item and splitter_item.hidden and not recipe.hidden then
			recipe.hidden = true
			recipe.enabled = false
			removed[name] = ingredient.name
			for _, other in pairs(lane_splitters) do
				if other.next_upgrade == name then
					other.next_upgrade = lane_splitter.next_upgrade
				end
			end
		end
	end

	local unlocks = {}
	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and removed[effect.recipe] then
				table.remove(effects, index)
				unlocks[effect.recipe] = (unlocks[effect.recipe] or 0) + 1
			end
		end
	end

	for name, splitter_name in pairs(removed) do
		log("razi-protocol: " .. name .. " hidden: its splitter " .. splitter_name .. " is hidden, "
			.. (unlocks[name] or 0) .. " unlocks removed")
	end
end

return hidden_splitters
