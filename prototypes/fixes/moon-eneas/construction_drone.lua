local construction_drone = {}

local item_name = "Construction_Drone"

-- moon-eneas 1.0.10 adds one Construction_Drone to every supply delivery once friend-tech is researched
-- (prototypes/scripts/events.lua:98-101) and inserts it into the lift (events.lua:825) without checking that the item
-- exists. Only Construction_Drones_Forked makes it; Eneas checks that mod for its debris loot (events.lua:34-40) but
-- not here, so without it every delivery after friend-tech stops the game with "Unknown item name:
-- Construction_Drone". A hidden item of that name, made only when no mod makes one, lets the delivery through, also
-- in saves where friend-tech is already researched. The lift is emptied at the start of every delivery
-- (events.lua:812), so the item does not pile up there.
function construction_drone.data_final_fixes()
	if not (mods["moon-eneas"] and data.raw.technology and data.raw.technology["friend-tech"]) then
		return
	end
	for item_type in pairs(defines.prototypes.item) do
		if data.raw[item_type] and data.raw[item_type][item_name] then
			return
		end
	end

	data:extend({{
		type = "item",
		name = item_name,
		localised_name = {"item-name.razi-eneas-construction-drone"},
		localised_description = {"item-description.razi-eneas-construction-drone"},
		icon = "__base__/graphics/icons/construction-robot.png",
		icon_size = 64,
		stack_size = 1,
		hidden = true,
		hidden_in_factoriopedia = true,
		subgroup = "other",
	}})
	log("razi-protocol: " .. item_name .. " is added as a hidden item, Eneas delivers it after friend-tech and"
		.. " Construction_Drones_Forked is not loaded")
end

return construction_drone
