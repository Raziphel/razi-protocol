local thrower_ranges = {}

-- RenaiTransportation reads the range of a thrower from the mod-data "RTRealRange<inserter name>"
-- (script/ThrowItemFunctions.lua:1198, RealMaxRange) and makes that entry only for its own RTThrower-* inserters
-- (data-final-fixes.lua:565-581). Other mods copy every inserter after that: panglia_planet as <name>_panglia_fast_version
-- (data-final-fixes.lua:19-22 of 0.8.2), tenebris-prime as bioluminescent-<name> (prototypes/bioluminescent.lua:90 of
-- 1.3.22) and planet-rabbasca as harene-infused-<name> (api.lua:175, scripts/create-ears-variants.lua:50: the ejector
-- hatch and the primer thrower exist when it runs, the generated throwers do not). A copy of a thrower has no mod-data,
-- and building one stops the game with "attempt to index field '?' (a nil value)".
-- Every thrower copy gets the entry of the thrower it was made from.
local function base_name(name)
	local stripped = name
	repeat
		name = stripped
		stripped = stripped:gsub("^bioluminescent%-", ""):gsub("^harene%-infused%-", ""):gsub("_panglia_fast_version$", "")
	until stripped == name

	return name
end

function thrower_ranges.data_final_fixes()
	local ranges = data.raw["mod-data"] or {}
	local copied = 0

	for name in pairs(data.raw.inserter or {}) do
		local range_name = "RTRealRange" .. name
		if name:find("RTThrower-", 1, true) and not ranges[range_name] then
			local base = ranges["RTRealRange" .. base_name(name)]
			if base then
				data:extend({{type = "mod-data", name = range_name, data = table.deepcopy(base.data)}})
				log("razi-protocol: " .. name .. " takes the thrower range of " .. base_name(name))
				copied = copied + 1
			else
				log("razi-protocol: " .. name .. " has no thrower range to copy")
			end
		end
	end

	if copied > 0 then
		log("razi-protocol: thrower ranges copied for " .. copied .. " thrower copies")
	end
end

return thrower_ranges
