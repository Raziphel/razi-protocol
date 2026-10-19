-- Every world of the pack, grouped by star system. Worlds of mods that are not installed are
-- skipped by the readers, so the list can name more than one pack ever contains.
local M = {}

M.systems = {
	calidus = {"muluna"},
	solaris = {"vulcanus", "castra", "arig", "hyarion", "tellus", "corrundum", "igrys"},
	nyxaris = {"gleba", "moshine", "apia-carnova-orbit", "panglia", "foliax", "rabbasca", "velora"},
	vibrant = {"fulgora", "cerys", "ribbonia", "paracelsin", "alchemy-planet"},
	vespera = {"muria", "athos", "aquilo", "nulla", "rubia", "maraxsis", "bm-balack"},
	beetlejuice = {"cubium", "linox-planet_linox", "secretas", "frozeta", "ferrum"},
	umbra = {"tenebris", "crucible", "vesta", "carna", "arcanyx", "obsidiax"},
}

-- Fixed order, as the systems are reached.
M.order = {"calidus", "solaris", "nyxaris", "vibrant", "vespera", "beetlejuice", "umbra"}

M.worlds = {}
for _, system in ipairs(M.order) do
	for _, world in ipairs(M.systems[system]) do
		M.worlds[#M.worlds + 1] = world
	end
end

return M
