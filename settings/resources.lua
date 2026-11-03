data:extend({
	{
		type = "string-setting",
		name = "razi-spoilage-pressure",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"forgiving", "normal", "fast", "brutal"},
		order = "ab[resources]-04[spoilage-pressure]"
	},
	{
		type = "string-setting",
		name = "razi-resource-frequency",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"abundant", "normal", "scarce", "desolate"},
		order = "ab[resources]-01[resource-frequency]"
	},
	{
		type = "string-setting",
		name = "razi-resource-patch-size",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"expansive", "normal", "small", "tiny"},
		order = "ab[resources]-02[resource-patch-size]"
	},
	{
		type = "string-setting",
		name = "razi-resource-richness",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"generous", "normal", "poor", "meager"},
		order = "ab[resources]-03[resource-richness]"
	},
	{
		type = "string-setting",
		name = "razi-science-demand",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"light", "normal", "intensive", "grueling"},
		order = "ab[resources]-05[science-demand]"
	},
	{
		type = "string-setting",
		name = "razi-rocket-launch-cost",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"economical", "normal", "costly", "punishing"},
		order = "ab[resources]-06[rocket-launch-cost]"
	},
	{
		type = "string-setting",
		name = "razi-factory-throughput",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"boosted", "normal", "constrained", "strained"},
		order = "ab[resources]-07[factory-throughput]"
	}
})
