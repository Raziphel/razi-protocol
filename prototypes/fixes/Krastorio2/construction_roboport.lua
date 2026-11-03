local construction_roboport = {}

-- Krastorio 2 sets logistics_radius = 0 on the construction mode of every roboport
-- (prototypes/updates/generate-roboport-variations.lua:42), so repair robots cannot take repair packs from it. A
-- construction roboport that builds keeps a logistic radius of 1, enough for its own repair packs.
function construction_roboport.data_final_fixes()
	for name, roboport in pairs(data.raw.roboport or {}) do
		if name:find("%-construction%-mode$") and (roboport.logistics_radius or 0) == 0
			and (roboport.construction_radius or 0) > 0 then
			roboport.logistics_radius = 1
			log("razi-protocol: roboport " .. name .. " has logistics_radius = 1")
		end
	end
end

return construction_roboport
