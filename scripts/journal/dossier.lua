-- The quest dossier: the reading sheet of one objective.
local M=require("scripts.journal.api")
local defs=require("scripts.journal.data")
local story=require("lib.story")
local industrial_briefs=require("scripts.journal.planet_briefs")
local catapults=require("scripts.compatibility.orbital-cannon.catapult_network")
local weather=require("scripts.journal.weather_guide")
local projects=require("scripts.journal.projects")
local guidance=require("scripts.journal.guidance")
local objectives=require("scripts.journal.objectives")
local chapter_timing=require("scripts.journal.chapter_timing")
local marks=require("scripts.journal.marks")
local themes=require("scripts.journal.themes")
local icons=require("scripts.journal.icons")
local widgets=require("scripts.journal.widgets")
local L=widgets.L
local COLOR=widgets.COLOR
local label=widgets.label
local wrap=widgets.wrap
local tint=widgets.tint
local subtitle=widgets.subtitle
local accent_rule=widgets.accent_rule
local dossier_heading=widgets.dossier_heading
local section=widgets.section
local wheel_pane=widgets.wheel_pane
local chapter_index=widgets.chapter_index
local quest_state=require("scripts.journal.quest_state")
local technology=quest_state.technology
local completion_caption=quest_state.completion_caption
local quests_for_technology=quest_state.quests_for_technology
local art=require("scripts.journal.quest_art")
local quest_art=art.quest_art
local recipe_gallery=art.recipe_gallery
local archive_view=require("scripts.journal.archive_view")
local record_title=archive_view.record_title

