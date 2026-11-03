data:extend({
	{
		type = "string-setting",
		name = "razi-difficulty-preset",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"easy", "normal", "hard", "nightmare", "custom"},
		order = "00[gameplay-difficulty]-a[preset]"
	},
	{
		type = "bool-setting",
		name = "razi-default-new-game-map",
		setting_type = "startup",
		default_value = true,
		order = "00[gameplay-difficulty]-b[map-generator]"
	}
})
