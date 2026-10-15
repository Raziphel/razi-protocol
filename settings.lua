-- Settings use localized section labels and stable intra-mod order keys.
-- The native settings GUI sorts by MOD before comparing these keys.
-- A title prefix in locale/en/settings.cfg is a best-effort display hint,
-- not a supported way to override the engine's mod-section ordering.
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
  -- WORLDS & ENCOUNTERS
  startup_toggle("razi-enable-enemy-routing", "aa[worlds]-a[enemy-routing]"),
  -- Native ten-stage quality asteroid escalation. No separate quality mod.
  {type="bool-setting",name="razi-quality-asteroids",
    setting_type="startup",default_value=true,
    order="aa[worlds]-b[quality-asteroids]"},
  {type="string-setting",name="razi-asteroid-difficulty-scale",
    setting_type="startup",default_value="balanced",
    allowed_values={"balanced","challenging","relentless"},
    order="aa[worlds]-c[asteroid-difficulty]"},


  -- PERFORMANCE EXPERIMENTS. All deliberately OFF: Factorio 2.1
  -- already optimizes many collectors, and some options change resources.
  {type="bool-setting",name="razi-performance-asteroid-particles",
    setting_type="startup",default_value=false,
    order="ad[asteroid-performance]-a[debris-effects]"},
  {type="bool-setting",name="razi-performance-weapon-particles",
    setting_type="startup",default_value=false,
    order="ad[asteroid-performance]-b[weapon-effects]"},
  {type="bool-setting",name="razi-performance-reduced-fragments",
    setting_type="startup",default_value=false,
    order="ad[asteroid-performance]-c[fragment-count]"},
  {type="bool-setting",name="razi-performance-outer-hostile-density",
    setting_type="startup",default_value=false,
    order="ad[asteroid-performance]-d[outer-hostiles]"},

  {type="bool-setting",name="razi-performance-space-explosion-smoke",
    setting_type="startup",default_value=false,
    order="ad[asteroid-performance]-e[explosion-smoke]"},
  -- Separate opt-in removal of cosmetic asteroid creation dust.
  -- Scripted quality-asteroid spawn events remain untouched.
  {type="bool-setting",name="razi-performance-asteroid-creation-dust",
    setting_type="startup",default_value=false,
    order="ad[asteroid-performance]-e2[creation-dust]"},
  -- Reduces precomputed map sprite layers, not active ship simulation.
  {type="bool-setting",name="razi-performance-compact-route-overlays",
    setting_type="startup",default_value=false,
    order="ad[asteroid-performance]-f[route-art-budget]"},

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
  -- Only late source-owned trains and shield research; never change
  -- cargo bay limits, source mod machinery or base rocket logistics.
  startup_toggle("razi-companion-science-weave",
    "ba[integration]-d[companion-industries]"),
  -- Experimental upstream link format. Disabled by default so installs
  -- cannot bypass the Vespera belt or introduce starmap order problems.
  {type="bool-setting",name="razi-orbital-catapult-local-links",
    setting_type="startup",default_value=false,
    order="ba[integration]-e[catapult-links]"},

  -- HOME SYSTEM MEGAPROJECT
  startup_toggle("razi-dyson-milestone-weave",
    "bb[stellar]-a[research]"),
  startup_toggle("razi-dyson-calidus-layout",
    "bb[stellar]-b[calidus-placement]"),

  -- QUALITY OF LIFE
  startup_toggle("razi-hide-redundant-assembler-tiers",
    "ca[quality-of-life]-a[redundant-assemblers]"),
  startup_toggle("razi-enable-expedition-briefings",
    "ca[quality-of-life]-b[expedition-briefings]"),
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
  {
    type="bool-setting",
    name="razi-starmap-cartography",
    setting_type="startup",
    default_value=false,
    order="cb[starmap]-e[chart]"
  }
})
