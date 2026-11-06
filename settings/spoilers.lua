data:extend({
	-- Research visibility is shared by the whole map and changes immediately.
	{
		type = "bool-setting",
		name = "razi-hide-spoilers",
		setting_type = "runtime-global",
		default_value = false,
		order = "a0[quality-of-life]-a[hide-spoilers]"
	},
	{
		type = "bool-setting",
		name = "razi-hide-other-tech-spoilers",
		setting_type = "runtime-global",
		default_value = false,
		order = "a0[quality-of-life]-b[other-mod-technologies]"
	}
})
