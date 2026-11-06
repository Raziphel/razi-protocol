-- Names, colours and the small GUI builders shared by the parts of the Journal.
local defs=require("scripts.journal.data")

local FRAME="razi_expedition_journal"
local TOP="razi_expedition_journal_button"
local TRACKER="razi_expedition_objective_tracker"
local L=function(key,...) return {"journal-ui."..key,...} end

-- A field-manual palette: chapter hues are restrained accents, not the ink.
-- Midnight Archive: soft parchment, antique brass and spectral teal.
-- Chapter pigments are used as signposts, never as entire text surfaces.
local COLOR={
  ink={r=.933,g=.890,b=.808}, muted={r=.72,g=.73,b=.71},
  quiet={r=.52,g=.58,b=.58}, green={r=.58,g=.80,b=.66},
  amber={r=.82,g=.69,b=.48}, teal={r=.52,g=.78,b=.76}
}

local function label(parent,caption)
  return parent.add{type="label",caption=caption}
end
local function wrap(parent,caption,width)
  local element=label(parent,caption)
  element.style.single_line=false
  element.style.horizontally_stretchable=true
  if width then element.style.maximal_width=width end
  return element
end
local function tint(element,color)
  element.style.font_color=color
  return element
end
local function subtitle(parent,key,width,theme)
  local item=label(parent,L(key))
  item.style.font="default-bold"
  item.style.font_color=theme and theme.soft or COLOR.muted
  if width then item.style.maximal_width=width end
  return item
end
-- A fine, chapter-colored rule that uses Factorio's built-in progressbar
-- texture. This needs no texture atlas or custom rendering on each tick.
local function accent_rule(parent,theme,width,thickness)
  local rule=parent.add{type="progressbar",value=1}
  rule.style.width=math.max(50,width)
  rule.style.height=thickness or 3
  rule.style.color=theme.primary
  return rule
end
-- Dense but legible folio section heads: a small number of native GUI
-- strokes make the chapter distinct without new atlases or paint events.
local function dossier_heading(parent,key,theme,width) -- luacheck: ignore 212
  local heading=parent.add{type="flow",direction="horizontal"}
  heading.style.horizontal_spacing=9
  heading.style.vertical_align="center"
  local title=subtitle(heading,key,width)
  title.style.font_color=COLOR.muted
  return heading
end
local function section(parent,key,caption,width,theme,tip)
  local block=parent.add{type="flow",direction="vertical"}
  block.style.horizontally_stretchable=true
  block.style.vertical_spacing=5
  dossier_heading(block,key,theme,width)
  if caption then
    local copy=wrap(block,caption,width)
    copy.style.font_color=COLOR.ink
    copy.tooltip=tip
  end
  return block
end

local function wheel_pane(parent,name,width,height)
  local pane=parent.add{type="scroll-pane",name=name,
    horizontal_scroll_policy="never",
    vertical_scroll_policy=name=="razi_journal_navigation"
      and "auto" or "dont-show-but-allow-scrolling"}
  pane.style.width=width
  pane.style.height=math.max(120,height)
  pane.style.horizontally_squashable=true
  pane.style.vertically_squashable=true
  return pane
end
local function chapter_index(id)
  for i,chapter in ipairs(defs.chapters) do
    if chapter.id==id then return i end
  end
  return 1
end

local function show_player_option(player,name)
  local personal=settings and settings.get_player_settings
    and settings.get_player_settings(player)
  local entry=personal and personal[name]
  return not entry or entry.value~=false
end

return {FRAME=FRAME,TOP=TOP,TRACKER=TRACKER,L=L,COLOR=COLOR,label=label,wrap=wrap,
  tint=tint,subtitle=subtitle,accent_rule=accent_rule,
  dossier_heading=dossier_heading,section=section,wheel_pane=wheel_pane,
  chapter_index=chapter_index,show_player_option=show_player_option}
