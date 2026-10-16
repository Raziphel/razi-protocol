local moshine_datacells = {}

-- Moshine grows its equation and DNA data cells in the processing grid, an
-- agricultural tower of its own. Muria fills accepted_seeds of the plain
-- agricultural tower before Moshine adds the data cells to it, and does not
-- leave them out, so the plain tower plants both on almost any planet and the
-- processing grid is not needed. Take the data cells out of every tower but
-- the processing grid. A tower without accepted_seeds takes every item with a
-- plant_result, the data cells included, so it gets an explicit list of all
-- those items but the cells.
local datacells = {
	["datacell-equation"] = true,
	["datacell-dna-raw"] = true
}

function moshine_datacells.data_final_fixes()
	if not mods["Moshine"] then
		return
	end

	for name, tower in pairs(data.raw["agricultural-tower"] or {}) do
		local seeds = tower.accepted_seeds
		if name ~= "processing-grid" and seeds then
			for index = #seeds, 1, -1 do
				if datacells[seeds[index]] then
					table.remove(seeds, index)
				end
			end
		end
	end

	-- Every item with a plant_result, the data cells left out
	local plantable = {}
	for _, prototypes in pairs(data.raw) do
		for item_name, item in pairs(prototypes) do
			if type(item) == "table" and item.stack_size and item.plant_result and not datacells[item_name] then
				plantable[#plantable + 1] = item_name
			end
		end
	end
	table.sort(plantable)

	for name, tower in pairs(data.raw["agricultural-tower"] or {}) do
		if name ~= "processing-grid" and tower.accepted_seeds == nil then
			tower.accepted_seeds = table.deepcopy(plantable)
			log("[Razi Protocol/moshine-datacells] " .. name .. " takes " .. #plantable .. " listed seeds, the data cells not among them")
		end
	end
end

return moshine_datacells
