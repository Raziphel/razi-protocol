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
	{ level = "strict", run = require("prototypes.balance.panglia_planet.panglite_recycling").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.plasma_crafter.fluoroketone_catalyst").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.common.catalysts").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.common.container_pairs").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.shchierbin.crusher_productivity").data_final_fixes },
	{ level = "strict", run = require("prototypes.balance.Krastorio2-spaced-out.loops").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.Krastorio2-spaced-out.loops").decorations_data_final_fixes },
	{ level = "strict", run = require("prototypes.balance.Krastorio2.crush_productivity").data_final_fixes },
	{ level = "strict", run = require("prototypes.balance.planetaris-hyarion.particle_manipulation").data_final_fixes },
	{ level = "strict", run = require("prototypes.balance.corrundum.recrystallization").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.skewer_planet_vesta.h2o_water").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.planet-crucible.hydrogen").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.nulls-k2so-tweaks.matter_to_bones").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.common.wood_coal_stone").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.planetaris-hyarion.quartz_and_calcite").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.corrundum.sulfuric_acid").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.corrundum.dry_ice").data_final_fixes },
	{ level = "closed", run = require("prototypes.balance.Krastorio2.recycling_returns").data_final_fixes },
	{ level = "strict", run = require("prototypes.balance.common.productivity_caps").data_final_fixes },
	{ level = "strict", run = require("prototypes.balance.cubium.latent_recovery_quality").data_final_fixes },
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
