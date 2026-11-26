-- Muria adds this foundry unlock without checking for the recipe (Muria/compat/bzlead.lua:46);
-- bzlead declares it only when more_entities is enabled (bzlead/lead-recipe.lua:101-157).
local M = {}

function M.data_final_fixes()
	if not (mods and mods["Muria"] and mods["bzlead"]) then
		return
	end

	local raw = data and data.raw or {}
	if (raw.recipe or {})["casting-lead-expansion-bolt"] then
		return
	end

	local foundry = (raw.technology or {}).foundry
	local effects = foundry and foundry.effects
	if type(effects) ~= "table" then
		return
	end

	local changed = false
	local index = 1
	while index <= #effects do
		local effect = effects[index]
		if effect.type == "unlock-recipe" and effect.recipe == "casting-lead-expansion-bolt" then
			table.remove(effects, index)
			changed = true
		else
			index = index + 1
		end
	end

	if changed then
		log("razi-protocol: bz: foundry: dropped the unlock of missing casting-lead-expansion-bolt")
	end
end

return M
