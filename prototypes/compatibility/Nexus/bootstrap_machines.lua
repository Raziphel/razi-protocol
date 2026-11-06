-- The first machines of Nexus can be built before travelling there.
local helpers = require("prototypes.fixes.common.progression_helpers")
local recipe = helpers.recipe

local bootstrap_machines = {}

function bootstrap_machines.data_final_fixes()
	-- Nexus-Updated is the 2.1 fork of Nexus with the same prototype names.
	if not (mods["Nexus"] or mods["Nexus-Updated"]) then
		return
	end

	-- These are the machines unlocked by Nexus' first production technology.
	-- Their recipes only consume materials from earlier planets, so forcing the
	-- machines themselves to be assembled on Nexus creates an avoidable landing
	-- bootstrap: players cannot prepare the production line before travelling.
	-- Keep every recipe that actually processes Nexus materials planet-bound.
	for _, recipe_name in ipairs({
		"atomacer",
		"atomar-separator",
		"photon-enrichment-chamber"
	}) do
		local bootstrap_recipe = recipe(recipe_name)
		if bootstrap_recipe then
			bootstrap_recipe.surface_conditions = nil
		end
	end
end

return bootstrap_machines
