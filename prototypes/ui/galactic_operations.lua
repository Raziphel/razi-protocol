-- Separate, opt-in manager; never patches the native Space Age list.
local icon="__razi-protocol__/graphics/icons/routes/interstellar-route.png"
data:extend({
  {
    type="custom-input",
    name="razi-galactic-operations-input",
    key_sequence="CONTROL + SHIFT + G",
    consuming="none"
  },
  {
    type="shortcut", name="razi-galactic-operations",
    action="lua", style="blue", order="z[razi]-g[galactic-operations]",
    icon=icon,icon_size=64,small_icon=icon,small_icon_size=64,
    toggleable=true,associated_control_input="razi-galactic-operations-input"
  }
})
