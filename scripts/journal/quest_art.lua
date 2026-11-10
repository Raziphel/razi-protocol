-- Pictures for quests: the sprite of a quest and the recipe gallery of a dossier.
local preview=require("scripts.journal.recipe_preview")
local icons=require("scripts.journal.icons")
local widgets=require("scripts.journal.widgets")
local L=widgets.L
local wrap=widgets.wrap
local subtitle=widgets.subtitle
local accent_rule=widgets.accent_rule
local quest_state=require("scripts.journal.quest_state")
local technology=quest_state.technology

-- All icons are resolved from the installed Factorio prototypes, not guessed
-- mod-specific assets. Keep work confined to visible GUI construction.
local function sprite_if_valid(path)
  if not path then return nil end
  if helpers and helpers.is_valid_sprite_path and
    not helpers.is_valid_sprite_path(path) then return nil end
  return path
end
local function quest_art(force,quest,context)
  if quest.world then
    local image=sprite_if_valid("space-location/"..quest.world)
    if image then return image end
  end
  local tech=technology(force,quest,context)
  return tech and sprite_if_valid("technology/"..tech.name)
    or "razi-journal-book-icon"
end

local function draw_gallery(parent,key,entries,width,max_items,theme)
  if #entries==0 then return end
  local block=parent.add{type="flow",direction="vertical"}
  block.style.vertical_spacing=5
  subtitle(block,key,width,theme)
  local columns=math.max(1,math.min(4,math.floor(width/215)))
  local card_width=math.max(180,math.floor((width-(columns-1)*7)/columns)-3)
  local grid=block.add{type="table",column_count=columns}
  grid.style.horizontal_spacing=7
  grid.style.vertical_spacing=7
  for i=1,math.min(max_items,#entries) do
    local entry=entries[i]
    local card=grid.add{type="flow",direction="horizontal"}
    card.style.width=card_width
    card.style.padding=4
    card.style.horizontal_spacing=7
    icons.sprite(card,entry.sprite,"gallery",entry.tooltip or entry.name)
    local caption=wrap(card,entry.name,card_width-54)
    caption.style.font_color=theme and theme.soft
      or {r=.86,g=.9,b=.94}
  end
  if #entries>max_items then
    wrap(block,L("more-gallery-items",tostring(#entries-max_items)),width)
  end
end
-- Exact recipe illustration for Razi's source-proven alternate processes.
-- Reads one recipe by ID only while its quest is viewed: no global scans.
local function recipe_gallery(parent,quest,native,width,theme)
  if not (quest.site and native and prototypes
      and prototypes.recipe) then return end
  local recipe=preview.recipe(quest,native,prototypes.recipe)
  if not recipe then return end
  local function cards(entries)
    local output={}
    for _,entry in ipairs(entries or {}) do
      local name=entry.name
      local kind=entry.type=="fluid" and "fluid" or "item"
      local proto=prototypes[kind] and prototypes[kind][name]
      local path=name and sprite_if_valid(kind.."/"..name)
      if proto and path then
        local caption={"",proto.localised_name,preview.quantity(entry)}
        output[#output+1]={sprite=path,name=caption,
          tooltip=caption}
      end
    end
    return output
  end
  local materials=cards(recipe.ingredients)
  local products=cards(recipe.products)
  if #materials==0 or #products==0 then return end
  local panel=parent.add{type="frame",direction="vertical",
    style="inside_deep_frame"}
  panel.style.width=width
  panel.style.padding=10
  subtitle(panel,"factory-diagram",width-26,theme)
  if theme then accent_rule(panel,theme,math.min(width-26,168),3) end
  wrap(panel,L("site-advisory",preview.workshop_fallback(quest,prototypes)),width-26)
  -- Existing machines and the original planet can be inspected before
  -- researching the optional production alternative.
  if quest.machine and prototypes.item and prototypes.item[quest.machine] then
    local machine=prototypes.item[quest.machine]
    local art=sprite_if_valid("item/"..quest.machine)
    if art then
      draw_gallery(panel,"factory-equipment",{
        {sprite=art,name=machine.localised_name,tooltip=machine.localised_name}
      },width-26,1,theme)
    end
  end
  draw_gallery(panel,"factory-imports",materials,width-26,10,theme)
  draw_gallery(panel,"factory-outputs",products,width-26,5,theme)
  wrap(panel,L(quest.optional and "factory-optional-note"
    or "factory-source-owned"),width-26)
end

return {quest_art=quest_art,recipe_gallery=recipe_gallery}
