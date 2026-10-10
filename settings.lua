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
	}
})
