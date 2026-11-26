-- Nuclear Steps allows trains on a space platform only where the tile has its forbid_space_train layer.

return function(runner)
	if not script.active_mods["nuclear-steps"] then return end

	runner.test("Nuclear Steps forbids trains on every platform tile without heavy foundation", function()
		local platform_tiles = {}
		for _, item in pairs(prototypes.item) do
			local placement = item.place_as_tile_result
			if placement and placement.invert == true and placement.condition
				and placement.condition.layers and placement.condition.layers.empty_space == true then
				local tile = placement.result
				platform_tiles[tile.name] = tile
			end
		end

		local tile_count = 0
		local missing_layer = {}
		for name, tile in pairs(platform_tiles) do
			tile_count = tile_count + 1
			local collision_mask = tile.collision_mask
			if not (collision_mask and collision_mask.layers
				and collision_mask.layers.forbid_space_train == true) then
				missing_layer[#missing_layer + 1] = name
			end
		end

		runner.assert(tile_count > 1, "no space platform tiles found")
		table.sort(missing_layer)
		runner.assert(#missing_layer == 0,
			"tiles without forbid_space_train layer: " .. table.concat(missing_layer, ", "))
	end)

	if script.active_mods["Cerys-Moon-of-Fulgora"] then
		runner.test("Nuclear Steps trains and rails stay off Cerys", function()
			for _, name in ipairs({ "locomotive", "cargo-wagon", "fluid-wagon", "straight-rail", "curved-rail-a", "train-stop" }) do
				local entity = prototypes.entity[name]
				runner.assert(entity, "no prototype " .. name)
				local condition
				for _, surface_condition in pairs(entity.surface_conditions or {}) do
					if surface_condition.property == "cerys-ambient-radiation" then
						condition = surface_condition
						break
					end
				end
				runner.assert(condition and condition.max and condition.max <= 300,
					name .. " has no Cerys ambient radiation maximum of 300 or less")
			end
		end)
	end
end
