-- Source-backed mission checklist; never adds progression state or invented goals.
-- The Journal passes the SAME force research and campaign snapshot as its
-- existing objective evaluation. No remote calls, world scans or storage.
local M={}

local function sorted_prerequisites(technology)
  local result={}
  for _,tech in pairs(technology and technology.prerequisites or {}) do
    if tech and tech.name then result[#result+1]=tech end
  end
  table.sort(result,function(a,b) return a.name<b.name end)
  return result
end

-- Evaluation options:
--  available(id): true when that Codex prerequisite exists in this pack
--  complete(id): authoritative campaign completion
--  visible(id): spoiler-safe prerequisite can be named or linked
--  quest_for_tech(name): spoiler-safe visible Codex quest ID, if any
--  current_research, research_progress: optional native Force research state
function M.snapshot(quest,technology,status,options)
  options=options or {}
  local rows={}
  local requirements=0
  local satisfied=0
  local seen={}
  local native_covered_by_campaign={}
  local function add(kind,id,name,done,link)
    local row={kind=kind,id=id,name=name,done=done==true,link=link}
    rows[#rows+1]=row
    if kind~="goal" then
      requirements=requirements+1
      if row.done then satisfied=satisfied+1 end
    end
  end
  for _,id in ipairs(quest.requires or {}) do
    if not seen[id] and (not options.available or options.available(id))
      and (not options.visible or options.visible(id)) then
      seen[id]=true
      local tech_name=options.tech_for_quest and options.tech_for_quest(id)
      if tech_name then native_covered_by_campaign[tech_name]=true end
      add("campaign",id,{"journal-title."..id},
        options.complete and options.complete(id),id)
    end
  end
  -- Boss defeats and physical Convergence mandates are not a fake
  -- ForceTechnology completion. Their final row follows the real source.
  if not quest.boss and not quest.convergence then
    for _,tech in ipairs(sorted_prerequisites(technology)) do
      if not native_covered_by_campaign[tech.name] then
        local link=options.quest_for_tech and
          options.quest_for_tech(tech.name) or nil
        add("research",tech.name,tech.localised_name or tech.name,
          tech.researched,link)
      end
    end
  end
  local kind=quest.boss and "boss" or quest.convergence and
    (quest.convergence=="victory" and "transmission" or "delivery")
    or quest.world and "discovery" or "research"
  local target
  if quest.boss then
    target={"nexus-bosses.boss-"..quest.boss}
  elseif quest.convergence then
    target={"journal-title."..quest.id}
  else
    target=technology and technology.localised_name
      or quest.world or quest.tech or quest.id
  end
  add("goal",quest.id,target,status=="complete",nil)
  local next_step
  for _,row in ipairs(rows) do
    if not row.done then next_step=row;break end
  end
  local current=options.current_research
  local percent
  if current and technology and current.name==technology.name
    and not technology.researched and type(options.research_progress)=="number" then
    ---@diagnostic disable-next-line: assign-type-mismatch
    local value=math.max(0,math.min(1,options.research_progress))
    percent=math.floor(value*100+.5)
  end
  return {
    rows=rows,kind=kind,target=target,requirements=requirements,
    satisfied=satisfied,next_step=next_step,finished=status=="complete",
    disabled=technology and technology.enabled==false
      and not technology.researched and status~="complete" or false,
    research_percent=percent,
    has_more=#rows>4,
  }
end

-- The summary already displays the next action and final success
-- condition above the checklist. Show OTHER unfinished steps here; never
-- repeat the first blocker or clutter a completed dossier with checked rows.
-- Expanded lists always contain the complete, source-backed history.
function M.visible_rows(plan,expanded,limit)
  if expanded then return plan.rows end
  local result={}
  if plan.finished then return result end
  local max=math.max(0,limit or 2)
  for _,row in ipairs(plan.rows) do
    if not row.done and row~=plan.next_step and #result<max then
      result[#result+1]=row
    end
  end
  return result
end

return M
