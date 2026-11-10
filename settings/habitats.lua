data:extend({
	{
		type = "bool-setting",
		name = "razi-enable-enemy-routing",
		setting_type = "startup",
		default_value = true,
		order = "ac[habitats]-01[enable-enemy-routing]"
	},
	{
		type = "string-setting",
		name = "razi-enemy-habitats",
		setting_type = "startup",
		default_value = "auto",
		allowed_values = {"auto", "none", "normal", "wide", "widest"},
		order = "ac[habitats]-02[enemy-habitats]"
	}
})
