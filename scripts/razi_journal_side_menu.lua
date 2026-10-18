-- The vanilla right-side minimap button GRID is not exposed by Factorio's
-- LuaGui API. Match its 2nd-row 5th-position visually with a screen overlay.
-- This is not an actual child of the native side-menu GUI.
local M={}
local BUTTON_EDGE=40
local COLUMN_PITCH=44
local TOP_MARGIN=104
local RIGHT_PADDING=12
-- The 5th (penultimate) of six 40px slots in the bottom row. In the
-- standard UI this cell is an unused dark placeholder (see the screenshots).
local COLUMNS_FROM_RIGHT=2

function M.position(resolution, scale)
  local factor=math.max(0.5, tonumber(scale) or 1)
  local width=math.floor((resolution and resolution.width or 1920)/factor)
  return {
    x=math.max(0,width-RIGHT_PADDING-BUTTON_EDGE-
      (COLUMNS_FROM_RIGHT-1)*COLUMN_PITCH),
    y=TOP_MARGIN,
  }
end

local function remove_previous_buttons(player,name)
  -- Versions before the first minimap redesign created the element here.
  local top=player.gui.top
  local old=top[name]
  if old and old.valid then old.destroy() end

  -- The previous patch used the mod-gui helper, which puts buttons on the
  -- TOP-LEFT of the screen. Remove only our own child, never another mod's.
  local frame=top["mod_gui_top_frame"]
  local flow=frame and frame.valid and frame["mod_gui_inner_frame"]
  if flow and flow.valid then
    old=flow[name]
    if old and old.valid then old.destroy() end
    -- Clean up the vacated old container only if *nobody* uses it.
    if #flow.children==0 and #frame.children==1 then frame.destroy() end
  end
  local legacy=top["mod_gui_button_flow"]
  if legacy and legacy.valid then
    old=legacy[name]
    if old and old.valid then old.destroy() end
  end
end

function M.ensure(player,name,tooltip)
  if not (player and player.valid) then return end
  remove_previous_buttons(player,name)

  local root=player.gui.screen
  local button=root[name]
  if not (button and button.valid) then
    button=root.add{
      type="sprite-button",
      name=name,
      style="side_menu_button",
      sprite="razi-journal-book-icon",
      tags={razi_journal_action="toggle"},
      tooltip=tooltip,
    }
  end
  -- Screen GUI positions use player interface-scaled coordinates. Update
  -- on init, reconnect, config migration and resolution/scale changes.
  button.location=M.position(player.display_resolution,player.display_scale)
  -- If the entire vanilla side menu is hidden, leave the hotkey usable.
  local settings=player.game_view_settings
  button.visible=not settings or settings.show_side_menu~=false
  return button
end

function M.update_visibility(player,name)
  if not (player and player.valid) then return end
  local button=player.gui.screen[name]
  if not (button and button.valid) then return end
  local settings=player.game_view_settings
  local desired=not settings or settings.show_side_menu~=false
  if button.visible~=desired then button.visible=desired end
end

return M
