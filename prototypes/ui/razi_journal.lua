-- Original compact top-left Expedition Journal button and hotkey.
data:extend({
 {type="custom-input",name="razi-journal-toggle",
  key_sequence="CONTROL + SHIFT + J",consuming="none"},
 {type="sprite",name="razi-journal-book-icon",
  filename="__razi-protocol__/graphics/ui/razi-journal-book.png",
  width=64,height=64,scale=0.5}
})

-- A restrained, native Factorio HUD control with a readable book emblem.
local styles=data.raw["gui-style"] and data.raw["gui-style"].default
if styles then
  styles.razi_journal_hud_button={
    type="button_style",parent="slot_button",size=42,padding=3
  }
end
