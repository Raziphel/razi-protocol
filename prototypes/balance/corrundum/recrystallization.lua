local recrystallization = {}

-- Corrundum dissolves iron and copper into sulfate solution (recrystallization: 5 plates, 16 gears, cables or sticks and
-- 200 sulfuric acid -> 200 solution) and reduces the solution to ore (force reduction: 300 solution -> 7 iron or 3
-- copper ore, with productivity). Plates -> solution -> ore -> plates gives more than it takes: the foundry alone adds
-- 50 %, and other mods have recipes that turn one ore into two to four plates (Linox sintering, Vesta hydrogen
-- combustion), so no smaller amount of ore closes the loop and keeps the recipe useful. The author of Corrundum accepts
-- the loop (issues #17, #60); closing it is the decision of razi, not a mistake of that mod. The recrystallization
-- recipes go, the solution comes from chalcopyrite only, as on Corrundum itself, and force reduction takes no
-- productivity. A technology left with no effects is hidden when no other technology requires it.
local names = {
	"iron-recrystalization", "iron-recrystalization-alt", "iron-stick-recrystalization",
	"copper-recrystalization", "copper-recrystalization-alt",
}

function recrystallization.data_final_fixes()
	local removed = {}
	for _, name in ipairs(names) do
		local recipe = data.raw.recipe[name]
		if recipe then
			if recipe.hidden ~= true or recipe.enabled ~= false then
				log("razi-protocol: " .. name .. " removed")
			end
			recipe.hidden = true
			recipe.enabled = false
			removed[name] = true
		end
	end

	local emptied = {}
	for technology_name, technology in pairs(data.raw.technology) do
		local effects = technology.effects or {}
		local had = #effects
		for index = #effects, 1, -1 do
			local effect = effects[index]
			if effect and effect.type == "unlock-recipe" and removed[effect.recipe] then
				table.remove(effects, index)
			end
		end
		if had > 0 and #effects == 0 then
			emptied[technology_name] = true
		end
	end

	for _, technology in pairs(data.raw.technology) do
		for _, prerequisite in pairs(technology.prerequisites or {}) do
			emptied[prerequisite] = nil
		end
	end

	local hidden = {}
	for technology_name in pairs(emptied) do
		hidden[#hidden + 1] = technology_name
	end
	table.sort(hidden)
	for _, technology_name in ipairs(hidden) do
		data.raw.technology[technology_name].hidden = true
		log("razi-protocol: technology " .. technology_name .. " hidden: nothing left to unlock")
	end

	for _, name in ipairs({ "force-reduction-iron", "force-reduction-copper" }) do
		local recipe = data.raw.recipe[name]
		if recipe and recipe.allow_productivity ~= false then
			recipe.allow_productivity = false
			log("razi-protocol: " .. name .. " takes no productivity")
		end
	end
end

return recrystallization
