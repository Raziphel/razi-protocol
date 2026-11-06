local refined_concrete = {}

-- The items planetaris-<color>-refined-concrete of planetaris-dyes place the colored tiles of the base game
-- (prototypes/item.lua:107-301 of 1.0.7), which have no minable (base prototypes/tile/tiles.lua:2693), so once placed
-- they stay. Every such item that places a tile without minable makes it minable into itself (the magenta item places
-- purple-refined-concrete, so the item is taken from place_as_tile, not from the name). Open pull request #14 of
-- planetaris-dyes does the same; it is not in 1.0.7.
function refined_concrete.data_final_fixes()
	for item_name, item in pairs(data.raw.item or {}) do
		local tile_name = item_name:find("^planetaris%-.+%-refined%-concrete$") and item.place_as_tile
			and item.place_as_tile.result
		local tile = tile_name and data.raw.tile and data.raw.tile[tile_name]

		if tile and not tile.minable then
			tile.minable = {mining_time = 0.1, result = item_name}
			log("razi-protocol: tile " .. tile_name .. " is mined into " .. item_name)
		end
	end
end

return refined_concrete
