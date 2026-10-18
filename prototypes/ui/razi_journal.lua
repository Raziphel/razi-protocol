-- Always reachable while playing, but no shortcut-bar button.
data:extend({
 {type="custom-input",name="razi-journal-toggle",
  key_sequence="CONTROL + SHIFT + J",consuming="none"},
 -- Factorio core's monochrome Factoriopedia book glyph, scaled to 32px
 -- inside the native 40px mod-GUI square next to the minimap.
 {type="sprite",name="razi-journal-book-icon",
  filename="__core__/graphics/side-menu-buttons.png",
  size=64,y=640,scale=0.5,mipmap_count=2,flags={"gui-icon"}},
 -- Factorio supports custom entries in the *shortcut bar*, not in the
 -- built-in panel above the minimap. Keep the journal accessible in the
 -- game's official configurable toolbar, with Ctrl+Shift+J unchanged.
 {type="shortcut",name="razi-expedition-journal-shortcut",
  action="lua",
  order="z[razi]-a[expedition-journal]",
  localised_name={"journal-ui.button"},
  associated_control_input="razi-journal-toggle",
  icon="__base__/graphics/icons/shortcut-toolbar/mip/new-blueprint-book-x56.png",
  icon_size=56,
  small_icon="__base__/graphics/icons/shortcut-toolbar/mip/new-blueprint-book-x24.png",
  small_icon_size=24}
})
