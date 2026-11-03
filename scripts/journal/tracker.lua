-- The pinned-objective tracker on the left of the screen.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local objectives=require("scripts.journal.objectives")
local themes=require("scripts.journal.themes")
local icons=require("scripts.journal.icons")
local widgets=require("scripts.journal.widgets")
local TRACKER=widgets.TRACKER
local L=widgets.L
local COLOR=widgets.COLOR
local label=widgets.label
local wrap=widgets.wrap
local accent_rule=widgets.accent_rule
local show_player_option=widgets.show_player_option
local pref=require("scripts.journal.preferences")
local quest_state=require("scripts.journal.quest_state")
local technology=quest_state.technology
local art=require("scripts.journal.quest_art")
local quest_art=art.quest_art

local function render_tracker(player)
  local area=player.gui.left
  local old=area[TRACKER]
  if old and old.valid then old.destroy() end
  local p=pref(player.index)
  if not p.tracker or not show_player_option(player,"razi-journal-show-tracker") then return end
  local context=M.context(player.force,player)
  local quest=p.pinned and defs.by_id[p.pinned]
  if not quest or not M.journal_visible(player.force,quest,context) then
    quest=M.next_quest(player.force,context)
    p.pinned=quest and quest.id or nil
  end
  if not quest then return end
  local theme=themes.get(quest.chapter)
  local frame=area.add{type="frame",name=TRACKER,direction="vertical",
    caption=L("tracker-title")}
  frame.style.maximal_width=286
  frame.style.padding=9
  local chapter=frame.add{type="flow",direction="horizontal"}
  chapter.style.horizontal_spacing=7
  icons.sprite(chapter,themes.icon(quest.chapter),"tracker_chapter")
  local chapter_text=wrap(chapter,{"journal-chapter."..quest.chapter},225)
  chapter_text.style.font="default-bold"
  chapter_text.style.font_color=theme.primary
  accent_rule(frame,theme,108,2)
  local line=frame.add{type="flow",direction="horizontal"}
  line.style.horizontal_spacing=7
  icons.sprite(line,quest_art(player.force,quest,context),"tracker_quest")
  local heading=line.add{type="label",style="clickable_label",
    caption=defs.quest_title(quest,player),
    tags={razi_journal_action="tracker-open"}}
  heading.style.single_line=false
  heading.style.maximal_width=195
  heading.style.font="default-bold"
  local done=M.complete(player.force,quest,context)
  local signal=wrap(frame,L(quest.boss
    and (done and "tracker-boss-done" or "tracker-boss-pending")
    or (done and "tracker-done" or "tracker-pending")),245)
  signal.style.font_color=done and COLOR.green or COLOR.muted
  -- A pinned goal should say what is actually blocking it, not just
  -- "pending". Use the same source-backed checklist as the dossier.
  if not done then
    local tech=technology(player.force,quest,context)
    local live=objectives.snapshot(quest,tech,M.state(player.force,quest,context),{
      available=function(id)
        local required=defs.by_id[id]
        return required and M.available(player.force,required,context) or false
      end,
      visible=function(id)
        local required=defs.by_id[id]
        return required and M.journal_visible(player.force,required,context) or false
      end,
      complete=function(id)
        local required=defs.by_id[id]
        return required and M.complete(player.force,required,context) or false
      end,
      current_research=player.force.current_research,
      research_progress=player.force.research_progress
    })
    if live.next_step then
      local step=live.next_step
      local kind=step.kind=="goal" and live.kind or step.kind
      local next_action=wrap(frame,L("tracker-next",
        L("mission-step-"..kind,step.name)),253)
      next_action.style.font_color=theme.soft
    end
    if live.research_percent~=nil then
      local research=label(frame,L("mission-research-progress",
        tostring(live.research_percent)))
      research.style.font_color=COLOR.teal
    end
  end
end
M.render_tracker=render_tracker

return render_tracker
