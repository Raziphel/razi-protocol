---@diagnostic disable: unnecessary-assert, param-type-mismatch, need-check-nil, inject-field
-- Shared by the journal tests: a minimal GUI mock, a walk through every
-- journal window, and the list of keys that belong to the story layer.
-- Callers set package.path first. Not a test itself.
local M={}

-- Keys of the authored layer: none of them may be shown while the story is off.
M.AUTHORED_PATTERNS={
  "^journal%-story%.","^journal%-mood%.","^journal%-record%-",
  "^journal%-title%.","^journal%-tip%.",
  "^razi%-industries%-brief%.","^razi%-planet%-charter%.",
  "^razi%-planet%-freight%.",
  "^journal%-chapter%-summary%.","^journal%-chapter%-story%.",
  "^journal%-chapter%-dispatch%.","^razi%-star%-signature%.",
  "^razi%-story%.","^razi%-welcome%.","^journal%-ui%.project%-context%-",
  "^journal%-ui%.project%-array%-record%-","^journal%-ui%.archive%-",
  "^journal%-ui%.view%-archive$","^journal%-ui%.story%-heading$",
  "^journal%-ui%.tip%-heading$","^journal%-ui%.industrial%-brief%-heading$",
  "^journal%-ui%.star%-charter%-heading$",
  "^journal%-ui%.chapter%-cover%-story$","^journal%-ui%.chapter%-cover%-dispatch$",
  "^journal%-ui%.chapter%-context$",
  "^razi%-ops%.convergence%-victory%-","^razi%-ops%.convergence%-witness%-testimony%-",
  "^razi%-ops%.convergence%-blackbox%-",
  "^razi%-ops%.convergence%-transmission%-sealed$",
  "^razi%-ops%.convergence%-transmission%-dyson$",
  "^razi%-ops%.convergence%-transmission%-resonance$",
  "^razi%-ops%.convergence%-transmission%-alignment$",
  "^razi%-ops%.convergence%-archive%-message$","^razi%-ops%.convergence%-won$"
}

