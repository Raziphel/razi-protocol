--require("prototypes.compat.k2so_deadia")

local function clear_invalid_place_result(item_prototypes)
	for _, prototype in pairs(item_prototypes or {}) do
		local place_result = prototype.place_result
		if type(place_result) == "string" and place_result:match("^bioluminescent%-") then
			local entity_exists =
				(data.raw["assembling-machine"] and data.raw["assembling-machine"][place_result]) or
				(data.raw["furnace"] and data.raw["furnace"][place_result]) or
				(data.raw["mining-drill"] and data.raw["mining-drill"][place_result]) or
				(data.raw["inserter"] and data.raw["inserter"][place_result]) or
				(data.raw["agricultural-tower"] and data.raw["agricultural-tower"][place_result]) or
				(data.raw["roboport"] and data.raw["roboport"][place_result]) or
				(data.raw["constant-combinator"] and data.raw["constant-combinator"][place_result]) or
				(data.raw["arithmetic-combinator"] and data.raw["arithmetic-combinator"][place_result]) or
				(data.raw["decider-combinator"] and data.raw["decider-combinator"][place_result]) or
				(data.raw["selector-combinator"] and data.raw["selector-combinator"][place_result]) or
				(data.raw["rocket-silo"] and data.raw["rocket-silo"][place_result]) or
				(data.raw["locomotive"] and data.raw["locomotive"][place_result]) or
				(data.raw["cargo-wagon"] and data.raw["cargo-wagon"][place_result]) or
				(data.raw["fluid-wagon"] and data.raw["fluid-wagon"][place_result]) or
				(data.raw["transport-belt"] and data.raw["transport-belt"][place_result])

			if not entity_exists then
				prototype.place_result = nil
			end
		end
	end
end

local function entity_exists(name)
	return
		(data.raw["assembling-machine"] and data.raw["assembling-machine"][name]) or
		(data.raw["furnace"] and data.raw["furnace"][name]) or
		(data.raw["mining-drill"] and data.raw["mining-drill"][name]) or
		(data.raw["inserter"] and data.raw["inserter"][name]) or
		(data.raw["agricultural-tower"] and data.raw["agricultural-tower"][name]) or
		(data.raw["roboport"] and data.raw["roboport"][name]) or
		(data.raw["constant-combinator"] and data.raw["constant-combinator"][name]) or
		(data.raw["arithmetic-combinator"] and data.raw["arithmetic-combinator"][name]) or
		(data.raw["decider-combinator"] and data.raw["decider-combinator"][name]) or
		(data.raw["selector-combinator"] and data.raw["selector-combinator"][name]) or
		(data.raw["rocket-silo"] and data.raw["rocket-silo"][name]) or
		(data.raw["locomotive"] and data.raw["locomotive"][name]) or
		(data.raw["cargo-wagon"] and data.raw["cargo-wagon"][name]) or
		(data.raw["fluid-wagon"] and data.raw["fluid-wagon"][name]) or
		(data.raw["transport-belt"] and data.raw["transport-belt"][name])
end

local function clear_invalid_bioluminescent_next_upgrade(entity_prototypes)
	for _, prototype in pairs(entity_prototypes or {}) do
		local next_upgrade = prototype.next_upgrade
		if type(prototype.name) == "string"
			and prototype.name:match("^bioluminescent%-")
			and type(next_upgrade) == "string"
			and next_upgrade:match("^bioluminescent%-")
			and not entity_exists(next_upgrade) then
			prototype.next_upgrade = nil
		end
	end
end

clear_invalid_place_result(data.raw.item)
clear_invalid_place_result(data.raw["item-with-entity-data"])
clear_invalid_bioluminescent_next_upgrade(data.raw["assembling-machine"])
clear_invalid_bioluminescent_next_upgrade(data.raw["furnace"])
clear_invalid_bioluminescent_next_upgrade(data.raw["mining-drill"])
clear_invalid_bioluminescent_next_upgrade(data.raw["inserter"])
clear_invalid_bioluminescent_next_upgrade(data.raw["agricultural-tower"])
clear_invalid_bioluminescent_next_upgrade(data.raw["roboport"])
clear_invalid_bioluminescent_next_upgrade(data.raw["constant-combinator"])
clear_invalid_bioluminescent_next_upgrade(data.raw["arithmetic-combinator"])
clear_invalid_bioluminescent_next_upgrade(data.raw["decider-combinator"])
clear_invalid_bioluminescent_next_upgrade(data.raw["selector-combinator"])
clear_invalid_bioluminescent_next_upgrade(data.raw["rocket-silo"])
clear_invalid_bioluminescent_next_upgrade(data.raw["locomotive"])
clear_invalid_bioluminescent_next_upgrade(data.raw["cargo-wagon"])
clear_invalid_bioluminescent_next_upgrade(data.raw["fluid-wagon"])
clear_invalid_bioluminescent_next_upgrade(data.raw["transport-belt"])
