local surface_conditions = {}

-- Arig keeps Aquilo's machines off its dust with planetaris-dust-concentration <= 50 on their recipes
-- (data-updates.lua: electromagnetic plant, cryogenic plant, recycler, ...). Its pressure of 600 lets in what Aquilo
-- needs, and three recipes and an explosion missed the list: quantum processors and fusion reactors and generators
-- were made on Arig, and an atomic bomb there left Aquilo's ammonia ocean crater. Open pull request #63 of
-- planetaris-arig adds them; until it is released this file does the same, with the helper's defaults
-- (PlanetarisLib.add_recipe_surface_condition: min 1, max 50) for the recipes and max 50 for the explosion.
local property = "planetaris-dust-concentration"

local function has_property(conditions)
	for _, condition in pairs(conditions or {}) do
		if condition.property == property then
			return true
		end
	end

	return false
end

function surface_conditions.data_final_fixes()
	if not (data.raw["surface-property"] and data.raw["surface-property"][property]) then
		return
	end

	for _, name in ipairs({"quantum-processor", "fusion-reactor", "fusion-generator"}) do
		local recipe = data.raw.recipe and data.raw.recipe[name]
		if recipe and not has_property(recipe.surface_conditions) then
			recipe.surface_conditions = recipe.surface_conditions or {}
			table.insert(recipe.surface_conditions, {property = property, min = 1, max = 50})
			log("razi-protocol: recipe " .. name .. " needs " .. property .. " <= 50 (planetaris-arig #63)")
		end
	end

	local nuke = data.raw.explosion and data.raw.explosion["nuke-effects-aquilo"]
	if nuke and nuke.surface_conditions and not has_property(nuke.surface_conditions) then
		table.insert(nuke.surface_conditions, {property = property, max = 50})
		log("razi-protocol: nuke-effects-aquilo needs " .. property .. " <= 50 (planetaris-arig #63)")
	end
end

return surface_conditions
