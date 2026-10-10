-- Belt surveys appear when players can reach the preceding planet.
-- Both belt edges unlock together; technology unlocks never require resources
-- from the far side of the belt.
data:extend({
  {
    type="technology", name="razi-vespera-belt-survey",
    localised_name={"technology-name.razi-vespera-belt-survey"},
    icon="__space-age__/graphics/icons/solar-system-edge.png",
    icon_size=64, essential=true,
    order="ed[vespera]-b[belt]",
    prerequisites={"planet-discovery-aquilo"},
    unit={count=800,time=45,ingredients={{"vespera-tech-card",1}}},
    effects={
      {type="unlock-space-location",space_location="razi-vespera-belt-inner"},
      {type="unlock-space-location",space_location="razi-vespera-belt-outer"}
    }
  },
  {
    type="technology", name="razi-umbra-belt-survey",
    localised_name={"technology-name.razi-umbra-belt-survey"},
    icon="__space-age__/graphics/icons/solar-system-edge.png",
    icon_size=64, essential=true,
    order="ef[umbra]-b[belt]",
    prerequisites={"planet-discovery-crucible"},
    unit={count=1100,time=60,ingredients={{"umbra-tech-card",1}}},
    effects={
      {type="unlock-space-location",space_location="razi-umbra-belt-inner"},
      {type="unlock-space-location",space_location="razi-umbra-belt-outer"}
    }
  }
})
