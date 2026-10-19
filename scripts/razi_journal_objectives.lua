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
      add("campaign",id,{"journal-title."..id},
        options.complete and options.complete(id),id)
    end
  end
  -- Boss defeats and physical Convergence mandates are not a fake
  -- ForceTechnology completion. Their final row follows the real source.
  if not quest.boss and not quest.convergence then
    for _,tech in ipairs(sorted_prerequisites(technology)) do
      local link=options.quest_for_tech and
        options.quest_for_tech(tech.name) or nil
      add("research",tech.name,tech.localised_name or tech.name,
        tech.researched,link)
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

-- A short view puts blockers FIRST and always includes the final target
-- when no unmet prerequisite remains. Expanded lists show every stage,
-- including achieved steps, in their original authoritative order.
function M.visible_rows(plan,expanded,limit)
  if expanded then return plan.rows end
  local max=limit or 3
  local result={}
  for _,row in ipairs(plan.rows) do
    if not row.done and #result<max then result[#result+1]=row end
  end
  if #result==0 then
    for _,row in ipairs(plan.rows) do
      if #result>=max then break end
      result[#result+1]=row
    end
  end
  return result
end

return M