-- A list for a failure message: the first few entries and the count.
function M.brief(list)
  local shown={}
  for index=1,math.min(#list,8) do shown[index]=list[index] end
  return table.concat(shown,", ")..(#list>8 and " ... ("..#list.." in all)" or "")
end

function M.authored(keys)
  local found={}
  for key in pairs(keys) do
    for _,pattern in ipairs(M.AUTHORED_PATTERNS) do
      if key:match(pattern) then found[#found+1]=key;break end
    end
  end
  table.sort(found)
  return found
end

-- Keys of a localised string, as {singles={key=true},chains={{key,...}}}.
-- `{"?",a,b}` is a chain of fallbacks: it is recorded as one chain, so the
-- caller can accept any of its keys. Nested chains are flattened.
local function alternatives(item,chain,out)
  if type(item)~="table" then return end
  if item[1]=="?" then
    for index=2,#item do alternatives(item[index],chain,out) end
    return
  end
  if type(item[1])=="string" and item[1]~="" then chain[#chain+1]=item[1] end
  for index=2,#item do M.collect(item[index],out) end
end
function M.collect(value,out)
  out=out or {singles={},chains={}}
  if type(value)~="table" then return out end
  if value[1]=="?" then
    local chain={}
    alternatives(value,chain,out)
    out.chains[#out.chains+1]=chain
    return out
  end
  if type(value[1])=="string" and value[1]~="" then
    out.singles[value[1]]=true
  end
  for index=2,#value do M.collect(value[index],out) end
  return out
end

-- Every key of a collected set, chain members included, as {key=true}.
function M.flat(collected)
  local keys={}
  for key in pairs(collected.singles) do keys[key]=true end
  for _,chain in ipairs(collected.chains) do
    for _,key in ipairs(chain) do keys[key]=true end
  end
  return keys
end

local function node(created,spec)
  local element={valid=true,type=spec.type,name=spec.name,tags=spec.tags,
    caption=spec.caption,tooltip=spec.tooltip,selected_index=spec.selected_index,
    items=spec.items,sprite=spec.sprite,text=spec.text,style={},children={}}
  created[#created+1]=element
  function element.add(child)
    local item=node(created,child)
    element.children[#element.children+1]=item
    if item.name then element[item.name]=item end
    return item
  end
  function element.clear() element.children={} end
  function element.scroll_to_element() end
  return element
end

-- Builds the mocked game and returns the window under test.
function M.setup()
  local ctx={}
  local created={}
  local journal=require("scripts.razi_journal")
  local defs=require("scripts.razi_journal_data")
  ctx.journal,ctx.defs=journal,defs
  ctx.projects=require("scripts.razi_journal_projects")
  local force={name="player",index=1,technologies={},
    get_entity_count=function() return 0 end,
    find_entities_filtered=function() return {} end,
    platforms={},players={},connected_players={}}
  local technologies={}
  rawset(_G,"helpers",{is_valid_sprite_path=function() return true end})
  rawset(_G,"prototypes",{item={},recipe={},technology=technologies})
  for _,quest in ipairs(defs.quests) do
    if quest.tech then
      force.technologies[quest.tech]={name=quest.tech,researched=true,
        enabled=true,localised_name={"technology-name."..quest.tech},
        prerequisites={},prototype={hidden=false,effects={}}}
      technologies[quest.tech]={name=quest.tech,
        localised_name={"technology-name."..quest.tech}}
    end
  end
  local inventory={valid=true,get_item_count=function() return 0 end}
  local player={valid=true,index=1,force=force,name="Tester",
    get_main_inventory=function() return inventory end,
    display_resolution={width=1920,height=1080},display_scale=1,
    gui={screen={},left={},top={}}}
  local root=node(created,{type="frame",name=journal.FRAME})
  player.gui.screen[journal.FRAME]=root
  rawset(_G,"storage",{})
  rawset(_G,"game",{tick=100,connected_players={player},forces={player=force},
    get_player=function(id) if id==1 then return player end end})
  ctx.force,ctx.player,ctx.root=force,player,root

  -- Every localised key shown anywhere in the open window.
  function ctx.shown()
    local out={singles={},chains={}}
    local function visit(parent)
      for _,child in ipairs(parent.children) do
        M.collect(child.caption,out);M.collect(child.tooltip,out)
        visit(child)
      end
    end
    visit(root)
    return out
  end
  -- Draws every view and every project, including both Convergence finale
  -- states, and returns the union of all keys shown.
  function ctx.open_everything()
    local all={singles={},chains={}}
    local function absorb()
      local now=ctx.shown()
      for key in pairs(now.singles) do all.singles[key]=true end
      for _,chain in ipairs(now.chains) do all.chains[#all.chains+1]=chain end
    end
    local p=journal.preferences(1)
    p.view="quests";p.selected="first-signal";p.chapter="calidus"
    p.chapter_cover=false
    journal.draw(player);absorb()
    p.chapter_cover=true
    journal.draw(player);absorb()
    p.chapter_cover=false
    -- One dossier for every quest: all kinds of titles and sections.
    for _,quest in ipairs(defs.quests) do
      p.selected=quest.id;p.chapter=quest.chapter
      journal.draw(player);absorb()
    end
    p.selected="first-signal";p.chapter="calidus"
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
  return ctx
end

-- Keys defined by locale/en/*.cfg, by section. Returns the set of
-- "section.key" and the set of section names.
function M.locale_keys()
  local keys,sections,files={}, {}, {}
  local handle=assert(io.popen('ls locale/en/*.cfg'))
  for name in handle:lines() do files[#files+1]=name end
  handle:close()
  for _,name in ipairs(files) do
    local section
    for line in assert(io.open(name,"r")):lines() do
      local head=line:match("^%[([^%]]+)%]%s*$")
      if head then
        section=head;sections[head]=true
      elseif section and line:match("^[^#;%s][^=]*=") then
        keys[section.."."..line:match("^([^=]+)=")]=true
      end
    end
  end
  return keys,sections
end

return M
