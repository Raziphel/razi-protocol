local productivity_caps = {}

-- Productivity caps on single recipes that close a loop which only productivity opens (break-even at or below
-- +100 % on one recipe; the loops that need more are left open). Each cap is set only while the recipe still has the
-- value the mod wrote.
local caps = {
	-- pelagos: 10 nutrients -> 20 spoilage in a bioassembler (+75 % base), spoilage -> nutrients with the infinite research
	{ "nutrients-spoiling", nil, 0 },
	-- linox: 150 lava + 50 crude -> 5 coal, the oil processing research pays off at +72 %
	{ "linox-recipe_rapid-distillation", nil, 0.5 },
	-- dea-dia-system: slime weed -> fiber + gel -> fiber, both with the slimeweed research (+81 % breaks even)
	{ "gel-polymerization", nil, 0 },
	{ "slime-weed-processing", nil, 2 },
	-- PlanetAthos: 1 electronic circuit + 1 silicon -> 1 advanced circuit, recycled back to 0.5 electronic circuit
	-- (and half of the rest); +100 % breaks even
	{ "advanced-circuit-from-silicon", nil, 1 },
}

function productivity_caps.data_final_fixes()
	for _, cap in ipairs(caps) do
		local recipe = data.raw.recipe[cap[1]]
		if recipe and recipe.maximum_productivity == cap[2] then
			recipe.maximum_productivity = cap[3]
			log("razi-protocol: " .. cap[1] .. " takes at most +" .. cap[3] * 100 .. " % productivity")
		end
	end

	-- Krastorio 2: 10 uranium ore (8 matter) -> 1 U-235 + 1 U-238 (the U-238 alone is 4.71 matter) with +300 % from
	-- nuclear-isotope-extraction-productivity gives 2.3 times the matter. 10 U-238 sell for 20 matter, not 47.1.
	local recipe = data.raw.recipe["kr-uranium-238-to-matter"]
	for _, product in pairs(recipe and recipe.results or {}) do
		if product.name == "kr-matter" and product.amount == 47.1 then
			product.amount = 20
			for _, key in pairs({ "ignored_by_productivity", "ignored_by_stats" }) do
				if product[key] == 47.1 then
					product[key] = 20
				end
			end
			log("razi-protocol: kr-uranium-238-to-matter gives 20 matter, not 47.1")
		end
	end
end

return productivity_caps
