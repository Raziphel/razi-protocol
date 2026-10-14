-- Galactic Operations: large-campaign planets and platform manager.
-- Read-only except for per-player pins. Uses real force/platform data;
-- no on_tick scans, no surface creation, no recipe/progression modifications.
local M={}
local catalog=require("scripts.galactic_catalog")
local atlas=require("scripts.galactic_atlas")
local trials=require("scripts.razi_nexus_trials")
local fleet=require("scripts.galactic_fleet")
local campaign=require("scripts.galactic_campaign")
local trade=require("scripts.galactic_trade")
local cargo_catalog=require("scripts.galactic_trade_catalog")
local convergence=require("scripts.razi_convergence")
local journal_module
function M.bind_journal(module)
  journal_module=module
end
local dyson=require("scripts.galactic_dyson")
local dyson_runtime=require("scripts.galactic_dyson_runtime")
local FRAME="razi_galactic_operations"
local MAP_ANCHOR="razi_ops_map_anchor"
local MAP_BUTTON="razi_ops_map_button"
local MAP_DYSON="razi_ops_dyson_stage"
local MAP_SPRITE="razi-galactic-operations-map-icon"
-- The engine's native starmap header isn't a LuaGuiElement. This floating
-- entry appears while Remote View displays the chart, beside its controls.
-- It is never inserted into Factorio's quickbar or shortcut bar.
local PAGE_SIZE=16
local SYSTEM_COLORS={
  calidus={r=.72,g=.82,b=.95},solaris={r=1,g=.69,b=.43},
  nyxaris={r=.57,g=.87,b=.66},vibrant={r=.60,g=.80,b=1},
  vespera={r=.69,g=.73,b=1},beetlejuice={r=1,g=.77,b=.48},
  umbra={r=.81,g=.61,b=.94},["deep-space"]={r=.86,g=.66,b=.80},
  unassigned={r=.70,g=.76,b=.82}
}
local function group_color(group)
  return SYSTEM_COLORS[group] or SYSTEM_COLORS.unassigned
end
-- Values are Factorio GUI units, not physical pixels. Narrow displays get
-- two lines of controls instead of a sideways-scrolling command centre.
function M.layout(resolution,scale)
  local factor=math.max(scale or 1,0.5)
  local width=math.floor((resolution.width or 1280)/factor)
  local height=math.floor((resolution.height or 720)/factor)
  local outer=math.max(235,math.min(970,width-28))
  local compact=outer<860
  return {width=outer,compact=compact,
    card_width=math.max(165,outer-76),
    title_width=math.max(75,outer-185),
    list_height=math.max(120,math.min(360,math.floor(height*0.34))),
    inspector_height=math.max(100,math.min(210,math.floor(height*0.20))),
    viewport_height=height}
end
local function lower(value)
  if helpers and helpers.multilingual_to_lower then
    return helpers.multilingual_to_lower(value)
  end
  return value:lower()
end
function M.search_matches(row,search)
  if search=="" then return true end
  for _,value in ipairs({row.name or "",row.display_search or "",
                         row.group or "",row.location_search or ""}) do
    if lower(value):find(search,1,true) then return true end
  end
  return false
end
local sprite_cache={}
local function row_sprite(row)
  if row.kind=="platforms" then
    local source="entity/space-platform-hub"
    return helpers and helpers.is_valid_sprite_path
      and helpers.is_valid_sprite_path(source) and source or MAP_SPRITE
  end
  local cached=sprite_cache[row.id]
  if cached then return cached end
  for _,kind in ipairs({"planet","space-location"}) do
    local source=kind.."/"..row.id
    if helpers and helpers.is_valid_sprite_path
      and helpers.is_valid_sprite_path(source) then
      sprite_cache[row.id]=source
      return source
    end
  end
  sprite_cache[row.id]=MAP_SPRITE
  return MAP_SPRITE
end
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
       collapsed={},recent={},notes={},focus=nil,atlas_origin=nil,priority_sort=false,
       translations={},translation_requested={},translation_pending={}}
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
  p.translations=p.translations or {}
  p.translation_requested=p.translation_requested or {}
  p.translation_pending=p.translation_pending or {}
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

