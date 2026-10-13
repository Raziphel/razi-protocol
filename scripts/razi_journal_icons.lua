-- Native GUI images do not automatically respect style.width/height.
-- A modded planet/technology sprite may be 256px or larger. Every Codex
-- image must opt out of intrinsic sprite sizing and fit a fixed square.
-- No sprite conversion, dynamic texture baking, or per-tick rescaling.
local M={}

local SIZES={
  toolbar=32,
  window_emblem=28,
  tracker_chapter=18,
  tracker_quest=24,
  chapter_seal=26,
  quest_hero=36,
  priority=18,
  chapter_button=28,
  quest_row=20,
  gallery=28,
  archive_button=26,
  archive_cover=32
}
M.SIZES=SIZES

function M.size(role)
  local value=SIZES[role]
  assert(value,"Unknown journal icon role: "..tostring(role))
  return value
end

function M.sprite(parent,path,role,tooltip)
  local edge=M.size(role)
  local element=parent.add{
    type="sprite",sprite=path,resize_to_sprite=false,tooltip=tooltip
  }
  -- Fixed bounds *and* resize_to_sprite=false are both necessary. Width
  -- alone can still let Factorio expand to a source sprite's natural size.
  element.style.size=edge
  element.style.stretch_image_to_widget_size=true
  return element
end

function M.button(parent,path,role,tags,tooltip,name)
  local edge=M.size(role)
  local element=parent.add{
    type="sprite-button",name=name,style="slot_button",sprite=path,
    tags=tags,tooltip=tooltip
  }
  element.style.size=edge
  return element
end

return M
