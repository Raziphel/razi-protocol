-- The manager lives in a map-only screen overlay, not the shortcut bar.
-- The optional hotkey stays available while Remote View is active.
data:extend({
  {
    type="custom-input",
    name="razi-galactic-operations-input",
    key_sequence="CONTROL + SHIFT + G",
    consuming="none"
  },
  {
    type="sprite",
    name="razi-galactic-operations-map-icon",
    filename="__razi-protocol__/graphics/icons/routes/interstellar-route.png",
    width=64,
    height=64
  }
})
