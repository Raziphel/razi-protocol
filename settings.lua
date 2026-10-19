data:extend({
	{
		type = "bool-setting",
		name = "razi-enable-enemy-routing",
		setting_type = "startup",
		default_value = true,
		order = "a[compat]-a[enemy-routing]"
	},
	{
		type = "bool-setting",
		name = "razi-hide-redundant-assembler-tiers",
		setting_type = "startup",
		default_value = true,
		order = "a[compat]-b[redundant-assemblers]"
	},
	{
		type = "string-setting",
		name = "razi-starmap-orbit-density",
		setting_type = "startup",
		default_value = "full",
		allowed_values = {"full", "balanced", "clean", "off"},
		order = "cb[starmap]-a2[orbit-density]"
	},
	{
		type = "bool-setting",
		name = "razi-group-barreling-recipes",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-b1[barreling-recipes]"
	},
	{
		type = "bool-setting",
		name = "razi-group-spoilable-recipes",
		setting_type = "startup",
		default_value = false,
		order = "ca[quality-of-life]-b2[spoilable-recipes]"
	}
})
