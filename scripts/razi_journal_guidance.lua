-- Deterministic research guidance. No mutable storage or recipe scans.
-- The caller supplies the Codex's existing research/quest snapshot.
local M={}
local data=require("scripts.razi_journal_data")
local dependents,downstream={},{}
for _,quest in ipairs(data.quests) do
  for _,required in ipairs(quest.requires or {}) do
    dependents[required]=(dependents[required] or 0)+1
    local list=downstream[required]
    if not list then list={} downstream[required]=list end
    list[#list+1]=quest
  end
end

-- Show direct Codex handoffs; real ForceTechnology still decides unlocks.
function M.followups(id,states,limit)
  local current=data.by_id[id]
  local ranked={}
  local order={active=1,locked=2,complete=3}
  for _,quest in ipairs(downstream[id] or {}) do
    local state=states and states[quest.id]
    if order[state] then
      ranked[#ranked+1]={quest=quest,state=state,
        cross=current and quest.chapter~=current.chapter or false}
    end
  end
  table.sort(ranked,function(a,b)
    if order[a.state]~=order[b.state] then
      return order[a.state]<order[b.state]
    end
    if a.cross~=b.cross then return a.cross end
    return a.quest.id<b.quest.id
  end)
  local result={}
  for i=1,math.min(math.max(0,limit or 3),#ranked) do
    result[#result+1]=ranked[i]
  end
  return result
end
local function frontier(quest)
  if quest.world then return true end
  local name=quest.tech or ""
  return name:find("discovery",1,true)~=nil
    or name:find("survey",1,true)~=nil
    or quest.id:find("gate",1,true)~=nil
end
local function research_blockers(tech)
  local blockers={}
  if not tech then return blockers end
  for _,prior in pairs(tech.prerequisites or {}) do
    if not prior.researched then blockers[#blockers+1]=prior end
  end
  table.sort(blockers,function(a,b) return a.name<b.name end)
  return blockers
end
local function quest_blockers(quest,states)
  local blockers={}
  for _,required in ipairs(quest.requires or {}) do
    local state=states[required]
    if state and state~="complete" and state~="unavailable" then
      blockers[#blockers+1]=required
    end
  end
  return blockers
end
local function score(quest)
  return (frontier(quest) and 18 or 0)
    +(quest.site and 9 or 0)
    +math.min(24,(dependents[quest.id] or 0)*5)
    -- Industry is worth showing, but never outranks ready story research.
    -(quest.optional and 36 or 0)
end
local function ordered(a,b)
  if a.score~=b.score then return a.score>b.score end
  return a.order<b.order
end
function M.plan(states,lookup)
  local ready,delayed,upcoming={},{},{}
  for order,quest in ipairs(data.quests) do
    local state=states[quest.id]
    if state and state~="unavailable" and state~="complete"
      and not quest.boss then
      local tech=lookup(quest)
      if tech then
        local entry={quest=quest,tech=tech,score=score(quest),
          order=order,chapter=quest.chapter}
        if state=="active" then
          entry.tech_blockers=research_blockers(tech)
          entry.disabled=tech.enabled==false
          if not entry.disabled and #entry.tech_blockers==0 then
            entry.kind="ready"
            ready[#ready+1]=entry
          else
            entry.kind="research-blocked"
            delayed[#delayed+1]=entry
          end
        elseif state=="locked" then
          entry.quest_blockers=quest_blockers(quest,states)
          if #entry.quest_blockers>0 then
            -- A one-step goal whose missing quest is already active is
            -- nearer than a frontier depending on several locked quests.
            entry.distant=0
            for _,required in ipairs(entry.quest_blockers) do
              if states[required]~="active" then
                entry.distant=entry.distant+1
              end
            end
            table.sort(entry.quest_blockers,function(left,right)
              if states[left]~=states[right] then
                return states[left]=="active"
              end
              return false
            end)
            entry.kind="campaign-blocked"
            upcoming[#upcoming+1]=entry
          end
        end
      end
    end
  end
  table.sort(ready,ordered)
  table.sort(delayed,function(a,b)
    if a.disabled~=b.disabled then return not a.disabled end
    if #a.tech_blockers~=#b.tech_blockers then
      return #a.tech_blockers<#b.tech_blockers end
    return ordered(a,b)
  end)
  table.sort(upcoming,function(a,b)
    if a.distant~=b.distant then return a.distant<b.distant end
    if #a.quest_blockers~=#b.quest_blockers then
      return #a.quest_blockers<#b.quest_blockers end
    return ordered(a,b)
  end)
  local selected,seen={},{}
  -- One priority per chapter first, so two active star systems remain
  -- represented instead of crowding each other out of the navigator.
  for _,entry in ipairs(ready) do
    if not seen[entry.chapter] and #selected<3 then
      selected[#selected+1]=entry
      seen[entry.chapter]=true
    end
  end
  if #selected<3 then
    for _,entry in ipairs(ready) do
      local present=false
      for _,chosen in ipairs(selected) do
        if chosen.quest.id==entry.quest.id then present=true;break end
      end
      if not present then selected[#selected+1]=entry end
      if #selected>=3 then break end
    end
  end
  local blocker
  -- Prefer near-term frontier research; never confuse a campaign story
  -- step with an actual native research prerequisite.
  for _,entry in ipairs(delayed) do
    if frontier(entry.quest) then blocker=entry;break end
  end
  if not blocker then
    for _,entry in ipairs(upcoming) do
      if frontier(entry.quest) then blocker=entry;break end
    end
  end
  blocker=blocker or delayed[1] or upcoming[1]
  return {primary=selected[1],alternatives={
    selected[2],selected[3]},blocker=blocker,
    ready_count=#ready,delayed_count=#delayed,
    selected=selected}
end
return M
