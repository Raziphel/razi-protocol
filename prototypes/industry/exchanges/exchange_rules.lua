-- The cross-planet production exchanges that planet_production_exchanges.lua registers when
-- their sources, machines and research allow it.
local exchanges = {
  {
    name = "razi-bio-rare-metal-casting",
    source = "kr-casting-rare-metals",
    product = "kr-rare-metals",
    planets = {"planet-discovery-vulcanus", "planet-discovery-gleba"},
    science = {"calidus-tech-card"},
    category = "metallurgy",
    working_world = "vulcanus",
    additional = {{type="item", name="bioflux", amount=2}},
    batch = 4, bonus = 1, count = 350, time = 30,
    bonus_icon = "bioflux",
    -- Industrial exchange opens in the first frontier, not after Fulgora.
    not_after = {"vibrant-discovery", "vespera-discovery"}
  },
  {
    name = "razi-electrobiological-components",
    source = "kr-electronic-components",
    product = "kr-electronic-components",
    planets = {"planet-discovery-fulgora", "planet-discovery-gleba"},
    science = {"solaris-tech-card", "nyxaris-tech-card"},
    category = "electromagnetics",
    surface_source = "kr-electromagnetic-research-data",
    surface_world = "fulgora",
    additional = {
      {type="item", name="bioflux", amount=1},
      {type="item", name="holmium-plate", amount=1}
    },
    batch = 4, bonus = 1, target_bonus_fraction = 0.20,
    max_bonus_fraction = 0.25, time_multiplier = 1.12,
    count = 550, time = 45,
    bonus_icon = "holmium-plate",
    not_after = {"beetlejuice-discovery", "umbra-discovery"}
  },
  -- Tenebris remains an independent chitin economy. Shipping stable Gleba
  -- bioflux only boosts its plastic output, never replaces its local chitin.
  {
    name = "razi-gleba-tenebris-biopolymer",
    source_mod = "tenebris-prime",
    source = "biopolymer",
    product = "plastic-bar",
    planets = {"planet-discovery-tenebris", "planet-discovery-gleba"},
    science = {"vibrant-tech-card", "vespera-tech-card"},
    category = "organic", working_world = "tenebris",
    additional = {{type="item", name="bioflux", amount=1}},
    batch = 2, bonus = 2, count = 950, time = 45,
    bonus_icon = "bioflux"
  }
}

return exchanges
