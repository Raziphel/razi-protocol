local tenebris_void_towers = {}

-- Tenebris Prime makes a bioluminescent copy of every machine, powered by a
-- void energy source. Factorio 2.1 crashes a few seconds after such a copy
-- of an agricultural tower that animates through graphics_set.states (Moshine's
-- processing grid) is built: "double value not in range for fixed point
-- number: inf" in CraftingMachineAnimationState. The plain tower stands on
-- Tenebris anyway, so the recipes of these copies are hidden together with
-- their unlocks; the entity and the item stay for saves that already hold one.
local function crashes(tower)
	local graphics = tower.graphics_set
	return tower.bioluminescent
		and tower.energy_source and tower.energy_source.type == "void"
		and graphics and graphics.states and next(graphics.states) ~= nil
end

local function makes_any(recipe, items)
	for _, result in pairs(recipe.results or {}) do
		if result.type == "item" and items[result.name] then
			return true
		end
	end

	return false
end

function tenebris_void_towers.data_final_fixes()
	if not mods["tenebris-prime"] then
		return
	end

	local items = {}
	for name, tower in pairs(data.raw["agricultural-tower"] or {}) do
		if crashes(tower) then
			for item_name, item in pairs(data.raw.item or {}) do
				if item.place_result == name then
					items[item_name] = true
				end
			end
		end
	end
	if next(items) == nil then
		return
	end

	local hidden = {}
	for name, recipe in pairs(data.raw.recipe or {}) do
		if not recipe.hidden and makes_any(recipe, items) then
			recipe.hidden = true
			recipe.enabled = false
			hidden[name] = true
			log("[Razi Protocol/tenebris-void-towers] " .. name .. " is hidden: its tower crashes the game on a void energy source")
		end
	end

	for _, technology in pairs(data.raw.technology or {}) do
		local effects = technology.effects or {}
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and hidden[effect.recipe] then
				table.remove(effects, index)
			end
		end
	end
end

return tenebris_void_towers
