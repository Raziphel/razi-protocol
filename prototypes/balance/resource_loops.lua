local resource_loops = {}

-- Recipe loops that make something out of nothing: the amounts, the productivity and the quality that source mods left
-- open. razi-resource-loops decides how many of them are closed:
--   open    none: the loops are as the mods wrote them;
--   closed  the loops that already run on the base productivity of a machine, and the recycling that returns more
--           than a quarter of the recipe it undoes;
--   strict  closed, and the loops that only productivity or quality modules open.
-- Each entry runs from the level named in it up. The order is the order of application: a later fix sees the result
-- of an earlier one (catalysts and container_pairs read the recipes the fixes before them left).
local presets = require("lib.difficulty.presets")

local ranks = { open = 0, closed = 1, strict = 2 }

local entries = {
	{ level = "closed", run = require("prototypes.balance.plasma_crafter.fluoroketone_catalyst").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.common.catalysts").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.common.container_pairs").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.shchierbin.crusher_productivity").data_final_fixes },
}

function resource_loops.level()
	local level = presets.effective("razi-resource-loops", "closed")
	return ranks[level] and level or "closed"
end

function resource_loops.data_final_fixes()
	local rank = ranks[resource_loops.level()]
	for _, entry in ipairs(entries) do
		if rank >= ranks[entry.level] then
			entry.run()
		end
	end
end

return resource_loops
