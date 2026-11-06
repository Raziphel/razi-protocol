data:extend({
	{
		type = "string-setting",
		name = "razi-starmap-orbit-density",
		setting_type = "startup",
		default_value = "full",
		allowed_values = {"full", "balanced", "clean", "off"},
		order = "cb[starmap]-b0[orbit-density]"
	},
	{
		type = "bool-setting",
		name = "razi-starmap-soften-bellicos",
		setting_type = "startup",
		default_value = true,
		order = "cb[starmap]-c2[pulsar-glare]"
	},
	{
		type = "string-setting",
		name = "razi-starmap-background-style",
		setting_type = "startup",
		default_value = "subtle",
		allowed_values = {"off", "subtle", "cinematic"},
		order = "cb[starmap]-a[background]"
	},
	{
		type = "bool-setting",
		name = "razi-starmap-system-halos",
		setting_type = "startup",
		default_value = true,
		order = "cb[starmap]-b[halos]"
	},
	{
		type = "bool-setting",
		name = "razi-starmap-belt-atmosphere",
		setting_type = "startup",
		default_value = true,
		order = "cb[starmap]-c[belts]"
	},
	{
		type = "bool-setting",
		name = "razi-starmap-fine-details",
		setting_type = "startup",
		default_value = true,
		order = "cb[starmap]-d[details]"
	},
	{
		type = "bool-setting",
		name = "razi-starmap-galactic-ornaments",
		setting_type = "startup",
		default_value = true,
		order = "cb[starmap]-d2[quiet-nebula-structure]"
	},
	{
		type = "bool-setting",
		name = "razi-starmap-micro-details",
		setting_type = "startup",
		default_value = true,
		order = "cb[starmap]-d3[micro-details]"
	},
	{
		type = "bool-setting",
		name = "razi-starmap-cinematic-extras",
		setting_type = "startup",
		default_value = true,
		order = "cb[starmap]-d4[cinematic-extras]"
	},
	{
		type = "bool-setting",
		name = "razi-starmap-cartography",
		setting_type = "startup",
		default_value = false,
		order = "cb[starmap]-e[chart]"
	},
	{
		type = "string-setting",
		name = "razi-map-star-intensity",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"dim", "standard", "bright"},
		order = "cb[starmap]-f[stars]"
	},
	{
		type = "string-setting",
		name = "razi-map-halo-intensity",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"faint", "standard", "strong"},
		order = "cb[starmap]-g[halos]"
	},
	{
		type = "string-setting",
		name = "razi-map-belt-intensity",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"faint", "standard", "strong"},
		order = "cb[starmap]-h[belt]"
	},
	{
		type = "string-setting",
		name = "razi-map-dust-intensity",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"faint", "standard", "strong"},
		order = "cb[starmap]-i[dust]"
	}
})
