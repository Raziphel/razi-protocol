local upgrade_chain = {}

-- xy-k2so-enhancements-nulls-fork puts the hyper tier of Arig between turbo and the superior belts of Krastorio 2
-- (updates/planetaris.lua:4-23) but leaves next_upgrade as it was: the upgrade planner takes the advanced loader
-- straight to superior past the hyper loader, and hyper belts, undergrounds and splitters upgrade to nothing. The
-- chain goes turbo -> hyper -> superior, where both ends exist and share a fast replace group.
local links = {
	{"loader-1x1", "kr-advanced-loader", "kr-hyper-loader"},
	{"transport-belt", "planetaris-hyper-transport-belt", "kr-superior-transport-belt"},
	{"underground-belt", "planetaris-hyper-underground-belt", "kr-superior-underground-belt"},
	{"splitter", "planetaris-hyper-splitter", "kr-superior-splitter"},
}

function upgrade_chain.data_final_fixes()
	for _, link in ipairs(links) do
		local prototypes = data.raw[link[1]] or {}
		local from, to = prototypes[link[2]], prototypes[link[3]]

		if from and to and from.next_upgrade ~= link[3] and from.fast_replaceable_group == to.fast_replaceable_group then
			from.next_upgrade = link[3]
			log("razi-protocol: " .. link[2] .. " upgrades to " .. link[3])
		end
	end
end

return upgrade_chain
