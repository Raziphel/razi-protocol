-- Factorio 2.1 has no supported way to insert mod buttons into its
-- minimap-side grid. Visually align one to the empty LOWER row fifth cell.
-- The GUI belongs to this mod only. Do not modify other mods' buttons.
local M={}
local ANCHOR="razi_expedition_journal_minimap_anchor"
local BUTTON_SIZE=40
local COLUMN_PITCH=44
local RIGHT_PADDING=3
local TOP_MARGIN=94

function M.position(resolution,scale)
  local factor=math.max(0.5,tonumber(scale) or 1)
  local width=math.floor((resolution and resolution.width or 1920)/factor)
  -- In a 2048-pixel screen at 1.35x GUI scale, target about (1930,127).
  return {x=math.max(0,width-RIGHT_PADDING-BUTTON_SIZE-COLUMN_PITCH),
          y=TOP_MARGIN}
end

local function remove_old(player,name)
  local top=player.gui.top
  local old=top[name]
  if old and old.valid then old.destroy() end
  -- Earlier patch created a separate top-left mod_gui frame.
  local outer=top["mod_gui_top_frame"]
  local inner=outer and outer.valid and outer["mod_gui_inner_frame"]
  if inner and inner.valid then
    old=inner[name]
    if old and old.valid then old.destroy() end
    -- Do not destroy shared containers containing anyone else's buttons.
    if #inner.children==0 and #outer.children==1 then outer.destroy() end
  end
  local legacy=top["mod_gui_button_flow"]
  if legacy and legacy.valid then
    old=legacy[name]
    if old and old.valid then old.destroy() end
  end
  -- Remove prior version's direct screen sprite-button too.
  old=player.gui.screen[name]
  if old and old.valid then old.destroy() end
end

local function show_side_menu(player)
  local settings=player.game_view_settings
  return not settings or settings.show_side_menu~=false
end

function M.ensure(player,name,tooltip)
  if not (player and player.valid) then return end
  remove_old(player,name)
  local screen=player.gui.screen
  local anchor=screen[ANCHOR]
  if not (anchor and anchor.valid and anchor.type=="frame") then
    if anchor and anchor.valid then anchor.destroy() end
    anchor=screen.add{
      type="frame",name=ANCHOR,direction="horizontal",
      style="invisible_frame"
    }
  end
  -- A direct SCREEN FRAME can be positioned reliably in LuaGui::screen.
  -- Its transparent background leaves the vanilla cell appearance intact.
  anchor.style.padding=0
  local button=anchor[name]
  if not (button and button.valid) then
    button=anchor.add{
      type="sprite-button",name=name,style="side_menu_button",
      sprite="razi-journal-book-icon",tooltip=tooltip,
      tags={razi_journal_action="toggle"}
    }
  end
  button.style.size=BUTTON_SIZE
  anchor.location=M.position(player.display_resolution,player.display_scale)
  anchor.visible=show_side_menu(player)
  anchor.bring_to_front()
  return button
end

function M.update_visibility(player,name)
  if not (player and player.valid) then return end
  local anchor=player.gui.screen[ANCHOR]
  local button=anchor and anchor.valid and anchor[name]
  -- A development save might not run configuration_changed if it was
  -- previously installed without bumping its info.json version.
  if not (button and button.valid) then
    M.ensure(player,name,{"journal-ui.button-tooltip"})
    return
  end
  local visible=show_side_menu(player)
  if anchor.visible~=visible then anchor.visible=visible end
  local top=player.gui.top
  local frame=top["mod_gui_top_frame"]
  local flow=frame and frame.valid and frame["mod_gui_inner_frame"]
  local old=top[name]
  if (old and old.valid) or
      (flow and flow.valid and flow[name] and flow[name].valid) then
    remove_old(player,name)
  end
end
return M
