-- The cactus mash recipe drops its seed result when no such item exists.
local helpers = require("prototypes.fixes.common.sanity_helpers")
local remove_result_if_missing = helpers.remove_result_if_missing

local cactus_mash_seeds = {}

function cactus_mash_seeds.data_final_fixes()
	remove_result_if_missing("planetaris-cactus-mash", "planetaris-cactus-seeds")
end

return cactus_mash_seeds
