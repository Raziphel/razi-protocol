local vibrant_discovery_guard = {}

local function build_card_discovery_ingredients()
	local ingredients = {}
	add_existing_science_packs(ingredients, {
		"calidus-tech-card",
		"solaris-tech-card",
		"nyxaris-tech-card"
	})
	return ingredients
end

local function force_discovery_requirements(technology_name, ingredients, count, time)
	local technology = data.raw.technology and data.raw.technology[technology_name]
	if not technology then
		return
	end

	if #ingredients == 0 then
		return
	end

	technology.research_trigger = nil
	technology.unit = technology.unit or {}
	technology.unit.count = count or technology.unit.count or 3000
	technology.unit.time = time or technology.unit.time or 60
	technology.unit.ingredients = table.deepcopy(ingredients)
end

function vibrant_discovery_guard.data_final_fixes()
	local vibrant_planet_ingredients = build_card_discovery_ingredients()

	if technology_exists("planet-discovery-muria") then
		set_prerequisites_if_exists("planet-discovery-muria", {"vibrant-discovery"})
	end

	set_prerequisites_if_exists("planet-discovery-aquilo", {"vibrant-discovery"})

	if technology_exists("planet-discovery-shchierbin") then
		set_prerequisites_if_exists("planet-discovery-shchierbin", {"planet-discovery-paracelsin"})
	end

	set_prerequisites_if_exists("planet-discovery-ribbonia", {"vibrant-discovery"})
	set_prerequisites_if_exists("planet-discovery-paracelsin", {"planet-discovery-ribbonia"})
	set_prerequisites_if_exists("planet-discovery-rubia", {"planet-discovery-aquilo"})
	set_first_existing_prerequisite("planet-discovery-maraxsis", {
		"planet-discovery-rubia",
		"planet-discovery-aquilo",
		"vibrant-discovery"
	})

	for _, technology_name in ipairs({
		"planet-discovery-muria",
		"planet-discovery-shchierbin",
		"planet-discovery-ribbonia",
		"planet-discovery-paracelsin",
		"planet-discovery-aquilo",
		"planet-discovery-rubia",
		"planet-discovery-maraxsis"
	}) do
		force_discovery_requirements(technology_name, vibrant_planet_ingredients, nil, 60)
	end
end

return vibrant_discovery_guard
