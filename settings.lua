-- Settings use localized color labels and stable numeric section order keys.
-- Only real Razi-owned behavior is configurable.
-- Setting names and types stay stable; Full native orbits are now the default.
local function startup_toggle(name, order)
  return {
    type = "bool-setting",
    name = name,
    setting_type = "startup",
    default_value = true,
    order = order
  }
end

data:extend({
  -- Normal is the default for fresh installations. Old saved startup choices
  -- remain player-owned, including an existing Custom selection.
  -- Startup changes require a Factorio restart BEFORE entering a save:
  -- other prototype-stage passes resolve the preset during the next mod load.
  -- The GUI still displays the saved manual controls, not resolved values.
  -- Custom appears LAST, as an advanced/manual override mode. Gameplay modes
  -- never override accessibility, cosmetics or source mod settings.
  {type="string-setting",name="razi-difficulty-preset",
    setting_type="startup",default_value="normal",
    allowed_values={"easy","normal","hard","nightmare","custom"},
    order="00[gameplay-difficulty]-a[preset]"},
  -- The map generator initially selects a Razi-branded default. Turn off
  -- to retain Factorio/other-mod default choice and default map values.
  {type="bool-setting",name="razi-default-new-game-map",
    setting_type="startup",default_value=true,
    order="00[gameplay-difficulty]-b[map-generator]"},
  -- One shared save setting controls research spoiler fog and the Journal.
  -- Runtime-global allows multiplayer forces to agree on research visibility
  -- and can be toggled without restarting or changing prototype IDs.
  {type="bool-setting",name="razi-hide-spoilers",
    setting_type="runtime-global",default_value=true,
    order="a0[quality-of-life]-a[hide-spoilers]"},
  -- Advanced opt-in scope. Main spoiler mode must be enabled to apply.
  -- Actual science/research already available is always kept visible.
  {type="bool-setting",name="razi-hide-other-tech-spoilers",
    setting_type="runtime-global",default_value=true,
    order="a0[quality-of-life]-b[other-mod-technologies]"},
  -- Personal onboarding settings, only applied to first-time arrival.
  {type="bool-setting",name="razi-clean-startup-chat",
    setting_type="runtime-per-user",default_value=true,
    order="a1[welcome]-a[compact-console]"},
  {type="bool-setting",name="razi-show-welcome",
    setting_type="runtime-per-user",default_value=true,
    order="a1[welcome]-b[welcome-message]"},
  -- Purely local UI visibility controls. The journal and hotkey still work.
  {type="bool-setting",name="razi-journal-show-button",
    setting_type="runtime-per-user",default_value=true,
    order="a1[welcome]-c[journal-shortcut]"},
  {type="bool-setting",name="razi-journal-show-tracker",
    setting_type="runtime-per-user",default_value=true,
    order="a1[welcome]-d[pinned-tracker]"},
  -- Combat systems use a common difficulty mode, but the player can still
  -- customize each value independently. Changes to advanced gameplay
  -- controls make the resolved difficulty Custom without overwriting them.
  {type="string-setting",name="razi-enemy-pressure",
    setting_type="startup",default_value="normal",
    allowed_values={"light","normal","aggressive","overrun"},
    order="aa[combat]-01[enemy-pressure]"},
  {type="string-setting",name="razi-nexus-hostility",
    setting_type="startup",default_value="normal",
    allowed_values={"normal","hard","apocalypse"},
    order="aa[combat]-02[nexus-hostility]"},
  -- Big-Monsters is controlled only through its published remote API.
  -- Its own interval and event weighting remain independently editable.
  {type="bool-setting",name="razi-big-monsters-events",
    setting_type="startup",default_value=false,
    order="aa[combat]-03[big-monsters-events]"},
  -- Native, non-scripted challenge systems with independent Custom controls.
  {type="string-setting",name="razi-pollution-pressure",
    setting_type="startup",default_value="normal",
    allowed_values={"gentle","normal","heavy","toxic"},
    order="aa[combat]-04[pollution-pressure]"},
  {type="string-setting",name="razi-raid-coordination",
    setting_type="startup",default_value="normal",
    allowed_values={"small","normal","organized","siege"},
    order="aa[combat]-05[raid-coordination]"},
  {type="string-setting",name="razi-colony-expansion",
    setting_type="startup",default_value="normal",
    allowed_values={"slow","normal","rapid","invasive"},
    order="aa[combat]-06[colony-expansion]"},
  {type="string-setting",name="razi-spoilage-pressure",
    setting_type="startup",default_value="normal",
    allowed_values={"forgiving","normal","fast","brutal"},
    order="ab[resources]-04[spoilage-pressure]"},
  -- Per-subsystem economic challenge knobs: manual edits resolve Custom
  -- without changing any other mod's saved startup settings.
  {type="string-setting",name="razi-resource-frequency",
    setting_type="startup",default_value="normal",
    allowed_values={"abundant","normal","scarce","desolate"},
    order="ab[resources]-01[resource-frequency]"},
  {type="string-setting",name="razi-resource-patch-size",
    setting_type="startup",default_value="normal",
    allowed_values={"expansive","normal","small","tiny"},
    order="ab[resources]-02[resource-patch-size]"},
  {type="string-setting",name="razi-resource-richness",
    setting_type="startup",default_value="normal",
    allowed_values={"generous","normal","poor","meager"},
    order="ab[resources]-03[resource-richness]"},
  {type="string-setting",name="razi-science-demand",
    setting_type="startup",default_value="normal",
    allowed_values={"light","normal","intensive","grueling"},
    order="ab[resources]-05[science-demand]"},
  {type="string-setting",name="razi-evolution-speed",
    setting_type="startup",default_value="normal",
    allowed_values={"slow","normal","accelerated","runaway"},
    order="aa[combat]-07[evolution-speed]"},
  {type="string-setting",name="razi-rocket-launch-cost",
    setting_type="startup",default_value="normal",
    allowed_values={"economical","normal","costly","punishing"},
    order="ab[resources]-06[rocket-launch-cost]"},
  -- Prototype-only production and fortification difficulty.
  {type="string-setting",name="razi-factory-throughput",
    setting_type="startup",default_value="normal",
    allowed_values={"boosted","normal","constrained","strained"},
    order="ab[resources]-07[factory-throughput]"},
  {type="string-setting",name="razi-fortification-durability",
    setting_type="startup",default_value="normal",
    allowed_values={"reinforced","normal","fragile","brittle"},
    order="aa[combat]-08[fortification-durability]"},
  -- Difficulty-aware, individually configurable enemy habitat coverage.
  {type="string-setting",name="razi-habitat-armoured-biters",
    setting_type="startup",default_value="auto",
    allowed_values={"auto","off","limited","curated","expanded","all"},
    order="ac[habitats]-02[habitat-armoured-biters]"},
  {type="string-setting",name="razi-habitat-cold-biters",
    setting_type="startup",default_value="auto",
    allowed_values={"auto","off","limited","curated","expanded","all"},
    order="ac[habitats]-03[habitat-cold-biters]"},
  {type="string-setting",name="razi-habitat-explosive-biters",
    setting_type="startup",default_value="auto",
    allowed_values={"auto","off","limited","curated","expanded","all"},
    order="ac[habitats]-04[habitat-explosive-biters]"},
  {type="string-setting",name="razi-habitat-toxic-biters",
    setting_type="startup",default_value="auto",
    allowed_values={"auto","off","limited","curated","expanded","all"},
    order="ac[habitats]-05[habitat-toxic-biters]"},
  {type="string-setting",name="razi-habitat-arachnids",
    setting_type="startup",default_value="auto",
    allowed_values={"auto","off","limited","curated","expanded","all"},
    order="ac[habitats]-06[habitat-arachnids]"},
  {type="string-setting",name="razi-habitat-electric-enemies",
    setting_type="startup",default_value="auto",
    allowed_values={"auto","off","limited","curated","expanded","all"},
    order="ac[habitats]-07[habitat-electric-enemies]"},
  -- WORLDS & ENCOUNTERS
  startup_toggle("razi-enable-enemy-routing", "ac[habitats]-01[enable-enemy-routing]"),
  -- Native ten-stage quality asteroid escalation. No separate quality mod.
  {type="bool-setting",name="razi-quality-asteroids",
    setting_type="startup",default_value=true,
    order="ad[asteroids]-01[quality-asteroids]"},
  {type="string-setting",name="razi-asteroid-difficulty-scale",
    setting_type="startup",default_value="balanced",
    allowed_values={"balanced","challenging","relentless"},
    order="ad[asteroids]-02[asteroid-difficulty-scale]"},


  -- GAMEPLAY CHALLENGE: Standard keeps the original asteroid spawn rates.
  {type="string-setting",name="razi-asteroid-population",
    setting_type="startup",default_value="standard",
    allowed_values={"sparse","standard","dense","swarm"},
    order="ad[asteroids]-03[asteroid-population]"},
  {type="string-setting",name="razi-belt-threats",
    setting_type="startup",default_value="standard",
    allowed_values={"relaxed","standard","severe"},
    order="ad[asteroids]-04[belt-threats]"},
  {type="string-setting",name="razi-belt-resource-richness",
    setting_type="startup",default_value="standard",
    allowed_values={"scarce","standard","rich"},
    order="ad[asteroids]-05[belt-resource-richness]"},
  {type="bool-setting",name="razi-belt-midsection-salvage",
    setting_type="startup",default_value=true,
    order="ad[asteroids]-06[belt-midsection-salvage]"},
  {type="bool-setting",name="razi-belt-edge-harvesting",
    setting_type="startup",default_value=true,
    order="ad[asteroids]-07[belt-edge-harvesting]"},
  -- PERFORMANCE EXPERIMENTS. All deliberately OFF: Factorio 2.1
  -- already optimizes many collectors, and some options change resources.
  {type="bool-setting",name="razi-performance-asteroid-particles",
    setting_type="startup",default_value=false,
    order="ae[performance]-01[performance-asteroid-particles]"},
  {type="bool-setting",name="razi-performance-weapon-particles",
    setting_type="startup",default_value=false,
    order="ae[performance]-02[performance-weapon-particles]"},
  {type="bool-setting",name="razi-performance-reduced-fragments",
    setting_type="startup",default_value=false,
    order="ae[performance]-03[performance-reduced-fragments]"},
  {type="bool-setting",name="razi-performance-outer-hostile-density",
    setting_type="startup",default_value=false,
    order="ae[performance]-04[performance-outer-hostile-density]"},

  {type="bool-setting",name="razi-performance-space-explosion-smoke",
    setting_type="startup",default_value=false,
    order="ae[performance]-05[performance-space-explosion-smoke]"},
  -- Separate opt-in removal of cosmetic asteroid creation dust.
  -- Scripted quality-asteroid spawn events remain untouched.
  {type="bool-setting",name="razi-performance-asteroid-creation-dust",
    setting_type="startup",default_value=false,
    order="ae[performance]-06[performance-asteroid-creation-dust]"},
  -- Reduces precomputed map sprite layers, not active ship simulation.
  {type="bool-setting",name="razi-performance-compact-route-overlays",
    setting_type="startup",default_value=false,
    order="ae[performance]-07[performance-compact-route-overlays]"},

  -- PRODUCTION INTEGRATION. The overarching mode controls optional cross-world
  -- discoveries and industry. The following toggles remain independent filters.
  {
    type = "string-setting",
    name = "razi-planetary-interdependence",
    setting_type = "startup",
    default_value = "balanced",
    allowed_values = {"off", "balanced", "deep"},
    order = "ba[integration]-0[interdependence]"
  },
  -- PRODUCTION INTEGRATION. These are independent optional recipe catalogs;
  -- neither switch disables Razi's mandatory seven-system science progression.
  startup_toggle("razi-enable-k2so-production-exchanges",
    "ba[integration]-a[k2so-exchanges]"),
  startup_toggle("razi-enable-modded-planet-exchanges",
    "ba[integration]-b[modded-planets]"),
  -- Move only guarded, optional non-bootstrap technologies into actual
  -- planetary science. Switch off for legacy/alternate start scenarios.
  startup_toggle("razi-distributed-technology",
    "ba[integration]-c[planetary-tech-distribution]"),
  -- Keep Aquilo's cryogenic capabilities, but earn terrain, portable
  -- fusion and legendary quality across later campaign milestones.
  startup_toggle("razi-stage-aquilo-breakthroughs",
    "ba[integration]-c2[aquilo-breakthroughs]"),
  -- Only late source-owned trains and shield research; never change
  -- cargo bay limits, source mod machinery or base rocket logistics.
  startup_toggle("razi-companion-science-weave",
    "ba[integration]-d[companion-industries]"),
  -- Experimental upstream link format. Disabled by default so installs
  -- cannot bypass the Vespera belt or introduce starmap order problems.
  -- Orbital Catapult is required via a load-order-independent dependency.
  -- Keep the existing setting ID for old saves; enable local Vespera
  -- freight links by default, without altering native planet research.
  {type="bool-setting",name="razi-orbital-catapult-local-links",
    setting_type="startup",default_value=true,
    order="ba[integration]-e[catapult-links]"},
  -- Optional second network layer: short local links on Solaris,
  -- Nyxaris and the Maraxsis spur. No star/belt crossings.
  {type="bool-setting",name="razi-orbital-catapult-regional-links",
    setting_type="startup",default_value=true,
    order="ba[integration]-e2[regional-catapult-links]"},

  -- HOME SYSTEM MEGAPROJECT
  startup_toggle("razi-dyson-milestone-weave",
    "bb[stellar]-a[research]"),
  startup_toggle("razi-dyson-calidus-layout",
    "bb[stellar]-b[calidus-placement]"),

  -- HELIOS: route difficulty and source-preserving late-game progression.
  {type="string-setting",name="razi-helios-progression",
    setting_type="startup",default_value="late",
    allowed_values={"legacy","late","epic"},
    order="bb[stellar]-c[progression]"},
  {type="string-setting",name="razi-helios-route-danger",
    setting_type="startup",default_value="extreme",
    allowed_values={"native","challenging","extreme"},
    order="bb[stellar]-e[corona-threats]"},
  {type="string-setting",name="razi-helios-route-distance",
    setting_type="startup",default_value="extended",
    allowed_values={"native","extended","marathon"},
    order="bb[stellar]-f[corona-distance]"},
  {type="string-setting",name="razi-helios-construction",
    setting_type="startup",default_value="satellites",
    allowed_values={"off","engineering","satellites"},
    order="bb[stellar]-d[industrial-construction]"},
  -- Second HELIOS expedition: physical commissioning and powered grid hardware.
  {type="string-setting",name="razi-helios-commissioning",
    setting_type="startup",default_value="expedition",
    allowed_values={"off","expedition","monumental"},
    order="bb[stellar]-g[commissioning]"},
  {type="bool-setting",name="razi-helios-convergence-proof",
    setting_type="startup",default_value=false,
    order="bb[stellar]-h[finale-proof]"},
  {type="string-setting",name="razi-helios-coronal-surges",
    setting_type="startup",default_value="occasional",
    allowed_values={"off","occasional","volatile"},
    order="bb[stellar]-i[coronal-surges]"},
  -- QUALITY OF LIFE
  startup_toggle("razi-hide-redundant-assembler-tiers",
    "ca[quality-of-life]-a[redundant-assemblers]"),
  startup_toggle("razi-enable-expedition-briefings",
    "ca[quality-of-life]-b[expedition-briefings]"),
  {type="bool-setting",name="razi-group-barreling-recipes",
    setting_type="startup",default_value=true,
    order="ca[quality-of-life]-b1[barreling-recipes]"},
  {type="bool-setting",name="razi-group-spoilable-recipes",
    setting_type="startup",default_value=false,
    order="ca[quality-of-life]-b2[spoilable-recipes]"},
  -- Only the crafting-list visibility changes; research and factories remain
  -- intact. Prototype settings apply to all players and require a restart.
  {type="string-setting",name="razi-hand-crafting-cleanup",
    setting_type="startup",default_value="all",
    allowed_values={"off","razi","all"},
    order="ca[quality-of-life]-b3[hand-crafting]"},
  -- Razi draws thin color on top of verified native route geometry,
  -- while the underlying Factorio connection remains clickable.
  {
    type="string-setting",name="razi-route-overlay-mode",setting_type="startup",
    default_value="danger",allowed_values={"off","danger","chapter"},
    order="ca[quality-of-life]-c[route-overlay-mode]"
  },
  {
    type="string-setting",name="razi-route-overlay-scope",setting_type="startup",
    default_value="all",allowed_values={"major","all"},
    order="ca[quality-of-life]-c2[route-overlay-scope]"
  },
  startup_toggle("razi-curated-space-routes",
    "ca[quality-of-life]-c3[curated-route-authority]"),
  startup_toggle("razi-route-intelligence",
    "ca[quality-of-life]-d[route-intelligence]"),
  -- EXPEDITION PRESENTATION AND PREFERENCES
  {type="bool-setting",name="razi-route-distance-repair",setting_type="startup",default_value=true,order="ba[integration]-z[distance-repair]"},
  {type="string-setting",name="razi-route-visibility",setting_type="startup",default_value="standard",allowed_values={"soft","standard","bright"},order="ca[quality-of-life]-e[route-visibility]"},
  {type="string-setting",name="razi-route-detail",setting_type="startup",default_value="standard",allowed_values={"economy","standard","smooth"},order="ca[quality-of-life]-f[route-detail]"},
  {type="bool-setting",name="razi-route-show-danger",setting_type="startup",default_value=true,order="ca[quality-of-life]-g[danger]"},
  {type="bool-setting",name="razi-route-show-sizes",setting_type="startup",default_value=true,order="ca[quality-of-life]-h[sizes]"},
  {type="bool-setting",name="razi-route-show-salvage",setting_type="startup",default_value=true,order="ca[quality-of-life]-i[salvage]"},
  {type="bool-setting",name="razi-route-show-advice",setting_type="startup",default_value=true,order="ca[quality-of-life]-j[advice]"},
  {type="bool-setting",name="razi-route-show-unknown",setting_type="startup",default_value=true,order="ca[quality-of-life]-k[unknown]"},
  {type="bool-setting",name="razi-route-show-belts",setting_type="startup",default_value=true,order="ca[quality-of-life]-l[belts]"},
  {type="bool-setting",name="razi-route-show-sectors",setting_type="startup",default_value=true,order="ca[quality-of-life]-m[sectors]"},
  {type="bool-setting",name="razi-route-show-haul",setting_type="startup",default_value=true,order="ca[quality-of-life]-n[haul]"},
  -- GALAXY VISUALS
  {
    type="string-setting",
    name="razi-starmap-background-style",
    setting_type="startup",
    default_value="subtle",
    allowed_values={"off","subtle","cinematic"},
    order="cb[starmap]-a[background]"
  },
  {
    type="string-setting",
    name="razi-starmap-orbit-density",
    setting_type="startup",
    default_value="full",
    allowed_values={"full","balanced","clean","off"},
    order="cb[starmap]-a2[orbit-density]"
  },
  startup_toggle("razi-starmap-system-halos","cb[starmap]-b[halos]"),
  startup_toggle("razi-starmap-belt-atmosphere","cb[starmap]-c[belts]"),
  startup_toggle("razi-starmap-soften-bellicos","cb[starmap]-c2[pulsar-glare]"),
  startup_toggle("razi-starmap-fine-details","cb[starmap]-d[details]"),
  startup_toggle("razi-starmap-galactic-ornaments",
    "cb[starmap]-d2[quiet-nebula-structure]"),
  startup_toggle("razi-starmap-micro-details",
    "cb[starmap]-d3[micro-details]"),
  startup_toggle("razi-starmap-cinematic-extras",
    "cb[starmap]-d4[cinematic-extras]"),
  {
    type="bool-setting",
    name="razi-starmap-cartography",
    setting_type="startup",
    default_value=false,
    order="cb[starmap]-e[chart]"
  },
  {type="string-setting",name="razi-map-star-intensity",setting_type="startup",default_value="standard",allowed_values={"dim","standard","bright"},order="cb[starmap]-f[stars]"},
  {type="string-setting",name="razi-map-halo-intensity",setting_type="startup",default_value="standard",allowed_values={"faint","standard","strong"},order="cb[starmap]-g[halos]"},
  {type="string-setting",name="razi-map-belt-intensity",setting_type="startup",default_value="standard",allowed_values={"faint","standard","strong"},order="cb[starmap]-h[belt]"},
  {type="string-setting",name="razi-map-dust-intensity",setting_type="startup",default_value="standard",allowed_values={"faint","standard","strong"},order="cb[starmap]-i[dust]"},
  -- Science converters can be disabled for established save layouts.
  {type="bool-setting",name="razi-auto-tech-cards",setting_type="startup",default_value=true,
    order="ca[quality-of-life]-b4[auto-tech-cards]"}
})
