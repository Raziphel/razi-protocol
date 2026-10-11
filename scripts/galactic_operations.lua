-- Galactic Operations: large-campaign planets and platform manager.
-- Read-only except for per-player pins. Uses real force/platform data;
-- no on_tick scans, no surface creation, no recipe/progression modifications.
local M={}
local catalog=require("scripts.galactic_catalog")
local atlas=require("scripts.galactic_atlas")
local fleet=require("scripts.galactic_fleet")
local FRAME="razi_galactic_operations"
local MAP_ANCHOR="razi_ops_map_anchor"
local MAP_BUTTON="razi_ops_map_button"
local MAP_SPRITE="razi-galactic-operations-map-icon"
-- The engine's native starmap header isn't a LuaGuiElement. This floating
-- entry appears while Remote View displays the chart, beside its controls.
-- It is never inserted into Factorio's quickbar or shortcut bar.
local PAGE_SIZE=22
local FILTERS={"all","favorites","active","attention","recent"}
local ROLES={"all","general","freighter","science","defense","exploration","construction"}
local ROLE_CHOICES={"auto","general","freighter","science","defense","exploration","construction"}
local function infer_role(name)
  local s=(name or ""):lower()
  if s:find("cargo",1,true) or s:find("freight",1,true)
    or s:find("hauler",1,true) then return "freighter" end
  if s:find("science",1,true) or s:find("research",1,true)
    or s:find("laboratory",1,true) then return "science" end
  if s:find("defense",1,true) or s:find("escort",1,true)
    or s:find("warship",1,true) or s:find("gunship",1,true) then
    return "defense"
  end
  if s:find("scout",1,true) or s:find("explor",1,true)
    or s:find("survey",1,true) then return "exploration" end
  if s:find("builder",1,true) or s:find("construct",1,true)
    then return "construction" end
  return "general"
end
local group_options={"all","calidus","solaris","nyxaris","vibrant","vespera","beetlejuice","umbra","deep-space","unassigned"}
local function L(key,...) return {"razi-ops."..key,...} end

local function preferences(index)
  storage.razigui=storage.razigui or {}
  local p=storage.razigui[index]
  if not p then
    p={tab="worlds",filter="all",group="all",search="",page=1,
       waypoints=false,locked=false,role_filter="all",roles={},favorites={worlds={},platforms={}},
       collapsed={},recent={},notes={},focus=nil,atlas_origin=nil,priority_sort=false}
    storage.razigui[index]=p
  end
  p.favorites=p.favorites or {worlds={},platforms={}}
  p.favorites.worlds=p.favorites.worlds or {}
  p.favorites.platforms=p.favorites.platforms or {}
  p.collapsed=p.collapsed or {}
  p.recent=p.recent or {}
  p.notes=p.notes or {}
  p.roles=p.roles or {}
  p.role_filter=p.role_filter or "all"
  p.priority_sort=p.priority_sort or false
  return p
end
local function is_unlocked(force,name)
  return force.is_space_location_unlocked(name)
end
local function has_surface(name)
  local planet=game.planets[name]
  return planet and planet.valid and planet.surface and planet.surface.valid
end
local function valid_platform(p)
  return p and p.valid and not p.hidden and p.scheduled_for_deletion==0
end
local function platform_status(p)
  if p.paused then return "paused" end
  if p.space_connection then return "transit" end
  if not p.hub or not p.hub.valid then return "building" end
  local schedule=p.schedule
  if not schedule or not schedule.records or #schedule.records==0 then
    return "unscheduled"
  end
  return "orbit"
end
local function platform_group(p)
  local loc=p.space_location or p.last_visited_space_location
  return catalog.system(loc and loc.name or "")
end

