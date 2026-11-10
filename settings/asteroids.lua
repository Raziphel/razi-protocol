data:extend({
	{
		type = "string-setting",
		name = "razi-asteroid-difficulty-scale",
		setting_type = "startup",
		default_value = "balanced",
		allowed_values = {"balanced", "challenging", "relentless"},
		order = "ad[asteroids]-02[asteroid-difficulty-scale]"
	},
	{
		type = "string-setting",
		name = "razi-asteroid-population",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"sparse", "standard", "dense", "swarm"},
		order = "ad[asteroids]-03[asteroid-population]"
	},
	{
		type = "string-setting",
		name = "razi-belt-threats",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"relaxed", "standard", "severe"},
		order = "ad[asteroids]-04[belt-threats]"
	},
	{
		type = "string-setting",
		name = "razi-belt-resource-richness",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"scarce", "standard", "rich"},
		order = "ad[asteroids]-05[belt-resource-richness]"
	},
	{
		type = "bool-setting",
		name = "razi-belt-midsection-salvage",
		setting_type = "startup",
		default_value = true,
		order = "ad[asteroids]-06[belt-midsection-salvage]"
	},
	{
		type = "bool-setting",
		name = "razi-belt-edge-harvesting",
		setting_type = "startup",
		default_value = true,
		order = "ad[asteroids]-07[belt-edge-harvesting]"
	},
	{
		type = "bool-setting",
		name = "razi-quality-asteroids",
		setting_type = "startup",
		default_value = true,
		order = "ad[asteroids]-01[quality-asteroids]"
	}
})
