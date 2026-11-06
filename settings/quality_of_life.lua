data:extend({
	{
		type = "bool-setting",
		name = "razi-hide-redundant-assembler-tiers",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-a[redundant-assemblers]"
	},
	{
		type = "bool-setting",
		name = "razi-curated-space-routes",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-c3[curated-route-authority]"
	},
	{
		type = "bool-setting",
		name = "razi-enable-expedition-briefings",
		setting_type = "startup",
		default_value = true,
		-- The briefings are story text; the setting has no effect while the story is off.
		hidden = not require("lib.story").enabled(),
		order = "ca[quality-of-life]-b[expedition-briefings]"
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
	},
	-- Only the crafting-list visibility changes; research and factories remain
	-- intact. Prototype settings apply to all players and require a restart.
	{
		type = "string-setting",
		name = "razi-hand-crafting-cleanup",
		setting_type = "startup",
		default_value = "all",
		allowed_values = {"off", "razi", "all"},
		order = "ca[quality-of-life]-b3[hand-crafting]"
	},
	{
		type = "string-setting",
		name = "razi-route-overlay-mode",
		setting_type = "startup",
		default_value = "danger",
		allowed_values = {"off", "danger", "chapter"},
		order = "ca[quality-of-life]-c[route-overlay-mode]"
	},
	{
		type = "string-setting",
		name = "razi-route-overlay-scope",
		setting_type = "startup",
		default_value = "all",
		allowed_values = {"major", "all"},
		order = "ca[quality-of-life]-c2[route-overlay-scope]"
	},
	{
		type = "bool-setting",
		name = "razi-route-intelligence",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-d[route-intelligence]"
	},
	{
		type = "string-setting",
		name = "razi-route-visibility",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"soft", "standard", "bright"},
		order = "ca[quality-of-life]-e[route-visibility]"
	},
	{
		type = "string-setting",
		name = "razi-route-detail",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"economy", "standard", "smooth"},
		order = "ca[quality-of-life]-f[route-detail]"
	},
	{
		type = "bool-setting",
		name = "razi-route-show-danger",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-g[danger]"
	},
	{
		type = "bool-setting",
		name = "razi-route-show-sizes",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-h[sizes]"
	},
	{
		type = "bool-setting",
		name = "razi-route-show-salvage",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-i[salvage]"
	},
	{
		type = "bool-setting",
		name = "razi-route-show-advice",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-j[advice]"
	},
	{
		type = "bool-setting",
		name = "razi-route-show-unknown",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-k[unknown]"
	},
	{
		type = "bool-setting",
		name = "razi-route-show-belts",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-l[belts]"
	},
	{
		type = "bool-setting",
		name = "razi-route-show-sectors",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-m[sectors]"
	},
	{
		type = "bool-setting",
		name = "razi-route-show-haul",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-n[haul]"
	}
})
