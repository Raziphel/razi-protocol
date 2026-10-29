-- Native GUI images do not automatically respect style.width/height.
-- A modded planet/technology sprite may be 256px or larger. Every Codex
-- image must opt out of intrinsic sprite sizing and fit a fixed square.
-- No sprite conversion, dynamic texture baking, or per-tick rescaling.
local M={}

local SIZES={
  toolbar=42,
  window_emblem=28,
  tab_icon=16,
  tracker_chapter=18,
  tracker_quest=24,
  chapter_seal=26,
  quest_hero=36,
  priority=18,
  chapter_button=22,
  quest_row=20,
  gallery=28,
  archive_button=26,
  archive_cover=32,
  project_icon=32,
  project_button=30,
  project_hero=40,
  cargo_header=28,
  cargo_chain=32,
  cargo_research=19,
  cargo_world=18,
  cargo_material=18,
  cargo_science=18
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
    type="sprite-button",name=name,
    style=role=="toolbar" and "razi_journal_hud_button" or "slot_button",
    sprite=path,
    tags=tags,tooltip=tooltip
  }
  element.style.size=edge
  return element
end

return M
