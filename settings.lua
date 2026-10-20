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
		type = "bool-setting",
		name = "razi-curated-space-routes",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-c3[curated-route-authority]"
	},
	{
		type = "bool-setting",
		name = "razi-route-distance-repair",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-z[distance-repair]"
	},
	{
		type = "string-setting",
		name = "razi-asteroid-population",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"sparse", "standard", "dense", "swarm"},
		order = "aa[worlds]-d[asteroid-population]"
	},
	{
		type = "string-setting",
		name = "razi-belt-threats",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"relaxed", "standard", "severe"},
		order = "aa[worlds]-e[belt-threats]"
	},
	{
		type = "string-setting",
		name = "razi-belt-resource-richness",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"scarce", "standard", "rich"},
		order = "aa[worlds]-f[belt-ore-richness]"
	},
	{
		type = "bool-setting",
		name = "razi-belt-midsection-salvage",
		setting_type = "startup",
		default_value = true,
		order = "aa[worlds]-g[belt-midsection-salvage]"
	},
	{
		type = "bool-setting",
		name = "razi-belt-edge-harvesting",
		setting_type = "startup",
		default_value = true,
		order = "aa[worlds]-h[belt-edge-harvesting]"
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
		name = "razi-enable-expedition-briefings",
		setting_type = "startup",
		default_value = true,
		order = "ca[quality-of-life]-b[expedition-briefings]"
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
		name = "razi-planetary-interdependence",
		setting_type = "startup",
		default_value = "balanced",
		allowed_values = {"off", "balanced"},
		order = "ba[integration]-0[interdependence]"
	},
	{
		type = "bool-setting",
		name = "razi-stage-aquilo-breakthroughs",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-c2[aquilo-breakthroughs]"
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
	{
		type = "bool-setting",
		name = "razi-performance-compact-route-overlays",
		setting_type = "startup",
		default_value = false,
		order = "ad[asteroid-performance]-f[route-art-budget]"
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
	},
	{
		type = "bool-setting",
		name = "razi-quality-asteroids",
		setting_type = "startup",
		default_value = true,
		order = "aa[worlds]-b[quality-asteroids]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-asteroid-particles",
		setting_type = "startup",
		default_value = false,
		order = "ad[asteroid-performance]-a[debris-effects]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-weapon-particles",
		setting_type = "startup",
		default_value = false,
		order = "ad[asteroid-performance]-b[weapon-effects]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-reduced-fragments",
		setting_type = "startup",
		default_value = false,
		order = "ad[asteroid-performance]-c[fragment-count]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-outer-hostile-density",
		setting_type = "startup",
		default_value = false,
		order = "ad[asteroid-performance]-d[outer-hostiles]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-space-explosion-smoke",
		setting_type = "startup",
		default_value = false,
		order = "ad[asteroid-performance]-e[explosion-smoke]"
	}
})
