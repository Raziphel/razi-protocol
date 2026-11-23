local void_container = {}

-- Voidcraft's safe disposal empties a full void-pure container in a centrifuge and gives the empty one back, and the
-- void-pure recipe fills it again (99 %, 1 % ruptures). The fill has a chance, so balance/common/container_pairs.lua
-- does not see a pair, and a centrifuge with a base productivity bonus (Nuclear Steps' centrifuge mk2, +50 %) returns
-- 1.5 empty containers for one: x1.49 containers out of nothing. The empty container is kept out of productivity.
function void_container.data_final_fixes()
	local recipe = data.raw.recipe["s6x-void-safe-disposal"]

	for _, product in pairs(recipe and recipe.results or {}) do
		if product.name == "void-pure-container" and product.amount == 1 and product.ignored_by_productivity == nil then
			product.ignored_by_productivity = 1
			log("razi-protocol: s6x-void-safe-disposal keeps its empty container out of productivity")
		end
	end
end

return void_container
