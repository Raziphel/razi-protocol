-- The matter research data recipe follows the broader Krastorio matter route, not one planet.
local helpers = require("prototypes.fixes.common.progression_helpers")
local recipe = helpers.recipe

local matter_research_data_surface = {}

function matter_research_data_surface.data_final_fixes()
	local matter_data = recipe("kr-matter-research-data")
	if not matter_data then
		return
	end

	-- K2SO 1.6 moved this onto Aquilo pressure only. Razi moves Aquilo into
	-- the expanded system ladder, so the data recipe needs to follow the broader K2SO
	-- matter route instead of hard-locking one planet.
	matter_data.surface_conditions = nil
end

return matter_research_data_surface
