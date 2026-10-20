-- Immutable first-clear times for each force's expedition chapters and
-- four Calidus acts. A false timestamp means cleared on a legacy save.
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
    record={chapters={},phases={}}
    all[force.index]=record
  end
  return record
end

function M.get(force,kind,id)
  local row=records(force,false)
  return row and row[kind] and row[kind][id]
end

function M.mark(force,kind,id,tick,historical)
  if kind~="chapters" and kind~="phases" then return false end
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
function M.observe(force,quests,available,complete,historical,tick)
  local chapters,phases={},{}
  for _,quest in ipairs(quests) do
    if not quest.optional and available(quest) then
      local chapter=chapters[quest.chapter] or {total=0,done=0}
      chapters[quest.chapter]=chapter
      chapter.total=chapter.total+1
      local act
      if quest.chapter=="calidus" and quest.phase then
        act=phases[quest.phase] or {total=0,done=0}
        phases[quest.phase]=act
        act.total=act.total+1
      end
      if complete(quest) then
        chapter.done=chapter.done+1
        if act then act.done=act.done+1 end
      end
    end
  end
  local changed=false
  for _,kind in ipairs({"chapters","phases"}) do
    local buckets=kind=="chapters" and chapters or phases
    for id,state in pairs(buckets) do
      if state.total>0 and state.total==state.done
        and M.mark(force,kind,id,tick,historical) then
        changed=true
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
  local into=all[target] or {chapters={},phases={}}
  for _,kind in ipairs({"chapters","phases"}) do
    into[kind]=into[kind] or {}
    for id,tick in pairs(from[kind] or {}) do
      into[kind][id]=earliest(into[kind][id],tick)
    end
  end
  all[target]=into
  all[source]=nil
end
return M
