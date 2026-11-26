local M = {}

function M.data_final_fixes()
	if not mods or not mods["Rocket-Silo-Construction"] then
		return
	end

	local raw = data and data.raw
	local recipes = raw and raw.recipe
	local technologies = raw and raw.technology
	local excavation_site = recipes and recipes["rsc-excavation-site"]
	local rocket_silo = recipes and recipes["rocket-silo"]
	local space_platform = technologies and technologies["space-platform"]
	if not excavation_site or not rocket_silo or not space_platform then
		return
	end

	-- Rocket-Silo-Construction/data-final-fixes.lua:17-24 moves the silo unlock and hides its recipe. Space platform is
	-- researched only after the first launch, so it unlocks the regular recipe after the staged first silo.
	if rocket_silo.hidden == true then
		rocket_silo.hidden = false
		log("razi-protocol: Rocket-Silo Construction: made the regular rocket-silo recipe visible")
	end

	local has_unlock = false
	for _, effect in pairs(space_platform.effects or {}) do
		if effect.type == "unlock-recipe" and effect.recipe == "rocket-silo" then
			has_unlock = true
			break
		end
	end

	if not has_unlock then
		space_platform.effects = space_platform.effects or {}
		space_platform.effects[#space_platform.effects + 1] = { type = "unlock-recipe", recipe = "rocket-silo" }
		log("razi-protocol: Rocket-Silo Construction: unlocked rocket-silo with space-platform")
	end
end

return M
