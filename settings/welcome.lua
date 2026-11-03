data:extend({
	{
		type = "bool-setting",
		name = "razi-clean-startup-chat",
		setting_type = "runtime-per-user",
		default_value = true,
		order = "a1[welcome]-a[compact-console]"
	},
	{
		type = "bool-setting",
		name = "razi-show-welcome",
		setting_type = "runtime-per-user",
		default_value = true,
		order = "a1[welcome]-b[welcome-message]"
	},
	{
		type = "bool-setting",
		name = "razi-journal-show-button",
		setting_type = "runtime-per-user",
		default_value = true,
		order = "a1[welcome]-c[journal-shortcut]"
	},
	{
		type = "bool-setting",
		name = "razi-journal-show-tracker",
		setting_type = "runtime-per-user",
		default_value = true,
		order = "a1[welcome]-d[pinned-tracker]"
	}
})
