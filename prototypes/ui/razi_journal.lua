-- Always reachable while playing, but no shortcut-bar button.
data:extend({
 {type="custom-input",name="razi-journal-toggle",
  key_sequence="CONTROL + SHIFT + J",consuming="none"},
 -- Factorio core's monochrome Factoriopedia book glyph, scaled to 32px
 -- inside the native 40px mod-GUI square next to the minimap.
 {type="sprite",name="razi-journal-book-icon",
  filename="__core__/graphics/side-menu-buttons.png",
  size=64,y=640,scale=0.5,mipmap_count=2,flags={"gui-icon"}}
})
