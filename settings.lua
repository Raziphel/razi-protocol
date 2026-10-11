-- FluxWorks-inspired sections use localized rich-text labels and stable
-- alphabetical order prefixes. Only real Razi-owned behavior is configurable.
-- All existing settings retain their names, types and default values.
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

  -- PRODUCTION INTEGRATION. These are independent optional recipe catalogs;
  -- neither switch disables Razi's mandatory seven-system science progression.
  startup_toggle("razi-enable-k2so-production-exchanges",
    "ba[integration]-a[k2so-exchanges]"),
  startup_toggle("razi-enable-modded-planet-exchanges",
    "ba[integration]-b[modded-planets]"),

  -- QUALITY OF LIFE
  startup_toggle("razi-hide-redundant-assembler-tiers",
    "ca[quality-of-life]-a[redundant-assemblers]"),
  startup_toggle("razi-enable-expedition-briefings",
    "ca[quality-of-life]-b[expedition-briefings]"),
  {
    type="string-setting",
    name="razi-route-highlight-style",
    setting_type="startup",
    default_value="subtle",
    allowed_values={"off","subtle","clear"},
    order="ca[quality-of-life]-c[route-highlights]"
  },
  startup_toggle("razi-route-intelligence",
    "ca[quality-of-life]-d[route-intelligence]")
})
