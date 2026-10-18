-- RAZI Industries correspondence. Research and real physical shipments
-- queue archival notices. No recurring world scans, alerts on save load,
-- or invented quest completion. Batched research sends ONE concise notice.
local M={}
local definitions=require("scripts.razi_journal_data")
local records=require("scripts.razi_journal_corporate")
local by_id={}
for _,record in ipairs(records) do by_id[record.id]=record end
local by_research={}
local by_world={}
local physical={
  stellar="corp-shipment-stellar",industry="corp-shipment-industry",
  ["deep-space"]="corp-shipment-deep",resonance="corp-shipment-resonance",
  ignition="corp-shipment-ignition",victory="corp-epilogue"
}
for _,record in ipairs(records) do
  local quest=definitions.by_id[record.unlock]
  if quest and not quest.convergence then
    if quest.world then
      local list=by_world[quest.world] or {}
      list[#list+1]=record.id
      by_world[quest.world]=list
    elseif quest.tech then
      local list=by_research[quest.tech] or {}
      list[#list+1]=record.id
      by_research[quest.tech]=list
    end
  end
end
local function sent()
  storage.razi_story_sent=storage.razi_story_sent or {}
  return storage.razi_story_sent
end
local function unread(player,id)
  local settings=storage.razi_expedition_journal
  if not settings then
    settings={}
    storage.razi_expedition_journal=settings
  end
  local p=settings[player.index]
  if not p then
    p={};settings[player.index]=p
  end
  p.story_unread=p.story_unread or {}
  p.story_unread[id]=true
  return p.story_alerts~=false
end
local function announce(force,ids)
  if not force or #ids==0 then return end
  local seen=sent()
  local announced=seen[force.index] or {}
  seen[force.index]=announced
  local new={}
  for _,id in ipairs(ids) do
    if not announced[id] then
      announced[id]=true
      new[#new+1]=id
    end
  end
  if #new==0 then return end
  for _,player in pairs(force.connected_players or {}) do
    local enabled=false
    for _,id in ipairs(new) do
      if unread(player,id) then enabled=true end
    end
    if enabled and player.print then
      if #new==1 then
        local record=by_id[new[1]]
        local key="record-unlocked"
        if record and record.series=="field" then
          key="field-unlocked"
        elseif new[1]:sub(1,14)=="corp-shipment-"
          or new[1]=="corp-epilogue" then
          key="mandate-unlocked"
        end
        player.print({"razi-story."..key,
          {"journal-record-title."..new[1]}})
      else
        player.print({"razi-story.records-unlocked",tostring(#new)})
      end
    end
  end
end
function M.on_research(event)
  local tech=event and event.research
  local force=tech and tech.force
  local matches={}
  if tech then
    for _,id in ipairs(by_research[tech.name] or {}) do
      matches[#matches+1]=id
    end
    for _,effect in pairs(tech.prototype and tech.prototype.effects or {}) do
      if effect.type=="unlock-space-location" then
        for _,id in ipairs(by_world[effect.space_location] or {}) do
          matches[#matches+1]=id
        end
      end
    end
  end
  if not (force and #matches>0) then return end
  local queue=storage.razi_story_pending or {}
  storage.razi_story_pending=queue
  local state=queue[force.index]
  if not state then
    state={ids={},order={}}
    queue[force.index]=state
  end
  for _,id in ipairs(matches) do
    if not state.ids[id] then
      state.ids[id]=true
      state.order[#state.order+1]=id
    end
  end
  state.last_tick=game and game.tick or 0
end
-- Reuse the Journal's existing 30-tick callback. Wait 2 seconds of quiet
-- so research-all and multi-completion events never flood the chat.
function M.flush()
  local queue=storage.razi_story_pending
  if not queue then return end
  local tick=game and game.tick or 0
  for index,state in pairs(queue) do
    if tick-(state.last_tick or 0)>=120 then
      local force=game and game.forces and game.forces[index]
      if force then announce(force,state.order or {}) end
      queue[index]=nil
    end
  end
  if not next(queue) then storage.razi_story_pending=nil end
end
function M.shipment(force,id)
  local record=physical[id]
  if record and force then announce(force,{record}) end
end
function M.forces_merged(event)
  local source=event and event.source_index
  local target=event and (event.destination and event.destination.index
    or event.destination_index)
  if not (source and target and source~=target) then return end
  local seen=storage.razi_story_sent
  if seen then
    seen[target]=seen[target] or {}
    for id in pairs(seen[source] or {}) do seen[target][id]=true end
    seen[source]=nil
  end
  local queue=storage.razi_story_pending
  if queue and queue[source] then
    local dest=queue[target] or {ids={},order={}}
    for _,id in ipairs(queue[source].order or {}) do
      if not dest.ids[id] then
        dest.ids[id]=true
        dest.order[#dest.order+1]=id
      end
    end
    dest.last_tick=math.max(dest.last_tick or 0,
      queue[source].last_tick or 0)
    queue[target]=dest
    queue[source]=nil
  end
end
return M