-- Pure selection/pagination helper: fixture-tested without Factorio.
function M.page_slice(rows,page,size)
  local pages=math.max(1,math.ceil(#rows/size))
  page=math.min(math.max(page,1),pages)
  local first=(page-1)*size+1
  local output={}
  for i=first,math.min(#rows,first+size-1) do
    output[#output+1]=rows[i]
  end
  return output,page,pages
end

local function collect_worlds(player,p)
  local entries={}
  local force=player.force
  for name,proto in pairs(prototypes.space_location) do
    if not proto.hidden and (proto.type=="planet" or p.waypoints) then
      local unlocked=is_unlocked(force,name)
      if unlocked or p.locked then
        local accessible=unlocked and has_surface(name) or false
        entries[#entries+1]={
          id=name,name=name,caption=proto.localised_name,
          kind="worlds",group=catalog.system(name),
          status=not unlocked and "locked" or accessible and "visited" or "unvisited",
          ready=accessible,unlocked=unlocked
        }
      end
    end
  end
  return entries
end
local function collect_platforms(player,p)
  local entries={}
  for index,platform in pairs(player.force.platforms) do
    if valid_platform(platform) then
      local diagnostics=fleet.snapshot(platform)
      entries[#entries+1]={
        id=tostring(index),index=index,name=platform.name,
        caption=platform.name,kind="platforms",
        group=platform_group(platform),status=platform_status(platform),
        ready=platform.surface and platform.surface.valid or false,
        location=platform.space_location or platform.last_visited_space_location,
        connection=platform.space_connection,
        role=p.roles[tostring(index)] or infer_role(platform.name),
        manual_role=p.roles[tostring(index)]~=nil,
        warnings=diagnostics.warning_count
      }
    end
  end
  return entries
end
local function recent_key(row)
  return row.kind..":"..row.id
end
local function is_recent(p,row)
  local key=recent_key(row)
  for _,entry in ipairs(p.recent) do
    if entry==key then return true end
  end
  return false
end
local function matches(p,row)
  if p.group~="all" and p.group~=row.group then return false end
  if row.kind=="platforms" and p.role_filter~="all"
    and p.role_filter~=row.role then return false end
  local text=p.search:lower()
  if text~="" then
    local name=(row.name or ""):lower()
    local group=row.group
    if not name:find(text,1,true) and not group:find(text,1,true) then
      return false
    end
  end
  if p.filter=="favorites" and not p.favorites[row.kind][row.id] then
    return false
  elseif p.filter=="active" then
    if row.kind=="worlds" and row.status~="visited" then return false end
    if row.kind=="platforms" and row.status~="transit" then return false end
  elseif p.filter=="attention" then
    if row.kind=="worlds" and row.status~="locked" then return false end
    if row.kind=="platforms" and (row.warnings or 0)==0 then return false end
  elseif p.filter=="recent" and not is_recent(p,row) then
    return false
  end
  return true
end
local function rows_for(player,p)
  local all=p.tab=="worlds" and collect_worlds(player,p) or collect_platforms(player,p)
  local filtered={}
  for _,row in ipairs(all) do
    if matches(p,row) then filtered[#filtered+1]=row end
  end
  table.sort(filtered,function(a,b)
    if p.priority_sort and a.kind=="platforms" and b.kind=="platforms"
      and a.warnings~=b.warnings then return a.warnings>b.warnings end
    local x,y=catalog.position(a.group),catalog.position(b.group)
    if x~=y then return x<y end
    local af,bf=p.favorites[a.kind][a.id],p.favorites[b.kind][b.id]
    if (not not af)~=(not not bf) then return not not af end
    if a.kind=="platforms" and b.kind=="platforms" and a.role~=b.role then
      return a.role<b.role
    end
    if a.name:lower()~=b.name:lower() then
      return a.name:lower()<b.name:lower()
    end
    return a.id<b.id
  end)
  return filtered,#all
end

local function add_button(parent,caption,action,value,tooltip)
  return parent.add{
    type="button",caption=caption,tooltip=tooltip,
    tags={razi_ops_action=action,value=value}
  }
end
local function accent(label,color)
  label.style.font_color=color
end
local function summary(player)
  local transit,attention,total=0,0,0
  for _,p in pairs(player.force.platforms) do
    if valid_platform(p) then
      total=total+1
      local state=platform_status(p)
      if state=="transit" then transit=transit+1 end
      if state=="paused" or state=="unscheduled" or state=="building" then
        attention=attention+1
      end
    end
  end
  return total,transit,attention
end
local function paint_row(parent,row,p)
  local band=parent.add{type="frame",direction="vertical",style="inside_shallow_frame"}
  band.style.horizontally_stretchable=true
  local line=band.add{type="flow",direction="horizontal"}
  line.style.vertical_align="center"
  local favorite=p.favorites[row.kind][row.id]
  add_button(line,favorite and "★" or "☆","favorite",
    recent_key(row),L("favorite-tooltip"))
  local title=line.add{type="label",caption=row.caption}
  title.style.font="default-bold"
  title.style.minimal_width=210
  local status=line.add{type="label",caption=L("status-"..row.status)}
  status.style.minimal_width=110
  if row.status=="paused" or row.status=="unscheduled" or row.status=="locked" then
    accent(status,{r=1,g=0.55,b=0.32})
  elseif row.status=="transit" or row.status=="visited" then
    accent(status,{r=0.35,g=0.84,b=0.62})
  end
  if row.kind=="platforms" then
    local place=line.add{type="label",caption=row.location
      and row.location.localised_name or L("between-worlds")}
    place.style.minimal_width=165
  else
    local place=line.add{type="label",caption=L("group-"..row.group)}
    place.style.minimal_width=165
  end
  if row.ready then
    add_button(line,L("view"),"view",recent_key(row),L("view-tooltip"))
  else
    local btn=add_button(line,L("no-view"),"not-available",
      recent_key(row),L("no-view-tooltip"))
    btn.enabled=false
  end
  add_button(line,L(row.kind=="worlds" and "atlas-open" or "fleet-open"),
    "details",recent_key(row),L("details-tooltip"))
  if row.kind=="platforms" then
    if (row.warnings or 0)>0 then
      local warning=band.add{type="label",
        caption=L("fleet-warnings",tostring(row.warnings))}
      accent(warning,{r=1,g=0.63,b=0.32})
    end
    local mission=band.add{type="flow",direction="horizontal"}
    mission.add{type="label",caption=L("mission")}
    local choice=mission.add{type="drop-down",
      name="razi_ops_role_"..row.id,
      items={L("role-auto"),L("role-general"),L("role-freighter"),
             L("role-science"),L("role-defense"),L("role-exploration"),
             L("role-construction")},
      tags={razi_ops_role_id=row.id}
    }
    local chosen=row.manual_role and row.role or "auto"
    for i,value in ipairs(ROLE_CHOICES) do
      if chosen==value then choice.selected_index=i;break end
    end
    mission.add{type="label",caption=L("role-"..row.role)}
    if row.connection then
      local detail=band.add{type="label",
        caption=L("flight-route",row.connection.from.localised_name,
          row.connection.to.localised_name)}
      accent(detail,{r=0.57,g=0.73,b=0.96})
    end
  end
end

local function redraw(player)
  local frame=player.gui.screen[FRAME]
  if not (frame and frame.valid) then return end
  local p=preferences(player.index)
  local body=frame.razi_ops_body
  if not (body and body.valid) then return end
  body.clear()
  local rows,total=rows_for(player,p)
  local page_rows,page,pages=M.page_slice(rows,p.page,PAGE_SIZE)
  p.page=page
  local total_platforms,traveling,warnings=summary(player)
  local stats=body.add{type="label",caption=L("overview",tostring(total),
    tostring(#rows),tostring(total_platforms),tostring(traveling),tostring(warnings))}
  accent(stats,{r=0.68,g=0.79,b=0.91})

  local list=body.add{type="scroll-pane",direction="vertical"}
  list.style.horizontally_stretchable=true
  list.style.height=math.max(210,math.min(420,
    math.floor(player.display_resolution.height/math.max(player.display_scale,1)*0.45)))
  if #page_rows==0 then
    list.add{type="label",caption=L("empty")}
  end
  local last_group=nil
  for _,row in ipairs(page_rows) do
    if row.group~=last_group then
      last_group=row.group
      local group_header=list.add{type="label",caption=L("group-"..row.group)}
      group_header.style.font="heading-2"
      accent(group_header,{r=0.46,g=0.77,b=0.96})
    end
    paint_row(list,row,p)
  end
  local footer=body.add{type="flow",direction="horizontal"}
  footer.style.vertical_align="center"
  local prev=add_button(footer,"◀","page",-1)
  prev.enabled=page>1
  footer.add{type="label",caption=L("pages",tostring(page),tostring(pages))}
  local next=add_button(footer,"▶","page",1)
  next.enabled=page<pages
  if p.focus then
    local kind,id=p.focus:match("^(worlds):(.+)$")
    if not kind then kind,id=p.focus:match("^(platforms):(.+)$") end
    if kind==p.tab and kind=="worlds" then
      atlas.render(body,player,id,p)
    elseif kind==p.tab and kind=="platforms" then
      local platform=player.force.platforms[tonumber(id)]
      fleet.render(body,platform,id,p)
    end
  end
end

local function close(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then frame.destroy() end
end

function M.in_map_view(player)
  return player and player.valid and player.connected
    and player.controller_type==defines.controllers.remote
    and player.render_mode~=defines.render_mode.game
end

local function position_map_button(player,anchor)
  local scale=math.max(player.display_scale,0.5)
  local width=math.floor(player.display_resolution.width/scale)
  -- Screen-root elements are on top of the map, NOT part of the shortcut bar.
  -- Leave the top-left native surface/planet selector unobstructed.
  anchor.location={x=math.max(8,width-244),y=86}
end

function M.sync_map_button(player)
  if not (player and player.valid) then return end
  local anchor=player.gui.screen[MAP_ANCHOR]
  if not M.in_map_view(player) then
    if anchor and anchor.valid then anchor.destroy() end
    if player.gui.screen[FRAME] then close(player) end
    return
  end
  if not (anchor and anchor.valid) then
    anchor=player.gui.screen.add{
      type="frame",name=MAP_ANCHOR,direction="horizontal"
    }
    local icon=anchor.add{
      type="sprite-button",name=MAP_BUTTON,
      sprite=MAP_SPRITE,style="slot_button",
      tooltip=L("map-button-tooltip"),
      tags={razi_ops_action="map-toggle"}
    }
    icon.style.width=38
    icon.style.height=38
    local text=anchor.add{
      type="button",caption=L("map-button"),
      tooltip=L("map-button-tooltip"),
      tags={razi_ops_action="map-toggle"}
    }
    text.style.font="default-bold"
    text.style.height=38
  end
  position_map_button(player,anchor)
end

function M.sync_all_map_buttons()
  for _,player in pairs(game.connected_players) do
    M.sync_map_button(player)
  end
end

function M.map_context_changed(event)
  local player=game.get_player(event.player_index)
  if player then M.sync_map_button(player) end
end
local function open(player)
  if player.gui.screen[FRAME] then return end
  local p=preferences(player.index)
  local resolution=player.display_resolution
  local scale=math.max(player.display_scale,1)
  local width=math.max(460,math.min(840,math.floor(resolution.width/scale)-70))
  local frame=player.gui.screen.add{
    type="frame",name=FRAME,direction="vertical",caption=L("title")
  }
  frame.style.width=width
  frame.location={x=math.max(0,math.floor((resolution.width/scale-width)/2)),
                  y=math.max(25,math.floor(resolution.height/scale*0.08))}
  local head=frame.add{type="flow",direction="horizontal"}
  head.style.horizontally_stretchable=true
  head.add{type="label",caption=L("subtitle")}
  local drag=head.add{type="empty-widget",style="draggable_space"}
  drag.style.horizontally_stretchable=true
  drag.style.height=28
  drag.drag_target=frame
  add_button(head,L("refresh"),"refresh","")
  add_button(head,"✕","close","")
  local tabs=frame.add{type="flow",direction="horizontal"}
  add_button(tabs,L("worlds-tab"),"tab","worlds")
  add_button(tabs,L("platforms-tab"),"tab","platforms")
  local search=frame.add{
    type="textfield",name="razi_ops_search",
    text=p.search,tooltip=L("search-tooltip")
  }
  search.style.horizontally_stretchable=true
  local filters=frame.add{type="flow",direction="horizontal"}
  filters.add{type="label",caption=L("filter")}
  local filter=filters.add{
    type="drop-down",name="razi_ops_filter",
    items={L("filter-all"),L("filter-favorites"),L("filter-active"),
           L("filter-attention"),L("filter-recent")}
  }
  for index,value in ipairs(FILTERS) do
    if value==p.filter then filter.selected_index=index end
  end
  filters.add{type="label",caption=L("system")}
  local groups={}
  for _,group in ipairs(group_options) do
    groups[#groups+1]=L("group-"..group)
  end
  local selector=filters.add{
    type="drop-down",name="razi_ops_group",items=groups
  }
  for index,value in ipairs(group_options) do
    if p.group==value then selector.selected_index=index end
  end
  local roles=frame.add{type="flow",name="razi_ops_roles",direction="horizontal"}
  roles.add{type="label",caption=L("mission-filter")}
  local role_filter=roles.add{type="drop-down",name="razi_ops_role_filter",
    items={L("role-all"),L("role-general"),L("role-freighter"),
           L("role-science"),L("role-defense"),L("role-exploration"),
           L("role-construction")}
  }
  for i,role in ipairs(ROLES) do
    if p.role_filter==role then role_filter.selected_index=i;break end
  end
  roles.visible=p.tab=="platforms"
  local sorter=frame.add{type="flow",name="razi_ops_sorter",direction="horizontal"}
  add_button(sorter,L(p.priority_sort and "priority-on" or "priority-off"),
    "priority","",L("priority-tooltip"))
  sorter.visible=p.tab=="platforms"
  local options=frame.add{type="flow",name="razi_ops_options",direction="horizontal"}
  options.add{
    type="checkbox",name="razi_ops_waypoints",
    state=p.waypoints,caption=L("waypoints")
  }
  options.add{
    type="checkbox",name="razi_ops_locked",
    state=p.locked,caption=L("show-locked")
  }
  local body=frame.add{type="flow",name="razi_ops_body",direction="vertical"}
  body.style.horizontally_stretchable=true
  options.razi_ops_waypoints.visible=p.tab=="worlds"
  options.razi_ops_locked.visible=p.tab=="worlds"
  player.opened=frame
  redraw(player)
end

function M.toggle(player)
  if player.gui.screen[FRAME] then
    close(player)
  elseif M.in_map_view(player) then
    open(player)
  end
end
local function record_recent(p,key)
  for i=#p.recent,1,-1 do
    if p.recent[i]==key then table.remove(p.recent,i) end
  end
  table.insert(p.recent,1,key)
  while #p.recent>12 do table.remove(p.recent) end
end
local function destination(player,kind,id)
  if kind=="worlds" then
    local planet=game.planets[id]
    if not planet or not planet.valid
      or not is_unlocked(player.force,id) or not planet.surface
      or not planet.surface.valid then return nil end
    return planet.surface
  end
  local index=tonumber(id)
  local platform=index and player.force.platforms[index]
  if not valid_platform(platform) or not platform.surface
    or not platform.surface.valid then return nil end
  return platform.surface
end
function M.gui_click(event)
  local element=event.element
  if not (element and element.valid) then return end
  local tags=element.tags
  if not (tags and tags.razi_ops_action) then return end
  local player=game.get_player(event.player_index)
  if not (player and player.valid) then return end
  local p=preferences(player.index)
  local action,value=tags.razi_ops_action,tags.value
  if action=="map-toggle" then M.toggle(player);return end
  if action=="close" then close(player);return end
  if action=="tab" then
    if value~="worlds" and value~="platforms" then return end
    p.tab=value;p.page=1;p.focus=nil
    local frame=player.gui.screen[FRAME]
    if frame and frame.valid then
      frame.razi_ops_options.razi_ops_waypoints.visible=value=="worlds"
      frame.razi_ops_options.razi_ops_locked.visible=value=="worlds"
      frame.razi_ops_roles.visible=value=="platforms"
      frame.razi_ops_sorter.visible=value=="platforms"
    end
  elseif action=="page" then
    p.page=math.max(1,p.page+value)
  elseif action=="priority" then
    p.priority_sort=not p.priority_sort
    local frame=player.gui.screen[FRAME]
    if frame and frame.valid then
      local sorter=frame.razi_ops_sorter
      if sorter and sorter.valid then sorter.children[1].caption=L(p.priority_sort and "priority-on" or "priority-off") end
    end
  elseif action=="details-close" then
    p.focus=nil
  elseif action=="atlas-origin" then
    if prototypes.space_location[value] and player.force.is_space_location_unlocked(value) then
      p.atlas_origin=value
    end
  elseif action=="details" then
    local kind,id=value:match("^(worlds):(.+)$")
    if not kind then kind,id=value:match("^(platforms):(.+)$") end
    if kind~=p.tab then return end
    if kind=="worlds" then
      local proto=prototypes.space_location[id]
      if not proto or proto.hidden or (not p.locked
        and not player.force.is_space_location_unlocked(id)) then return end
    elseif not valid_platform(player.force.platforms[tonumber(id)]) then
      return
    end
    p.focus=value
  elseif action=="favorite" or action=="view" then
    local kind,id=value:match("^(worlds):(.+)$")
    if not kind then kind,id=value:match("^(platforms):(.+)$") end
    if not kind then return end
    if action=="favorite" then
      p.favorites[kind][id]=not p.favorites[kind][id] or nil
    else
      local surface=destination(player,kind,id)
      if surface then
        record_recent(p,value)
        close(player)
        player.set_controller{type=defines.controllers.remote,surface=surface}
        return
      end
    end
  elseif action~="refresh" then
    return
  end
  redraw(player)
end
function M.text_changed(event)
  local element=event.element
  if not (element and element.valid) then return end
  local tags=element.tags
  if tags and tags.razi_ops_note_id then
    local p=preferences(event.player_index)
    p.notes[tostring(tags.razi_ops_note_id)]=element.text:sub(1,128)
    return
  end
  if element.name~="razi_ops_search" then return end
  local p=preferences(event.player_index)
  p.search=element.text:sub(1,80);p.page=1
  local player=game.get_player(event.player_index)
  if player then redraw(player) end
end
function M.selection_changed(event)
  local element=event.element
  if not (element and element.valid) then return end
  local p=preferences(event.player_index)
  local tags=element.tags
  if tags and tags.razi_ops_role_id then
    local id=tostring(tags.razi_ops_role_id)
    local role=ROLE_CHOICES[element.selected_index] or "auto"
    p.roles[id]=role~="auto" and role or nil
    p.page=1
    local player=game.get_player(event.player_index)
    if player then redraw(player) end
    return
  end
  if element.name=="razi_ops_role_filter" then
    p.role_filter=ROLES[element.selected_index] or "all"
  elseif element.name=="razi_ops_filter" then
    p.filter=FILTERS[element.selected_index] or "all"
  elseif element.name=="razi_ops_group" then
    p.group=group_options[element.selected_index] or "all"
  else return end
  p.page=1
  local player=game.get_player(event.player_index)
  if player then redraw(player) end
end
function M.checkbox_changed(event)
  local element=event.element
  if not (element and element.valid) then return end
  local p=preferences(event.player_index)
  if element.name=="razi_ops_waypoints" then
    p.waypoints=element.state
  elseif element.name=="razi_ops_locked" then
    p.locked=element.state
  else return end
  p.page=1
  local player=game.get_player(event.player_index)
  if player then redraw(player) end
end
function M.gui_closed(event)
  if event.element and event.element.valid
    and event.element.name==FRAME then
    local player=game.get_player(event.player_index)
    if player then close(player) end
  end
end
function M.on_display_changed(event)
  local player=game.get_player(event.player_index)
  if not player then return end
  if player.gui.screen[FRAME] then
    close(player)
    if M.in_map_view(player) then open(player) end
  end
  M.sync_map_button(player)
end
function M.on_removed(event)
  if storage.razigui then storage.razigui[event.player_index]=nil end
end
return M
