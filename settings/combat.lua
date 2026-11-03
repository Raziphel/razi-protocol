data:extend({
	{
		type = "string-setting",
		name = "razi-pollution-pressure",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"gentle", "normal", "heavy", "toxic"},
		order = "aa[combat]-04[pollution-pressure]"
	},
	{
		type = "string-setting",
		name = "razi-raid-coordination",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"small", "normal", "organized", "siege"},
		order = "aa[combat]-05[raid-coordination]"
	},
	{
		type = "string-setting",
		name = "razi-colony-expansion",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"slow", "normal", "rapid", "invasive"},
		order = "aa[combat]-06[colony-expansion]"
	},
	{
		type = "string-setting",
		name = "razi-evolution-speed",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"slow", "normal", "accelerated", "runaway"},
		order = "aa[combat]-07[evolution-speed]"
	},
	{
		type = "string-setting",
		name = "razi-fortification-durability",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"reinforced", "normal", "fragile", "brittle"},
		order = "aa[combat]-08[fortification-durability]"
	}
})
