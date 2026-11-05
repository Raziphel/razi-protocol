-- Immutable first-clear times for missions, all authored acts and chapters.
-- The historic 'phases' storage key remains compatible with older saves.
local M={}
local KEY="razi_chapter_completion_times"

local function records(force,create)
  local all=storage and storage[KEY]
  if not all and create then
    all={}
    storage[KEY]=all
  end
  if not (all and force and force.index) then return nil end
  local record=all[force.index]
  if not record and create then
    record={chapters={},phases={},milestones={}}
    all[force.index]=record
  end
  return record
end

function M.get(force,kind,id)
  local row=records(force,false)
  return row and row[kind] and row[kind][id]
end

function M.mark(force,kind,id,tick,historical)
  if kind~="chapters" and kind~="phases" and kind~="milestones" then return false end
  local row=records(force,true)
  if not row then return false end
  row[kind]=row[kind] or {}
  if row[kind][id]~=nil then return false end
  row[kind][id]=historical and false or math.max(0,tick or 0)
  return true
end

function M.format(tick)
  if type(tick)~="number" then return nil end
  local seconds=math.floor(math.max(0,tick)/60)
  return string.format("%02d:%02d",math.floor(seconds/3600),
    math.floor(seconds%3600/60))
end

-- Source completion is authoritative. Spoiler-hidden research is still
-- counted; optional quests do not prevent a story chapter's first clear.
function M.observe(force,quests,available,complete,historical,tick,act_for)
  local chapters,acts={},{}
  local changed=false
  -- A completion previously earned in a 2.x/3.x save may already have a
  -- milestone timestamp. Only reconstruct a new chapter timestamp when ALL
  -- required milestones have genuine recorded times. Unknown history stays
  -- unknown; the save's older chapter keys are retained untouched.
  local function bucket(collection,id)
    if not collection[id] then
      collection[id]={total=0,done=0,required=0,done_required=0}
    end
    return collection[id]
  end
  local function add(group,quest,done,recorded)
    group.total=group.total+1
    if done then group.done=group.done+1 end
    if not quest.optional then
      group.required=group.required+1
      if done then group.done_required=group.done_required+1 end
    end
    if done then
      if type(recorded)=="number" then
        group.latest=math.max(group.latest or recorded,recorded)
        if not quest.optional then
          group.required_latest=math.max(group.required_latest or recorded,recorded)
        end
      else
        group.unknown=true
        if not quest.optional then group.required_unknown=true end
      end
    end
  end
  for _,quest in ipairs(quests) do
    if available(quest) then
      local done=complete(quest)
      if done and M.mark(force,"milestones",quest.id,tick,historical) then
        changed=true
      end
      local recorded=done and M.get(force,"milestones",quest.id) or nil
      add(bucket(chapters,quest.chapter),quest,done,recorded)
      local act_id=act_for and act_for(quest) or quest.phase
      if act_id then add(bucket(acts,act_id),quest,done,recorded) end
    end
  end
  local function finished(state)
    if state.required>0 then return state.done_required==state.required end
    return state.total>0 and state.done==state.total
  end
  local function historical_completion(state)
    if state.required>0 then
      return not state.required_unknown and state.required_latest or nil
    end
    return not state.unknown and state.latest or nil
  end
  -- "phases" remains the legacy storage key. Neither original act keys nor
  -- original chapter records are renamed to the new catalog identifiers.
  for _,kind in ipairs({"chapters","phases"}) do
    local buckets=kind=="chapters" and chapters or acts
    for id,state in pairs(buckets) do
      if finished(state) then
        local recorded=historical and historical_completion(state) or nil
        if M.mark(force,kind,id,recorded or tick,historical and recorded==nil) then
          changed=true
        end
      end
    end
  end
  return changed
end

local function earliest(a,b)
  -- Never replace a historic unknown with a misleading precise timestamp.
  if a==false or b==false then return false end
  if a==nil then return b end
  if b==nil then return a end
  return math.min(a,b)
end
function M.forces_merged(event)
  local all=storage and storage[KEY]
  local source=event and event.source_index
  local target=event and (event.destination and event.destination.index
    or event.destination_index)
  if not (all and source and target and source~=target and all[source]) then
    return
  end
  local from=all[source]
  local into=all[target] or {chapters={},phases={},milestones={}}
  for _,kind in ipairs({"chapters","phases","milestones"}) do
    into[kind]=into[kind] or {}
    for id,tick in pairs(from[kind] or {}) do
      into[kind][id]=earliest(into[kind][id],tick)
    end
  end
  all[target]=into
  all[source]=nil
end
return M