local function render_details(parent,player,quest,p,context,size,view)
  local panel=parent.add{type="frame",direction="vertical",
    style="razi_journal_paper"}
  panel.style.width=size.reader
  panel.style.height=size.body
  panel.style.padding=11
  local inner=size.reader-38
  local status=M.state(player.force,quest,context)
  local theme=themes.get(quest.chapter)
  -- One dossier masthead instead of five independent header strips.
  -- The story has one title; chapter, file ID and live state are metadata.
  local masthead=panel.add{type="flow",direction="horizontal"}
  masthead.style.vertical_align="center"
  masthead.style.horizontal_spacing=8
  icons.sprite(masthead,themes.icon(quest.chapter),"chapter_seal",
    {"journal-chapter."..quest.chapter})
  local file_meta=masthead.add{type="flow",direction="vertical"}
  file_meta.style.vertical_spacing=1
  local chapter_intro=label(file_meta,{"journal-chapter."..quest.chapter})
  chapter_intro.style.font="default-bold"
  chapter_intro.style.font_color=theme.soft
  local serial=label(file_meta,L("dossier-index",
    string.format("%02d",chapter_index(quest.chapter))))
  serial.style.font_color=COLOR.quiet
  local masthead_space=masthead.add{type="empty-widget"}
  masthead_space.style.horizontally_stretchable=true
  local status_label=label(masthead,L("status-"..status))
  status_label.style.font="default-bold"
  status_label.style.font_color=status=="complete" and COLOR.green
    or status=="active" and COLOR.amber or COLOR.muted

  local hero=panel.add{type="flow",direction="horizontal"}
  hero.style.horizontal_spacing=11
  hero.style.vertical_align="center"
  icons.sprite(hero,quest_art(player.force,quest,context),"quest_hero")
  local hero_text=hero.add{type="flow",direction="vertical"}
  hero_text.style.vertical_spacing=2
  local hero_title=wrap(hero_text,defs.quest_title(quest,player),inner-68)
  hero_title.tooltip=story.key_tooltip(player,"quest-title",quest.id)
  hero_title.style.font="heading-2"
  hero_title.style.font_color=COLOR.ink
  local milestone_time=completion_caption(
    chapter_timing.get(player.force,"milestones",quest.id),"milestone")
  if status=="complete" and milestone_time then
    local stamp=wrap(hero_text,milestone_time,inner-68)
    stamp.style.font_color=COLOR.green
    stamp.tooltip=L("milestone-time-explanation")
  end
  if not size.compact and story.visible(player) then
    local mood=wrap(hero_text,story.text(player,"chapter-mood",quest.chapter,
      {"journal-mood."..quest.chapter}),inner-68)
    mood.style.font_color=COLOR.muted
    mood.tooltip=story.key_tooltip(player,"chapter-mood",quest.chapter)
  end
  local folio_link=panel.add{type="label",style="clickable_label",
    caption=L("chapter-cover-open"),
    tags={razi_journal_action="chapter-dossier",id=quest.chapter},
    tooltip=L("chapter-cover-tooltip")}
  folio_link.style.font_color=theme.soft
  accent_rule(panel,theme,math.min(92,inner),2)
  -- Dossier actions now scroll with the reading sheet, instead of
  -- permanently stealing vertical space at small resolutions.
  local content_height=size.body-(size.compact and 124 or 148)
  local scroll=wheel_pane(panel,"razi_journal_reading",inner,content_height)
  local text_width=inner-18
  local prose=scroll.add{type="flow",name="razi_journal_prose",direction="vertical"}
  prose.style.width=text_width
  prose.style.vertical_spacing=9
  local native=technology(player.force,quest,context)
  local force=player.force
  -- Read each milestone through the same native state as the index. No
  -- artificial crafting counters, discovered worlds or stored completion.
  local plan=objectives.snapshot(quest,native,status,{
    available=function(id)
      local required=defs.by_id[id]
      return required and M.available(force,required,context) or false
    end,
    visible=function(id)
      local required=defs.by_id[id]
      return required and M.journal_visible(force,required,context) or false
    end,
    complete=function(id)
      local required=defs.by_id[id]
      return required and M.complete(force,required,context) or false
    end,
    tech_for_quest=function(id)
      local required=defs.by_id[id]
      -- World objectives may use an alternate source technology in the
      -- installed modpack. Do not guess that technology from a world ID.
      local source=required and not (required.world or required.boss or
        required.convergence) and technology(force,required,context)
      return source and source.name or nil
    end,
    quest_for_tech=function(name)
      for _,candidate in ipairs(quests_for_technology[name] or {}) do
        if M.journal_visible(force,candidate,context) then
          return candidate.id
        end
      end
    end,
    title_for_quest=function(id)
      local required=defs.by_id[id]
      return required and defs.quest_title(required,player)
    end,
    current_research=force.current_research,
    research_progress=force.research_progress
  })
  local mission=prose.add{type="frame",name="razi_journal_mission_plan",
    direction="vertical",style="razi_journal_callout"}
  mission.style.width=text_width
  mission.style.padding=size.compact and 8 or 10
  local mission_header=mission.add{type="flow",direction="horizontal"}
  mission_header.style.horizontal_spacing=8
  mission_header.style.vertical_align="center"
  local mission_heading=label(mission_header,L("mission-plan"))
  mission_heading.style.font="default-bold"
  mission_heading.style.font_color=theme.soft
  local mission_space=mission_header.add{type="empty-widget"}
  mission_space.style.horizontally_stretchable=true
  if plan.requirements>0 then
    local count=label(mission_header,L("mission-stage-count",
      tostring(plan.satisfied),tostring(plan.requirements)))
    count.style.font_color=COLOR.muted
  end
  -- Always display the *actual* success criterion, even if a
  -- long blocker list collapses below the first three pending steps.
  local finish=wrap(mission,L("mission-finish-line",
    L("mission-step-"..plan.kind,plan.target)),text_width-28)
  finish.style.font_color=COLOR.muted
  -- The top line is always the next verifiable action, never a made-up
  -- logistical task. For bosses and deliveries the source owns the result.
  if plan.finished then
    local done=wrap(mission,L("mission-complete"),text_width-28)
    done.style.font_color=COLOR.green
  elseif plan.next_step then
    local step=plan.next_step
    local key=step.kind=="goal" and plan.kind or step.kind
    local next_caption=L("mission-next",
      L("mission-step-"..key,step.name))
    local action
    if step.link then
      action=mission.add{type="label",style="clickable_label",
        caption=next_caption,tooltip=L("open-prerequisite"),
        tags={razi_journal_action="guidance-select",id=step.link}}
      action.style.single_line=false
      action.style.maximal_width=text_width-28
    else
      action=wrap(mission,next_caption,text_width-28)
    end
    action.style.font="default-bold"
    action.style.font_color=COLOR.ink
  end
  if plan.requirements>0 then
    local readiness=mission.add{type="progressbar",
      value=plan.satisfied/plan.requirements}
    readiness.style.width=math.min(245,text_width-34)
    readiness.style.height=3
    readiness.style.color=theme.primary
  end
  if plan.disabled and not plan.finished then
    local warning=wrap(mission,L("mission-disabled"),text_width-28)
    warning.style.font_color=COLOR.amber
  end
  -- Allocate this tiny research strip once; a 120-tick reader-only
  -- update keeps it alive without resetting the dossier scroll position.
  local research_row=mission.add{type="flow",name="razi_journal_research_row",
    direction="vertical"}
  research_row.style.vertical_spacing=3
  research_row.visible=plan.research_percent~=nil
  local running=research_row.add{type="label",
    name="razi_journal_research_percent",
    caption=L("mission-research-progress",
      tostring(plan.research_percent or 0))}
  running.style.font_color=COLOR.teal
  local research_bar=research_row.add{type="progressbar",
    name="razi_journal_research_progress",
    value=(plan.research_percent or 0)/100}
  research_bar.style.width=math.min(240,text_width-32)
  research_bar.style.height=4
  research_bar.style.color=COLOR.teal
  -- Next Action and Success Condition are already visible above these rows.
  -- An expanded checklist belongs to one dossier, not every quest the
  -- player visits afterward.
  local goal_expanded=p.goal_expanded and p.goal_expanded_quest==quest.id
  local shown=objectives.visible_rows(plan,goal_expanded,
    size.compact and 1 or 2)
  local checklist=mission.add{type="flow",direction="vertical"}
  checklist.style.vertical_spacing=4
  for _,row in ipairs(shown) do
    local item=checklist.add{type="flow",direction="horizontal"}
    item.style.horizontal_spacing=8
    item.style.vertical_align="center"
    local marker=label(item,row.done and marks.done or marks.pending)
    marker.style.font_color=row.done and COLOR.green
      or row.kind=="goal" and theme.primary or COLOR.amber
    marker.tooltip=L(row.done and "mission-goal-status-done"
      or "mission-goal-status-open")
    local kind=row.kind=="goal" and plan.kind or row.kind
    local caption=L("mission-step-"..kind,row.name)
    if row.link then
      local link=item.add{type="label",style="clickable_label",
        caption=caption,tooltip=L("open-prerequisite"),
        tags={razi_journal_action="guidance-select",id=row.link}}
      link.style.single_line=false
      link.style.maximal_width=text_width-64
      link.style.font_color=row.done and COLOR.muted or COLOR.ink
    else
      local note=wrap(item,caption,text_width-64)
      note.style.font_color=row.done and COLOR.muted or COLOR.ink
    end
  end
  if goal_expanded or #plan.rows>1 then
    local toggle=mission.add{type="label",style="clickable_label",
      caption=L(goal_expanded and "mission-collapse" or "mission-expand",
        tostring(#plan.rows)),
      tags={razi_journal_action="mission-details",id=quest.id}}
    toggle.style.font_color=theme.soft
  end
  -- A journal is primarily a story. After the live objective and its
  -- immediate blockers, let the player read the entry before secondary
  -- route previews, industry notes or production analytics.
  if story.visible(player) then
    section(prose,"story-heading",story.text(player,"quest-story",quest.id,
      {"journal-story."..quest.id}),text_width,theme,
      story.key_tooltip(player,"quest-story",quest.id))
  end
  -- Direct campaign handoffs share the force snapshot with the chapter rail.
  local next_steps=guidance.followups(quest.id,view and view.states,3)
  if #next_steps>0 then
    local forecast=prose.add{type="flow",direction="vertical"}
    forecast.style.width=text_width
    forecast.style.vertical_spacing=4
    dossier_heading(forecast,"next-steps-heading",theme,text_width)
    for _,step in ipairs(next_steps) do
      local line=forecast.add{type="flow",direction="horizontal"}
      line.style.horizontal_spacing=8
      icons.sprite(line,quest_art(player.force,step.quest,context),"quest_row")
      local note=line.add{type="flow",direction="vertical"}
      note.style.vertical_spacing=1
      local link=note.add{type="label",style="clickable_label",
        caption=defs.quest_title(step.quest,player),
        tags={razi_journal_action="guidance-select",id=step.quest.id}}
      link.style.single_line=false
      link.style.maximal_width=text_width-80
      if step.state~="complete" then
        tint(wrap(note,L("next-step-"..step.state),text_width-80),theme.soft)
      end
    end
  end
  if quest.convergence or quest.id=="convergence-commission"
    or quest.id=="convergence-synchronization" then
    local bridge=prose.add{type="flow",direction="vertical"}
    bridge.style.width=text_width
    bridge.style.vertical_spacing=4
    wrap(bridge,L("convergence-codex-description"),text_width-26)
    bridge.add{type="button",caption=L("convergence-codex-open"),
      tags={razi_journal_action="open-convergence",id=quest.id}}
  end
  -- Source-backed operational context; not an extra research requirement.
  local brief=industrial_briefs.for_quest(quest)
  if brief and story.visible(player) then
    section(prose,"industrial-brief-heading",
      story.text(player,"quest-brief",brief,
        {"razi-industries-brief."..brief}),text_width,theme,
      story.key_tooltip(player,"quest-brief",brief))
  end
  -- Field assignments are advisory, not research, physical exploration or
  -- shipment completion. Follow-ups must be actual, spoiler-visible Codex IDs.
  -- Only the charter text is story; the follow-up milestones, the project
  -- button and the advisory line are navigation and always shown.
  local charter=industrial_briefs.charter_for_quest(quest)
  if charter then
    local handoffs=industrial_briefs.visible_related(quest,defs.by_id,
      function(target)
        return M.journal_visible(force,target,context)
      end,2)
    -- Real build/travel/delivery tasks live in Projects, where physical
    -- evidence is verified. Only show a supported, spoiler-visible project.
    local project=industrial_briefs.project_for_quest(quest)
    if not (project and projects.visible(force,project)) then project=nil end
    if story.visible(player) or #handoffs>0 or project then
      local field=prose.add{type="flow",direction="vertical"}
      field.style.width=text_width
      field.style.vertical_spacing=5
      subtitle(field,"field-assignment-heading",text_width-26,theme)
      if story.visible(player) then
        local charter_text=wrap(field,story.text(player,"quest-charter",charter,
          {"razi-planet-charter."..charter}),text_width-26)
        charter_text.tooltip=story.key_tooltip(player,"quest-charter",charter)
      end
      if #handoffs>0 then
        local heading=wrap(field,L("field-assignment-followups"),
          ---@diagnostic disable-next-line: redundant-parameter
          text_width-26,true)
        heading.style.font_color=theme.soft
        for _,target in ipairs(handoffs) do
          local state=M.state(force,target,context)
          local next_link=field.add{type="label",style="clickable_label",
            caption={"",defs.quest_title(target,player),"  /  ",
              L("next-step-"..state)},
            tooltip=L("open-prerequisite"),
            tags={razi_journal_action="guidance-select",id=target.id}}
          next_link.style.single_line=false
          next_link.style.maximal_width=text_width-26
          next_link.style.font_color=state=="complete" and COLOR.green
            or theme.soft
        end
      end
      if project then
        local jump=field.add{type="button",
          caption=L("field-assignment-project"),
          tooltip=L("field-assignment-project-help"),
          tags={razi_journal_action="field-project",id=project}}
        jump.style.font_color=theme.soft
      end
      local advice=wrap(field,L("field-assignment-advisory"),text_width-26)
      advice.style.font_color=COLOR.quiet
    end
  end
  -- Existing Vespera dossiers can discuss actually configured neighboring
  -- lanes. The shared snapshot hides undiscovered neighbors when spoiler
  -- protection is ON; no invented shipment or catapult-building state.
  if charter then
    local network=catapults.snapshot(player.force)
    if network.installed and network.enabled then
      local local_lanes=catapults.for_world(network,quest.id)
      if #local_lanes>0 then
        local lanes=prose.add{type="flow",direction="vertical"}
        lanes.style.width=text_width
        lanes.style.vertical_spacing=4
        subtitle(lanes,"catapult-local-heading",text_width-26,theme)
        for _,link in ipairs(local_lanes) do
          local neighbor=link.source==quest.id and link.target or link.source
          local world=prototypes and prototypes.space_location
            and prototypes.space_location[neighbor]
          wrap(lanes,L("catapult-local-neighbor",
            world and world.localised_name or neighbor,
            L(link.state=="researched" and "catapult-local-surveyed"
              or "catapult-local-pending")),text_width-26)
        end
        tint(wrap(lanes,L("catapult-local-note"),text_width-26),theme.soft)
      end
    end
  end
  -- Field notes are authored text: story layer only.
  if story.visible(player) then
    section(prose,"tip-heading",story.text(player,"quest-tip",quest.id,
      {"journal-tip."..quest.id}),text_width,theme,
      story.key_tooltip(player,"quest-tip",quest.id))
  end
  -- The human accounts are useful where their actual milestone was
  -- completed, not just buried in the Archive's growing collection.
  -- No link or future title is shown before source quest completion.
  if M.complete(player.force,quest,context) then
    for _,record in ipairs(story.records(player)) do
      if record.series=="field" and record.unlock==quest.id then
        local letter=prose.add{type="flow",direction="vertical"}
        letter.style.vertical_spacing=5
        subtitle(letter,"field-citation-heading",text_width-26,theme)
        local button=letter.add{type="button",
          caption=record_title(player,record.id),
          tooltip=L("field-citation-tooltip"),
          tags={razi_journal_action="record",id=record.id}}
        button.style.minimal_width=math.min(210,text_width-26)
        break
      end
    end
  end
  -- Research costs and unlocks belong to Factorio's technology screen.
  -- The Journal keeps only the practical, source-backed workshop diagram.
  if native then
    recipe_gallery(prose,quest,native,text_width,theme)
  end
  local forecast=weather.for_quest(quest)
  if forecast then
    local sky=section(prose,"weather-heading",
      {"journal-weather."..forecast.world},text_width,theme)
    tint(wrap(sky,L(forecast.enabled and "weather-active"
      or "weather-inactive"),text_width),
      forecast.enabled and {r=.54,g=.85,b=.75} or {r=.72,g=.74,b=.79})
  end

  -- Never let the long Nexus and pin actions overflow narrow readers.
  local actions=prose.add{type="table",name="razi_journal_actions",
    column_count=text_width<350 and 1 or text_width<640 and 2 or 4}
  actions.style.horizontal_spacing=8
  actions.style.vertical_spacing=6
  if quest.boss then
    actions.add{type="button",caption=L("nexus-open-codex"),
      tags={razi_journal_action="nexus-codex",id=quest.boss}}
  end
  local pinned=p.tracker and p.pinned==quest.id
  actions.add{type="button",style="razi_journal_action_button",
    name="razi_journal_pin_button",caption=L(pinned
    and "tracker-hide" or "tracker-show"),
    tags={razi_journal_action="pin",id=quest.id}}
  actions.add{type="button",style="razi_journal_action_button",
    caption=L("previous-in-chapter"),
    tags={razi_journal_action="previous-in-chapter"}}
  actions.add{type="button",style="razi_journal_action_button",
    caption=L("next-in-chapter"),
    tags={razi_journal_action="next-in-chapter"}}
end

return render_details
