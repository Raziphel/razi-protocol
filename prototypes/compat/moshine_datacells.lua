local moshine_datacells = {}

-- Moshine grows its equation and DNA data cells in the processing grid, an
-- agricultural tower of its own. Muria fills accepted_seeds of the plain
-- agricultural tower before Moshine adds the data cells to it, and does not
-- leave them out, so the plain tower plants both on almost any planet and the
-- processing grid is not needed. Take the data cells out of every tower but
-- the processing grid.
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
end

return moshine_datacells
