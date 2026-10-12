-- Native Journal GUI regression without running Factorio or changing game state.
-- The mock tests column widths, wrapped captions, hidden scrollbar chrome
-- and navigation callbacks. Full visual rendering still needs a game test.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end
local journal=require("scripts.razi_journal")
local defs=require("scripts.razi_journal_data")
local created={}
local function node(spec)
  local element={valid=true,type=spec.type,name=spec.name,tags=spec.tags,
    caption=spec.caption,tooltip=spec.tooltip,
    selected_index=spec.selected_index,items=spec.items,
    sprite=spec.sprite,text=spec.text,
    horizontal_scroll_policy=spec.horizontal_scroll_policy,
    vertical_scroll_policy=spec.vertical_scroll_policy,
    style={},children={}}
  created[#created+1]=element
  function element.add(child)
    local item=node(child)
    element.children[#element.children+1]=item
    if item.name then element[item.name]=item end
    return item
  end
  function element.clear()
    element.children={}
    for _,child in ipairs(created) do
      if child.name then element[child.name]=nil end
    end
  end
  function element.scroll_to_element(target)
    check(target.valid,"Cannot scroll to destroyed quest")
  end
  return element
end
local force={name="player",technologies={}}
rawset(_G,"helpers",{is_valid_sprite_path=function() return true end})
rawset(_G,"prototypes",{
 item={
   ["automation-science-pack"]={localised_name="Automation science"},
   ["assembling-machine-1"]={localised_name="Assembler",
     place_result={name="assembling-machine-1",localised_name="Assembler"}}},
 recipe={
   ["assembling-machine-1"]={localised_name="Assembler",
     products={{type="item",name="assembling-machine-1"}}}}
})
for _,quest in ipairs(defs.quests) do
  if quest.tech then
    force.technologies[quest.tech]={
      name=quest.tech,researched=false,enabled=true,
      localised_name=quest.tech,prerequisites={},
      prototype={hidden=false,effects={}}
    }
  end
end
force.technologies.automation.prototype.effects={
  {type="unlock-recipe",recipe="assembling-machine-1"}}
force.technologies.automation.research_unit_ingredients={
  {name="automation-science-pack",amount=1}}
local player={valid=true,index=1,force=force,
  display_resolution={width=1920,height=1080},
  display_scale=1.25,
  gui={screen={},left={},top={}}}
local root=node{type="frame",name=journal.FRAME}
player.gui.screen[journal.FRAME]=root
rawset(_G,"storage",{})
rawset(_G,"game",{
  connected_players={player},forces={player=force},
  get_player=function(id) if id==1 then return player end end
})
local function assert_panes()
  local count=0
  for _,element in ipairs(created) do
    if element.type=="scroll-pane" then
      count=count+1
      check(element.horizontal_scroll_policy=="never",
        "One of the reader's scroll panes still has a horizontal bar")
      check(element.vertical_scroll_policy=="dont-show-but-allow-scrolling",
        "Scrollbar chrome should be hidden, but wheel scrolling preserved")
      check(element.style.width and element.style.width>100,
        "Scroll pane missing explicit width")
    end
  end
  return count
end
journal.draw(player)
local wide=journal.layout(player.display_resolution,player.display_scale)
check(wide.width>960,"The redesigned window was not enlarged")
check(root.style.width==wide.width,"Frame width ignores resolution")
check(assert_panes()==2,"Quest view needs only navigator and reader panes")
local sprites={}
for _,entry in ipairs(created) do
  if entry.sprite then sprites[entry.sprite]=true end
end
check(sprites["technology/automation"],"Native research art is missing")
check(sprites["item/automation-science-pack"],"Native science art is missing")
check(sprites["entity/assembling-machine-1"],"Native building art is missing")
check(journal.matches_query(defs.by_id["first-signal"],"automation"),
  "Search must match native technology")
check(not journal.matches_query(defs.by_id["first-signal"],"maraxsis"),
  "Search must exclude unrelated technologies")
local search_field
for _,entry in ipairs(created) do
  if entry.name=="razi_journal_search" then search_field=entry end
end
check(search_field,"Live search input is missing")
search_field.text="automation"
journal.text_changed({player_index=1,element=search_field})
check(journal.preferences(1).query=="automation",
  "Typed search should persist in existing player preferences")
journal.preferences(1).query=""
created={}
journal.draw(player)
local picker
local selector
for _,element in ipairs(created) do
  if element.name=="razi_journal_chapter_picker" then picker=element end
  if element.tags and element.tags.razi_journal_action=="select"
    and element.type=="button" then selector=element end
end
check(picker and picker.items and #picker.items==17 and picker.selected_index,
  "The chapter jump dropdown is absent")
check(selector and selector.tags.id,
  "Wrapped quest rows require a guaranteed clickable button")
picker.selected_index=3
created={}
journal.selection_changed({player_index=1,element=picker})
check(journal.preferences(1).chapter=="nyxaris",
  "Jumping to a chapter did not navigate the index")
check(journal.preferences(1).selected~=nil,
  "Chapter jump must select a visible objective")
created={}
journal.preferences(1).view="archive"
force.technologies.automation.researched=true
journal.draw(player)
check(assert_panes()==2,
  "Archive navigation and reading should also hide both scrollbars")
for _,size in ipairs({
  {width=1920,height=1080,scale=1},
  {width=1920,height=1080,scale=1.25},
  {width=1600,height=900,scale=1.5},
  {width=1280,height=720,scale=1},
  {width=1024,height=768,scale=1}
}) do
  local d=journal.layout(size,size.scale)
  check(d.reader+d.rail+43==d.width,
    "Columns must fit within their window at every UI scale")
  check(d.reader>=190,"Story pane too narrow for readable content")
  check(d.body<d.height,"Reader must leave space for toolbar and header")
end
print("Journal GUI: large window, wrapped navigation, hidden scrollbars and jump selector passed")
