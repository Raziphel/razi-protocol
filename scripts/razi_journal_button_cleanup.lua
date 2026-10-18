-- Retire unsupported Expedition Journal overlays introduced in 2.1.118
-- and 2.1.119. Vanilla Factorio GUIs always draw above LuaGui::screen,
-- so trying to paint into the vanilla minimap menu's empty squares hides
-- the button. The journal now has a real Factorio shortcut-bar prototype.
local M={}
local ANCHOR="razi_expedition_journal_minimap_anchor"
function M.remove(player,name)
  if not (player and player.valid) then return end
  local top=player.gui.top
  local old=top[name]
  if old and old.valid then old.destroy() end

  -- The first attempt used mod_gui.get_button_flow(), on the top-left.
  local frame=top["mod_gui_top_frame"]
  local inner=frame and frame.valid and frame["mod_gui_inner_frame"]
  if inner and inner.valid then
    old=inner[name]
    if old and old.valid then old.destroy() end
    -- The containing mod-gui may belong to another mod. Leave it alone.
  end
  local legacy=top["mod_gui_button_flow"]
  if legacy and legacy.valid then
    old=legacy[name]
    if old and old.valid then old.destroy() end
  end

  local screen=player.gui.screen
  old=screen[name]
  if old and old.valid then old.destroy() end
  old=screen[ANCHOR]
  if old and old.valid then old.destroy() end
end
return M
