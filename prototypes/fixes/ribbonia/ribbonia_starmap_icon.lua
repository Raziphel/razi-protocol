local ribbonia_starmap_icon = {}

function ribbonia_starmap_icon.data_final_fixes()
	local ribbonia = data.raw.planet and data.raw.planet["ribbonia"]
	if ribbonia then
		ribbonia.starmap_icon = "__ribbonia__/graphics/starmap/ribbonia2048.png"
		ribbonia.starmap_icon_size = 2048
	end

	local default_sprites = data.raw["utility-sprites"] and data.raw["utility-sprites"]["default"]
	local starmap_star = default_sprites and default_sprites["starmap_star"]
	if starmap_star and starmap_star.layers then
		for index = #starmap_star.layers, 1, -1 do
			local layer = starmap_star.layers[index]
			if layer and layer.filename == "__ribbonia__/graphics/starmap/ribbonia2048.png" then
				table.remove(starmap_star.layers, index)
			end
		end
	end
end

return ribbonia_starmap_icon
