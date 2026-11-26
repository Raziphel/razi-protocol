local M = {}

-- Nuclear Steps 0.4.1 lets rails and trains onto space platforms only on its heavy foundation: it clears their surface
-- conditions and adds a tile_buildability_rules check for forbid_space_train (data-updates/rail-network-in-space.lua:29-61),
-- and gives that layer to space-platform-foundation only (:22-27). Platform tiles from other mods (Muluna, Rabbasca) get
-- the layer here too. Clearing the conditions also drops gravity >= 1, which kept trains off Cerys; Cerys relaxes gravity
-- for cars, tanks and spidertrons but not trains (prototypes/override-final/entity.lua:35-46), so trains get their own
-- cerys-ambient-radiation <= 300 condition (common.lua:11), which is 10 everywhere but Cerys. The ±0.4 area of the rule
-- is left as Nuclear Steps wrote it.
local item_types = {
	"item",
	"tool",
	"capsule",
	"module",
	"ammo",
	"item-with-entity-data",
	"rail-planner",
	"repair-tool",
}

local entity_types = {
	"locomotive",
	"cargo-wagon",
	"fluid-wagon",
	"artillery-wagon",
	"train-stop",
	"rail-signal",
	"rail-chain-signal",
	"straight-rail",
	"half-diagonal-rail",
	"curved-rail-a",
	"curved-rail-b",
	"legacy-straight-rail",
	"legacy-curved-rail",
}

local function note(message)
	if log then
		log("razi-protocol: nuclear-steps: " .. message)
	end
end

local function has_surface_condition(conditions, property)
	for _, condition in pairs(conditions or {}) do
		if condition.property == property then
			return true
		end
	end

	return false
end

local function has_forbid_space_train_rule(rules)
	for _, rule in pairs(rules or {}) do
		local layers = rule.colliding_tiles and rule.colliding_tiles.layers
		if layers and layers.forbid_space_train == true then
			return true
		end
	end

	return false
end

local function add_foundation_layer()
	local processed_tiles = {}

	for _, item_type in ipairs(item_types) do
		for _, item in pairs(data.raw[item_type] or {}) do
			local placement = item.place_as_tile
			local condition = placement and placement.condition
			if placement and placement.invert == true and condition and condition.layers
				and condition.layers.empty_space == true then
				local tile_name = placement.result
				if tile_name and not processed_tiles[tile_name] then
					processed_tiles[tile_name] = true
					local tile = data.raw.tile and data.raw.tile[tile_name]
					if tile then
						if tile.collision_mask == nil then
							note("tile " .. tile_name .. " has the default collision mask, left as is")
						elseif tile.collision_mask.layers and tile.collision_mask.layers.forbid_space_train ~= true then
							tile.collision_mask.layers.forbid_space_train = true
							note("tile " .. tile_name .. " forbids trains without heavy foundation")
						end
					end
				end
			end
		end
	end
end

local function keep_trains_off_cerys()
	if not (data.raw["surface-property"] and data.raw["surface-property"]["cerys-ambient-radiation"]) then
		return
	end

	for _, entity_type in ipairs(entity_types) do
		local changed = 0
		for _, entity in pairs(data.raw[entity_type] or {}) do
			if has_forbid_space_train_rule(entity.tile_buildability_rules)
				and not has_surface_condition(entity.surface_conditions, "gravity")
				and not has_surface_condition(entity.surface_conditions, "cerys-ambient-radiation") then
				entity.surface_conditions = entity.surface_conditions or {}
				entity.surface_conditions[#entity.surface_conditions + 1] = {
					property = "cerys-ambient-radiation",
					max = 300,
				}
				changed = changed + 1
			end
		end

		if changed > 0 then
			note(entity_type .. ": off Cerys for " .. changed .. " prototypes")
		end
	end
end

function M.data_final_fixes()
	if not (mods and mods["nuclear-steps"] and data.raw["collision-layer"]
		and data.raw["collision-layer"].forbid_space_train) then
		return
	end

	add_foundation_layer()
	keep_trains_off_cerys()
end

return M
