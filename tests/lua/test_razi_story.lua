-- The storyline switch (scripts/razi_story.lua): with the story off nothing
-- story-related is created, called or shown, and the mechanics still work.
-- With the story on the original behaviour is unchanged.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local story=require("scripts.razi_story")
check(story.enabled()==false,"The story must ship switched off")
check(#story.records()==0,"No archive records while the story is off")
-- Notices are no-ops even without any game state.
story.dispatch.on_research{research={name="automation"}}
story.dispatch.flush()
story.dispatch.forces_merged{source_index=1,destination_index=2}
story.dispatch.shipment({index=1},"victory")
check(rawget(_G,"storage")==nil,"Record notices touched save data while off")
check(package.loaded["scripts.razi_story_dispatch"]==nil
  and package.loaded["scripts.razi_journal_records"]==nil,
  "Story modules must not be loaded while the story is off")

-- Minimal GUI mock, as in test_razi_journal_layout.lua.
local created={}
local function node(spec)
  local element={valid=true,type=spec.type,name=spec.name,tags=spec.tags,
    caption=spec.caption,tooltip=spec.tooltip,selected_index=spec.selected_index,
    items=spec.items,sprite=spec.sprite,text=spec.text,style={},children={}}
  created[#created+1]=element
  function element.add(child)
    local item=node(child)
    element.children[#element.children+1]=item
    if item.name then element[item.name]=item end
    return item
  end
  function element.clear() element.children={} end
  function element.scroll_to_element() end
  return element
end
local journal=require("scripts.razi_journal")
local defs=require("scripts.razi_journal_data")
local projects=require("scripts.razi_journal_projects")
local force={name="player",index=1,technologies={},
  get_entity_count=function() return 0 end,
  find_entities_filtered=function() return {} end,
  platforms={},players={},connected_players={}}
rawset(_G,"helpers",{is_valid_sprite_path=function() return true end})
rawset(_G,"prototypes",{item={},recipe={}})
for _,quest in ipairs(defs.quests) do
  if quest.tech then
    force.technologies[quest.tech]={name=quest.tech,researched=true,
      enabled=true,localised_name=quest.tech,prerequisites={},
      prototype={hidden=false,effects={}}}
  end
end
local inventory={valid=true,get_item_count=function() return 0 end}
local player={valid=true,index=1,force=force,name="Tester",
  get_main_inventory=function() return inventory end,
  display_resolution={width=1920,height=1080},display_scale=1,
  gui={screen={},left={},top={}}}
local root=node{type="frame",name=journal.FRAME}
player.gui.screen[journal.FRAME]=root
rawset(_G,"storage",{})
rawset(_G,"game",{tick=100,connected_players={player},forces={player=force},
  get_player=function(id) if id==1 then return player end end})

-- Every localised key shown anywhere in the open window.
local function shown_keys()
  local keys={}
  local function walk(value)
    if type(value)~="table" then return end
    if type(value[1])=="string" and value[1]~="" and value[1]~="?" then
      keys[value[1]]=true
    end
    for _,item in ipairs(value) do walk(item) end
  end
  local function visit(parent)
    for _,child in ipairs(parent.children) do
      walk(child.caption);walk(child.tooltip)
      visit(child)
    end
  end
  visit(root)
  return keys
end
local STORY_KEY_PATTERNS={
  "^journal%-story%.","^journal%-mood%.","^journal%-record%-",
  "^journal%-chapter%-summary%.","^journal%-chapter%-story%.",
  "^journal%-chapter%-dispatch%.","^razi%-star%-signature%.",
  "^razi%-story%.","^razi%-welcome%.","^journal%-ui%.project%-context%-",
  "^journal%-ui%.project%-array%-record%-","^journal%-ui%.archive%-",
  "^journal%-ui%.view%-archive$","^journal%-ui%.story%-heading$",
  "^journal%-ui%.chapter%-cover%-story$","^journal%-ui%.chapter%-cover%-dispatch$",
  "^journal%-ui%.chapter%-context$","^journal%-ui%.star%-charter%-heading$",
  "^razi%-ops%.convergence%-victory%-","^razi%-ops%.convergence%-witness%-testimony%-",
  "^razi%-ops%.convergence%-blackbox%-",
  "^razi%-ops%.convergence%-transmission%-sealed$",
  "^razi%-ops%.convergence%-transmission%-dyson$",
  "^razi%-ops%.convergence%-transmission%-resonance$",
  "^razi%-ops%.convergence%-transmission%-alignment$",
  "^razi%-ops%.convergence%-archive%-message$","^razi%-ops%.convergence%-won$"
}
local function story_keys(keys)
  local found={}
  for key in pairs(keys) do
    for _,pattern in ipairs(STORY_KEY_PATTERNS) do
      if key:match(pattern) then found[#found+1]=key;break end
    end
  end
  table.sort(found)
  return found
end
local function open_everything()
  local all={}
  local function absorb()
    for key in pairs(shown_keys()) do all[key]=true end
  end
  local p=journal.preferences(1)
  p.view="quests";p.selected="first-signal";p.chapter="calidus"
  p.chapter_cover=false
  journal.draw(player);absorb()
  p.chapter_cover=true
  journal.draw(player);absorb()
  p.chapter_cover=false
  p.view="archive"
  journal.draw(player);absorb()
  for _,id in ipairs({"platform","voyage","skybridge","beltbreaker","dyson",
    "array","transceiver","nexus-trials","ark","convergence"}) do
    p.view="projects";p.project=id
    journal.draw(player);absorb()
  end
  -- Convergence finale states: transmission running, then victory.
  p.view="projects";p.project="convergence"
  storage.razi_convergence={[1]={delivered={},victory=false,
    transmission={started=0,beat=2,operator="Tester"}}}
  journal.draw(player);absorb()
  storage.razi_convergence={[1]={delivered={},victory=true,
    completed_by="Tester",completed_site="nexus",victory_tick=3600}}
  journal.draw(player);absorb()
  storage.razi_convergence=nil
  p.view="systems"
  journal.draw(player);absorb()
  return all,p
end

-- Story off.
local keys,p=open_everything()
check(p.project~="array","Archive Array must not be reachable while off")
check(projects.valid("array")==false and projects.valid("convergence"),
  "Archive Array project exists only with the story")
local leaked=story_keys(keys)
check(#leaked==0,"Story text shown while off: "..table.concat(leaked,", "))
check(keys["journal-title.first-signal"] and keys["journal-chapter.calidus"],
  "Quest and chapter names must stay while the story is off")
check(keys["journal-tip.first-signal"],"Practical tips must stay while off")
check(keys["razi-story-off.convergence-won"]
  and keys["razi-story-off.convergence-archive-message"]
  and keys["razi-story-off.transmission-stage"],
  "Plain Convergence texts must replace the story ones while off")
-- A saved Archive view falls back to the quest list.
p.view="archive"
check(journal.preferences(1).view=="quests","Saved Archive view must fall back")
journal.preferences(1).story_unread["corp-welcome"]=true
journal.gui_click{player_index=1,element={valid=true,
  tags={razi_journal_action="view",id="archive"}}}
check(journal.preferences(1).view=="quests","Archive tab must not open while off")
check(journal.preferences(1).story_unread["corp-welcome"],
  "Unread markers are save data and must be kept")
local unlocked,total=journal.unlocked_records(force)
check(unlocked==0 and total==0,"No archive records while off")

-- Story on: the original windows come back.
story.configure(true)
check(story.enabled() and #story.records()>0,"Story did not switch on")
check(projects.valid("array"),"Archive Array project missing with the story")
keys=open_everything()
check(keys["journal-story.first-signal"] and keys["journal-mood.calidus"],
  "Story paragraphs must be shown with the story on")
check(keys["journal-chapter-summary.calidus"] and keys["journal-ui.project-context-platform"],
  "Chapter cover and project context must be shown with the story on")
check(keys["journal-ui.view-archive"],"Archive tab must exist with the story on")
check(keys["razi-ops.convergence-blackbox-1"]
  and keys["razi-ops.convergence-transmission-dyson"],
  "Convergence story text must be shown with the story on")
story.configure(false)
check(not story.enabled() and #story.records()==0,"Story did not switch off")
print("Razi story switch: off hides every story surface, on restores them")