-- Translation is asynchronous. Request each visible name just once per
-- player's locale, never on every redraw or every search keystroke.
local function request_world_name(player,p,name,caption)
  if p.translation_locale~=player.locale then
    p.translation_locale=player.locale
    p.translations={}
    p.translation_requested={}
    p.translation_pending={}
  end
  if p.translations[name] or p.translation_requested[name] then return end
  if not player.connected or not player.request_translation then return end
  local id=player.request_translation(caption)
  p.translation_requested[name]=true
  p.translation_pending[id]=name
end

local function collect_worlds(player,p)
  local entries={}
  local force=player.force
  for name,proto in pairs(prototypes.space_location) do
    if not proto.hidden and (proto.type=="planet" or p.waypoints) then
      local unlocked=is_unlocked(force,name)
      if unlocked or p.locked then
        local accessible=unlocked and has_surface(name) or false
        request_world_name(player,p,name,proto.localised_name)
        entries[#entries+1]={
          id=name,name=name,caption=proto.localised_name,
          display_search=p.translations[name],
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
      local place=platform.space_location or platform.last_visited_space_location
      if place then request_world_name(player,p,place.name,place.localised_name) end
      entries[#entries+1]={
        id=tostring(index),index=index,name=platform.name,
        caption=platform.name,kind="platforms",
        group=platform_group(platform),status=platform_status(platform),
        ready=platform.surface and platform.surface.valid or false,
        location=place,
        connection=platform.space_connection,
        location_search=place and (p.translations[place.name] or place.name),
        alerts=diagnostics.warnings,
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
local function matches(p,row,search,recent)
  if p.group~="all" and p.group~=row.group then return false end
  if row.kind=="platforms" and p.role_filter~="all"
    and p.role_filter~=row.role then return false end
  if not M.search_matches(row,search) then return false end
  if p.filter=="favorites" and not p.favorites[row.kind][row.id] then
    return false
  elseif p.filter=="active" then
    if row.kind=="worlds" and row.status~="visited" then return false end
    if row.kind=="platforms" and row.status~="transit" then return false end
  elseif p.filter=="attention" then
    if row.kind=="worlds" and row.status~="locked" then return false end
    if row.kind=="platforms" and (row.warnings or 0)==0 then return false end
  elseif p.filter=="recent" and not recent[recent_key(row)] then
    return false
  end
  return true
end
local function rows_for(player,p)
  local all=p.tab=="worlds" and collect_worlds(player,p) or collect_platforms(player,p)
  local filtered={}
  local search=lower(p.search or "")
  local recent={}
  if p.filter=="recent" then
    for _,id in ipairs(p.recent) do recent[id]=true end
  end
  for _,row in ipairs(all) do
    if matches(p,row,search,recent) then
      row.sort_group=catalog.position(row.group)
      row.sort_name=lower(row.display_search or row.name)
      filtered[#filtered+1]=row
    end
  end
  table.sort(filtered,function(a,b)
    if p.priority_sort and a.kind=="platforms" and b.kind=="platforms"
      and a.warnings~=b.warnings then return a.warnings>b.warnings end
    if a.sort_group~=b.sort_group then
      return a.sort_group<b.sort_group
    end
    local af,bf=p.favorites[a.kind][a.id],p.favorites[b.kind][b.id]
    if (not not af)~=(not not bf) then return not not af end
    if a.kind=="platforms" and b.kind=="platforms" and a.role~=b.role then
      return a.role<b.role
    end
    if a.sort_name~=b.sort_name then
      return a.sort_name<b.sort_name
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
local function paint_row(parent,row,p,layout)
  local band=parent.add{type="frame",direction="vertical",style="inside_shallow_frame"}
  band.style.width=layout.card_width
  band.style.padding=9
  local header=band.add{type="flow",direction="horizontal"}
  header.style.vertical_align="center"
  header.style.horizontal_spacing=8
  local icon=header.add{type="sprite",sprite=row_sprite(row)}
  icon.style.width=layout.compact and 26 or 32
  icon.style.height=layout.compact and 26 or 32
  local heading=header.add{type="flow",direction="vertical"}
  heading.style.vertical_spacing=2
  local title=heading.add{type="label",caption=row.caption}
  title.style.font="default-bold"
  title.style.single_line=false
  title.style.maximal_width=math.max(60,layout.card_width-
    (layout.compact and 125 or 115))
  local group=heading.add{type="label",caption=L("group-"..row.group)}
  group.style.font_color=group_color(row.group)
  group.style.single_line=false
  group.style.maximal_width=math.max(60,layout.card_width-
    (layout.compact and 125 or 115))
  local favorite=p.favorites[row.kind][row.id]
  add_button(header,favorite and "★" or "☆","favorite",
    recent_key(row),L("favorite-tooltip"))

  local detail=band.add{type="flow",direction="horizontal"}
  detail.style.vertical_align="center"
  local state=detail.add{type="label",caption=L("status-"..row.status)}
  state.style.font="default-bold"
  state.style.single_line=false
  state.style.maximal_width=layout.card_width-25
  if row.status=="paused" or row.status=="unscheduled"
    or row.status=="locked" or row.status=="building" then
    accent(state,{r=1,g=.65,b=.38})
  elseif row.status=="transit" or row.status=="visited" then
    accent(state,{r=.49,g=.88,b=.71})
  end

  if row.kind=="platforms" then
    local where=row.location and row.location.localised_name or L("between-worlds")
    local place=band.add{type="label",caption=where}
    place.style.single_line=false
    place.style.maximal_width=layout.card_width-25
    if row.connection then
      local route=band.add{type="label",
        caption=L("flight-route",row.connection.from.localised_name,
          row.connection.to.localised_name)}
      route.style.single_line=false
      route.style.maximal_width=layout.card_width-25
      accent(route,{r=.57,g=.76,b=.96})
    end
    if (row.warnings or 0)>0 then
      local warning=band.add{type="label",
        caption=L("fleet-warnings",tostring(row.warnings))}
      accent(warning,{r=1,g=.69,b=.42})
      for i=1,math.min(2,#(row.alerts or {})) do
        local hint=band.add{type="label",
          caption=L("fleet-warning-"..row.alerts[i])}
        hint.style.single_line=false
        hint.style.maximal_width=layout.card_width-25
      end
      if row.warnings>2 then
        local more=band.add{type="label",caption=L("fleet-more-warnings",
          tostring(row.warnings-2))}
        accent(more,{r=.92,g=.76,b=.57})
      end
    end
    local mission=band.add{type="flow",
      direction=layout.compact and "vertical" or "horizontal"}
    mission.style.vertical_align="center"
    mission.add{type="label",caption=L("mission")}
    local choice=mission.add{type="drop-down",
      name="razi_ops_role_"..row.id,
      items={L("role-auto"),L("role-general"),L("role-freighter"),
             L("role-science"),L("role-defense"),L("role-exploration"),
             L("role-construction")},
      tags={razi_ops_role_id=row.id}}
    choice.style.width=layout.compact
      and math.max(95,layout.card_width-35)
      or math.max(95,math.min(225,layout.card_width-98))
    local chosen=row.manual_role and row.role or "auto"
    for i,value in ipairs(ROLE_CHOICES) do
      if chosen==value then choice.selected_index=i;break end
    end
  end
  local actions=band.add{type="flow",direction="horizontal"}
  actions.style.horizontal_spacing=8
  local view=add_button(actions,row.ready and L("view") or L("no-view"),
    row.ready and "view" or "not-available",
    recent_key(row),row.ready and L("view-tooltip") or L("no-view-tooltip"))
  view.enabled=row.ready
  add_button(actions,L(row.kind=="worlds" and "atlas-open" or "fleet-open"),
    "details",recent_key(row),L("details-tooltip"))
end

local function redraw(player)
  local frame=player.gui.screen[FRAME]
  if not (frame and frame.valid) then return end
  local p=preferences(player.index)
  local body=frame.razi_ops_body
  if not (body and body.valid) then return end
  body.clear()
  if p.tab=="campaign" then campaign.render(body,player);return end
  if p.tab=="trade" then trade.render(body,player,p);return end
  if p.tab=="dyson" then dyson.render(body,player);return end
  if p.tab=="convergence" then convergence.render(body,player);return end
  local layout=M.layout(player.display_resolution,player.display_scale)
  local rows,total=rows_for(player,p)
  local page_rows,page,pages=M.page_slice(rows,p.page,PAGE_SIZE)
  p.page=page
  local _,traveling,warnings=summary(player)
  local heading=body.add{type="label",caption=L(p.tab=="worlds"
    and "list-title-worlds" or "list-title-platforms")}
  heading.style.font="heading-2"
  heading.style.font_color={r=.56,g=.77,b=.96}
  local stats=body.add{type="table",
    column_count=layout.compact and 2 or 4}
  stats.style.horizontal_spacing=6
  stats.style.vertical_spacing=6
  for _,metric in ipairs({
    {"stat-total",total},{"stat-matches",#rows},
    {"stat-transit",traveling},{"stat-attention",warnings}
  }) do
    local tile=stats.add{type="frame",direction="vertical",
      style="inside_shallow_frame"}
    local number=tile.add{type="label",caption=tostring(metric[2])}
    number.style.font="heading-2"
    number.style.font_color=metric[1]=="stat-attention" and warnings>0
      and {r=1,g=.67,b=.41} or {r=.53,g=.80,b=.98}
    local caption=tile.add{type="label",caption=L(metric[1])}
    caption.style.single_line=false
    caption.style.maximal_width=layout.compact
      and math.max(90,math.floor(layout.card_width/2)-22)
      or math.max(105,math.floor(layout.card_width/4)-18)
  end

  local list=body.add{type="scroll-pane",direction="vertical"}
  list.style.horizontally_stretchable=true
  list.horizontal_scroll_policy="never"
  list.style.height=p.focus and math.max(110,math.floor(layout.list_height*.78))
    or layout.list_height
  if #page_rows==0 then
    local pending=p.tab=="worlds" and p.search~=""
      and next(p.translation_pending or {})
    list.add{type="label",caption=L(pending and "search-translating" or "empty")}
  end
  local last_group=nil
  for _,row in ipairs(page_rows) do
    if row.group~=last_group then
      last_group=row.group
      local group_header=list.add{type="label",caption=L("group-"..row.group)}
      group_header.style.font="heading-2"
      accent(group_header,group_color(row.group))
    end
    paint_row(list,row,p,layout)
  end
  local footer=body.add{type="flow",direction="horizontal"}
  footer.style.vertical_align="center"
  local prev=add_button(footer,"◀","page",-1)
  prev.enabled=page>1
  footer.add{type="label",caption=L("pages",tostring(page),tostring(pages))}
  local next=add_button(footer,"▶","page",1)
  next.enabled=page<pages
  if p.focus then
    -- A bounded inspector scroll prevents tall tech graphs or cargo summaries
    -- from pushing Galactic Operations below smaller displays.
    local inspector=body.add{type="scroll-pane",direction="vertical"}
    inspector.style.horizontally_stretchable=true
    inspector.horizontal_scroll_policy="never"
    inspector.style.height=layout.inspector_height
    local kind,id=p.focus:match("^(worlds):(.+)$")
    if not kind then kind,id=p.focus:match("^(platforms):(.+)$") end
    if kind==p.tab and kind=="worlds" then
      atlas.render(inspector,player,id,p)
    elseif kind==p.tab and kind=="platforms" then
      local platform=player.force.platforms[tonumber(id)]
      fleet.render(inspector,platform,id,p)
    end
  end
end

local function close(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then frame.destroy() end
  -- A direct Codex link may open Cargo outside Remote View. Returning to
  -- normal map-only behaviour on close prevents sticky floating windows.
  local p=storage.razigui and storage.razigui[player.index]
  if p then
    p.cargo_direct=nil;p.cargo_origin=nil
    p.convergence_direct=nil
  end
end

function M.in_map_view(player)
  return player and player.valid and player.connected
    and player.controller_type==defines.controllers.remote
    and player.render_mode~=defines.render_mode.game
end

function M.on_dyson_research(event)
  local research=event and event.research
  local force=research and research.force
  if not force then return end
  local matched=false
  for _,stage in ipairs(dyson.stages) do
    if stage[1]==research.name then matched=true;break end
  end
  if not matched then return end
  dyson_runtime.invalidate(force)
  for _,player in pairs(force.connected_players or {}) do
    M.sync_map_button(player)
    local p=storage.razigui and storage.razigui[player.index]
    local frame=player.gui.screen[FRAME]
    if p and p.tab=="dyson" and frame and frame.valid then
      redraw(player)
    end
  end
end

local function position_map_button(player,anchor)
  local scale=math.max(player.display_scale,0.5)
  local width=math.floor(player.display_resolution.width/scale)
  -- Only move the floating map button when its position actually changes.
  -- Writing the same GUI location every 30 ticks forces extra layout work.
  local x=math.max(8,width-291)
  local current=anchor.location
  if not current or current.x~=x or current.y~=86 then
    anchor.location={x=x,y=86}
  end
end

function M.sync_map_button(player)
  if not (player and player.valid) then return end
  local anchor=player.gui.screen[MAP_ANCHOR]
  if not M.in_map_view(player) then
    if anchor and anchor.valid then anchor.destroy() end
    local p=storage.razigui and storage.razigui[player.index]
    if player.gui.screen[FRAME] and not
      (p and p.cargo_direct and p.tab=="trade") then close(player) end
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
  local completed,total=dyson.status(player.force)
  local badge=anchor[MAP_DYSON]
  if total>0 then
    local wanted="razi-dyson-works-stage-"..math.min(6,completed)
    if not (badge and badge.valid) then
      badge=anchor.add{
        type="sprite-button",name=MAP_DYSON,
        sprite=wanted,style="slot_button",
        tags={razi_ops_action="dyson-map"}
      }
      badge.style.width=38
      badge.style.height=38
    end
    if badge.sprite~=wanted then badge.sprite=wanted end
    local state=badge.tags
    if not state or state.razi_ops_stage~=completed then
      badge.tags={razi_ops_action="dyson-map",razi_ops_stage=completed}
      badge.tooltip=L("dyson-map-progress",tostring(completed),tostring(total))
    end
  elseif badge and badge.valid then badge.destroy() end
  position_map_button(player,anchor)
end

function M.sync_all_map_buttons()
  for _,player in pairs(game.connected_players) do
    M.sync_map_button(player)
    local p=storage.razigui and storage.razigui[player.index]
    if p and p.translation_dirty then
      p.translation_dirty=nil
      local frame=player.gui.screen[FRAME]
      if (p.tab=="worlds" or p.tab=="platforms") and p.search~=""
        and frame and frame.valid then redraw(player) end
    end
  end
end

function M.on_string_translated(event)
  local p=storage.razigui and storage.razigui[event.player_index]
  local pending=p and p.translation_pending
  local name=pending and pending[event.id]
  if not name then return end
  pending[event.id]=nil
  if event.translated and type(event.result)=="string" then
    p.translations[name]=lower(event.result)
    -- Paint once in the existing 30-tick map check, not once per
    -- translated planet. Names are stored per player and locale.
    p.translation_dirty=true
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
  local scale=math.max(player.display_scale,0.5)
  local layout=M.layout(resolution,scale)
  local width=layout.width
  local frame=player.gui.screen.add{
    type="frame",name=FRAME,direction="vertical",caption=L("title")
  }
  frame.style.width=width
  frame.style.maximal_height=math.max(230,layout.viewport_height-24)
  frame.location={x=math.max(0,math.floor((resolution.width/scale-width)/2)),
                  y=math.max(12,math.floor(resolution.height/scale*0.04))}
  local head=frame.add{type="flow",direction="horizontal"}
  head.style.horizontally_stretchable=true
  local eyebrow=head.add{type="label",
    caption=L(layout.compact and "subtitle-compact" or "subtitle")}
  eyebrow.style.single_line=false
  eyebrow.style.maximal_width=layout.compact and 155 or 350
  local drag=head.add{type="empty-widget",style="draggable_space"}
  drag.style.horizontally_stretchable=true
  drag.style.height=28
  drag.drag_target=frame
  add_button(head,L("refresh"),"refresh","")
  add_button(head,"✕","close","")
  local tabs=frame.add{type="table",name="razi_ops_tabs",
    column_count=layout.compact and 3 or 6}
  tabs.style.horizontal_spacing=5
  tabs.style.vertical_spacing=5
  for _,entry in ipairs({
    {"worlds","worlds-tab"},{"platforms","platforms-tab"},
    {"campaign","campaign-tab"},{"trade","trade-tab"},
    {"dyson","dyson-tab"},{"convergence","convergence-tab"}
  }) do
    local caption=entry[2]..(layout.compact and "-short" or "")
    local button=add_button(tabs,L(caption),"tab",entry[1])
    button.toggled=entry[1]==p.tab
  end
  local search_tools=frame.add{type="flow",
    name="razi_ops_search_tools",direction="horizontal"}
  search_tools.style.horizontally_stretchable=true
  local search=search_tools.add{
    type="textfield",name="razi_ops_search",
    text=p.search,tooltip=L("search-tooltip")
  }
  search.style.horizontally_stretchable=true
  search.style.width=math.max(150,width-126)
  add_button(search_tools,L("clear-search"),"clear-search")
  local filters=frame.add{type="flow",name="razi_ops_filters",
    direction=layout.compact and "vertical" or "horizontal"}
  local filter_row=filters.add{type="flow",direction="horizontal"}
  filter_row.add{type="label",caption=L("filter")}
  local filter=filter_row.add{
    type="drop-down",name="razi_ops_filter",
    items={L("filter-all"),L("filter-favorites"),L("filter-active"),
           L("filter-attention"),L("filter-recent")}
  }
  filter.style.width=layout.compact and math.max(135,width-125) or 195
  for index,value in ipairs(FILTERS) do
    if value==p.filter then filter.selected_index=index end
  end
  local group_row=filters.add{type="flow",direction="horizontal"}
  group_row.add{type="label",caption=L("system")}
  local groups={}
  for _,group in ipairs(group_options) do
    groups[#groups+1]=L("group-"..group)
  end
  local selector=group_row.add{
    type="drop-down",name="razi_ops_group",items=groups
  }
  selector.style.width=layout.compact and math.max(135,width-125) or 255
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
  local listing=p.tab=="worlds" or p.tab=="platforms"
  search_tools.visible=listing
  filters.visible=listing
  options.visible=p.tab=="worlds"
  options.razi_ops_waypoints.visible=p.tab=="worlds"
  options.razi_ops_locked.visible=p.tab=="worlds"
  player.opened=frame
  redraw(player)
end

function M.refresh_convergence(force)
  if not force then return end
  for _,player in pairs(force.connected_players or {}) do
    local frame=player.gui.screen[FRAME]
    local p=storage.razigui and storage.razigui[player.index]
    if frame and frame.valid and p and p.tab=="convergence" then
      redraw(player)
    end
  end
end
function M.on_convergence_research(event)
  local research=event and event.research
  if not research or (research.name~="razi-convergence-commission"
    and research.name~="razi-convergence-synchronization"
    and research.name~="razi-convergence-ignition") then return end
  M.refresh_convergence(research.force)
end

function M.toggle(player)
  if player.gui.screen[FRAME] then
    close(player)
  elseif M.in_map_view(player) then
    open(player)
  end
end
-- Called only by an explicit Codex action. The map launch button still
-- appears exclusively inside Remote View. No surface switching occurs.
function M.open_cargo(player,chain,target)
  if not (player and player.valid and
    cargo_catalog.is_installed(player.force,chain)) then return false end
  local known=false
  for _,entry in ipairs(cargo_catalog.chains) do
    if entry.id==chain then known=true;break end
  end
  if not known or (target and
    cargo_catalog.chain_for_technology(target)~=chain) then return false end
  local p=preferences(player.index)
  p.tab="trade"
  p.cargo_focus=chain
  p.cargo_target=target
  p.cargo_origin=chain
  p.cargo_direct=not M.in_map_view(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then
    -- Reuse the open window rather than destroying player.opened and
    -- accidentally clearing the direct-link preference in gui_closed.
    frame.razi_ops_options.visible=false
    frame.razi_ops_search_tools.visible=false
    frame.razi_ops_filters.visible=false
    frame.razi_ops_roles.visible=false
    frame.razi_ops_sorter.visible=false
    local tabs=frame.razi_ops_tabs
    if tabs then
      for _,button in pairs(tabs.children) do
        local meta=button.tags
        if meta and meta.razi_ops_action=="tab" then
          button.toggled=meta.value=="trade"
        end
      end
    end
    redraw(player)
  else
    open(player)
  end
  return true
end
-- Open the endgame from the Codex outside Remote View. Physical cargo
-- still requires the character aboard the expedition platform.
function M.open_convergence(player)
  if not (player and player.valid and convergence.available(player.force)) then
    return false
  end
  local p=preferences(player.index)
  p.tab="convergence"
  p.convergence_direct=not M.in_map_view(player)
  local frame=player.gui.screen[FRAME]
  if frame and frame.valid then
    for _,name in ipairs({"razi_ops_options","razi_ops_search_tools",
      "razi_ops_filters","razi_ops_roles","razi_ops_sorter"}) do
      frame[name].visible=false
    end
    for _,tab in pairs(frame.razi_ops_tabs.children) do
      local tags=tab.tags
      if tags and tags.razi_ops_action=="tab" then
        tab.toggled=tags.value=="convergence"
      end
    end
    redraw(player)
  else
    open(player)
  end
  return true
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
  if action=="dyson-map" then
    p.tab="dyson";p.page=1;p.focus=nil
    local frame=player.gui.screen[FRAME]
    if frame and frame.valid then
      frame.razi_ops_options.visible=false
      frame.razi_ops_search_tools.visible=false
      frame.razi_ops_filters.visible=false
      frame.razi_ops_roles.visible=false
      frame.razi_ops_sorter.visible=false
      for _,tab in pairs(frame.razi_ops_tabs.children) do
        local meta=tab.tags
        if meta and meta.razi_ops_action=="tab" then
          tab.toggled=meta.value=="dyson"
        end
      end
      redraw(player)
    else
      open(player)
    end
    return
  end
  if action=="refresh" and p.tab=="dyson" then
    dyson_runtime.invalidate(player.force)
  end
  if action=="close" then close(player);return end
  if action=="atlas-convergence" then
    M.open_convergence(player)
    return
  end
  if action=="convergence-deliver" then
    if p.tab~="convergence" then return end
    local message,amount=convergence.deliver(player,value)
    player.print(L(message,tostring(amount)))
    redraw(player)
    return
  end
  if action=="nexus-codex" then
    if not trials.open_codex(player,value) then
      player.print(L("atlas-nexus-codex-unavailable"))
    end
    return
  end
  if action=="tab" then
    if value~="worlds" and value~="platforms"
      and value~="campaign" and value~="trade"
      and value~="dyson" and value~="convergence" then return end
    p.tab=value;p.page=1;p.focus=nil
    local frame=player.gui.screen[FRAME]
    if frame and frame.valid then
      frame.razi_ops_options.visible=value=="worlds"
      frame.razi_ops_options.razi_ops_waypoints.visible=value=="worlds"
      frame.razi_ops_options.razi_ops_locked.visible=value=="worlds"
      local listing=value=="worlds" or value=="platforms"
      frame.razi_ops_search_tools.visible=listing
      frame.razi_ops_filters.visible=listing
      frame.razi_ops_roles.visible=value=="platforms"
      frame.razi_ops_sorter.visible=value=="platforms"
      local tabs=frame.razi_ops_tabs
      if tabs then
        for _,button in pairs(tabs.children) do
          local meta=button.tags
          if meta and meta.razi_ops_action=="tab" then
            button.toggled=meta.value==value
          end
        end
      end
    end
  elseif action=="cargo-focus" then
    if p.tab~="trade" then return end
    if not cargo_catalog.is_installed(player.force,value) then return end
    local allowed=false
    for _,entry in ipairs(cargo_catalog.chains) do
      if entry.id==value then allowed=true;break end
    end
    if not allowed then return end
    p.cargo_focus=p.cargo_focus==value and nil or value
    p.cargo_target=nil
  elseif action=="cargo-codex" then
    if p.tab~="trade" then return end
    local quest_id=cargo_catalog.quest_for_technology(value)
    local linked=cargo_catalog.chain_for_technology(value)
    if not (quest_id and cargo_catalog.is_installed(player.force,linked)
      and player.force.technologies[value]) then return end
    local quest=journal_module and journal_module.quest_by_id(quest_id)
    if not (quest and journal_module.available(player.force,quest)) then return end
    close(player)
    journal_module.open_quest(player,quest_id)
    return
  elseif action=="clear-search" then
    p.search="";p.page=1
    local frame=player.gui.screen[FRAME]
    local field=frame and frame.razi_ops_search_tools
      and frame.razi_ops_search_tools.razi_ops_search
    if field and field.valid then field.text="" end
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
    local p=preferences(player.index)
    local was_direct=p.cargo_direct and p.tab=="trade"
    local convergence_direct=p.convergence_direct and p.tab=="convergence"
    local chain,target=p.cargo_origin or p.cargo_focus,p.cargo_target
    close(player)
    if M.in_map_view(player) then
      open(player)
    elseif was_direct then
      M.open_cargo(player,chain,target)
    elseif convergence_direct then
      M.open_convergence(player)
    end
  end
  M.sync_map_button(player)
end
function M.on_removed(event)
  if storage.razigui then storage.razigui[event.player_index]=nil end
end
return M
