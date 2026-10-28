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
	},
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
		name = "razi-route-distance-repair",
		setting_type = "startup",
		default_value = true,
		order = "ba[integration]-z[distance-repair]"
	},
	{
		type = "string-setting",
		name = "razi-asteroid-difficulty-scale",
		setting_type = "startup",
		default_value = "balanced",
		allowed_values = {"balanced", "challenging", "relentless"},
		order = "ad[asteroids]-02[asteroid-difficulty-scale]"
	},
	{
		type = "string-setting",
		name = "razi-asteroid-population",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"sparse", "standard", "dense", "swarm"},
		order = "ad[asteroids]-03[asteroid-population]"
	},
	{
		type = "string-setting",
		name = "razi-belt-threats",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"relaxed", "standard", "severe"},
		order = "ad[asteroids]-04[belt-threats]"
	},
	{
		type = "string-setting",
		name = "razi-belt-resource-richness",
		setting_type = "startup",
		default_value = "standard",
		allowed_values = {"scarce", "standard", "rich"},
		order = "ad[asteroids]-05[belt-resource-richness]"
	},
	{
		type = "bool-setting",
		name = "razi-belt-midsection-salvage",
		setting_type = "startup",
		default_value = true,
		order = "ad[asteroids]-06[belt-midsection-salvage]"
	},
	{
		type = "bool-setting",
		name = "razi-belt-edge-harvesting",
		setting_type = "startup",
		default_value = true,
		order = "ad[asteroids]-07[belt-edge-harvesting]"
	},
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
		name = "razi-enable-expedition-briefings",
		setting_type = "startup",
		default_value = true,
		-- The briefings are story text; the setting has no effect while the story is off.
		hidden = not require("scripts.razi_story").enabled(),
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
		allowed_values = {"off", "balanced", "deep"},
		order = "ba[integration]-0[interdependence]"
	},
	{
		type = "bool-setting",
		name = "razi-distributed-technology",
		setting_type = "startup",
		default_value = false,
		order = "ba[integration]-c[planetary-tech-distribution]"
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
		type = "bool-setting",
		name = "razi-performance-compact-route-overlays",
		setting_type = "startup",
		default_value = false,
		order = "ae[performance]-07[performance-compact-route-overlays]"
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
	},
	{
		type = "bool-setting",
		name = "razi-quality-asteroids",
		setting_type = "startup",
		default_value = true,
		order = "ad[asteroids]-01[quality-asteroids]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-asteroid-particles",
		setting_type = "startup",
		default_value = false,
		order = "ae[performance]-01[performance-asteroid-particles]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-weapon-particles",
		setting_type = "startup",
		default_value = false,
		order = "ae[performance]-02[performance-weapon-particles]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-reduced-fragments",
		setting_type = "startup",
		default_value = false,
		order = "ae[performance]-03[performance-reduced-fragments]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-outer-hostile-density",
		setting_type = "startup",
		default_value = false,
		order = "ae[performance]-04[performance-outer-hostile-density]"
	},
	{
		type = "bool-setting",
		name = "razi-performance-space-explosion-smoke",
		setting_type = "startup",
		default_value = false,
		order = "ae[performance]-05[performance-space-explosion-smoke]"
	},
	{
		type = "bool-setting",
		name = "razi-default-new-game-map",
		setting_type = "startup",
		default_value = true,
		order = "00[gameplay-difficulty]-b[map-generator]"
	},
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
		name = "razi-spoilage-pressure",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"forgiving", "normal", "fast", "brutal"},
		order = "ab[resources]-04[spoilage-pressure]"
	},
	{
		type = "string-setting",
		name = "razi-resource-frequency",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"abundant", "normal", "scarce", "desolate"},
		order = "ab[resources]-01[resource-frequency]"
	},
	{
		type = "string-setting",
		name = "razi-resource-patch-size",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"expansive", "normal", "small", "tiny"},
		order = "ab[resources]-02[resource-patch-size]"
	},
	{
		type = "string-setting",
		name = "razi-resource-richness",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"generous", "normal", "poor", "meager"},
		order = "ab[resources]-03[resource-richness]"
	},
	{
		type = "string-setting",
		name = "razi-science-demand",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"light", "normal", "intensive", "grueling"},
		order = "ab[resources]-05[science-demand]"
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
		name = "razi-rocket-launch-cost",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"economical", "normal", "costly", "punishing"},
		order = "ab[resources]-06[rocket-launch-cost]"
	},
	{
		type = "string-setting",
		name = "razi-factory-throughput",
		setting_type = "startup",
		default_value = "normal",
		allowed_values = {"boosted", "normal", "constrained", "strained"},
		order = "ab[resources]-07[factory-throughput]"
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
