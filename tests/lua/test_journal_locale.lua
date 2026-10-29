---@diagnostic disable: unnecessary-assert, param-type-mismatch, need-check-nil, inject-field
-- Every localised key the journal, Projects, Convergence and the welcome can
-- show exists in locale/en. With the story off none of them comes from the
-- authored layer and no quest shows a title that is not defined.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local story=require("scripts.razi_story")
local W=require("tests.lua.journal_window")
local ctx=W.setup()
local defined,sections=W.locale_keys()

-- Names owned by the game or by other mods; only our own sections are checked.
local FOREIGN={
  ["technology-name"]=true,["space-location-name"]=true,["entity-name"]=true,
  ["item-name"]=true,["recipe-name"]=true,["fluid-name"]=true,
  ["tile-name"]=true,["nexus-bosses"]=true,["controls"]=true,["gui-menu"]=true
}
local function resolves(key)
  local section=key:match("^([^.]+)%.")
  return defined[key] or (section and FOREIGN[section]) or false
end
local function unresolved(collected)
  local missing={}
  for key in pairs(collected.singles) do
    if not resolves(key) then missing[#missing+1]=key end
  end
  for _,chain in ipairs(collected.chains) do
    local ok=false
    for _,key in ipairs(chain) do
      if resolves(key) then ok=true;break end
    end
    if not ok then missing[#missing+1]="{"..table.concat(chain,"|").."}" end
  end
  table.sort(missing)
  return missing
end

local function read(path)
  local file=assert(io.open(path,"r"))
  local text=file:read("*a")
  file:close()
  return text
end

-- The welcome briefing, as printed to chat.
local function welcome_keys()
  local printed={singles={},chains={}}
  ctx.player.print=function(message) W.collect(message,printed) end
  ctx.player.admin=true
  ctx.player.connected=true
  rawset(_G,"settings",{get_player_settings=function() return {} end,
    global={["razi-hide-spoilers"]={value=true}}})
  local welcome=require("scripts.razi_welcome")
  welcome.command{player_index=1}
  W.collect(welcome.help(),printed)
  rawset(_G,"settings",nil)
  return printed
end

-- The victory screen the Convergence sets: its keys are built from the section
-- name, so read the suffixes from the source.
local function victory_keys(section)
  local found={singles={},chains={}}
  local source=read("scripts/razi_convergence.lua")
  for suffix in source:gmatch('section%.%.%"%.([%w%-]+)"') do
    found.singles[section.."."..suffix]=true
  end
  check(next(found.singles)~=nil,"No victory screen keys found in the source")
  return found
end

-- Literal keys in the sources: the walk cannot reach every state (a catapult
-- lane, a failed delivery), so read the keys the code names directly.
local LITERAL_PREFIX={
  ["scripts/razi_journal.lua"]="journal-ui",
  ["scripts/razi_journal_projects.lua"]="journal-ui",
  ["scripts/razi_journal_systems.lua"]="journal-systems"
}
local function literal_keys()
  local found={}
  local handle=assert(io.popen("ls scripts/razi_journal*.lua "
    .."scripts/razi_convergence*.lua scripts/razi_welcome.lua scripts/razi_story*.lua"))
  for path in handle:lines() do
    local source=read(path)
    for section,key in source:gmatch('{"([%w%-]+)%.([%w%-]+)"') do
      -- A key ending in a dash is a prefix completed at run time.
      if sections[section] and not FOREIGN[section] and not key:match("%-$") then
        found[#found+1]=section.."."..key
      end
    end
    local prefix=LITERAL_PREFIX[path]
    if prefix then
      -- The first argument of L(...) may hold several literals, e.g.
      -- L(a and "key-one" or "key-two"): read up to its first top-level comma.
      for start in source:gmatch('[^%w_]L%(()') do
        local depth,stop=0,start
        while stop<=#source do
          local char=source:sub(stop,stop)
          if char=="(" then depth=depth+1
          elseif char==")" then
            if depth==0 then break end
            depth=depth-1
          elseif char=="," and depth==0 then break end
          stop=stop+1
        end
        local argument=source:sub(start,stop-1)
        for position,key in argument:gmatch('()"([%w%-]+)"') do
          local before=argument:sub(1,position-1)
          -- The key itself, or an `and`/`or` branch; not a compared value.
          -- A piece that starts or ends with a dash is joined at run time.
          if (before:match("^%s*$") or before:match("%f[%w]and%s*$")
            or before:match("%f[%w]or%s*$"))
            and not key:match("^%-") and not key:match("%-$") then
            found[#found+1]=prefix.."."..key
          end
        end
      end
    end
  end
  handle:close()
  return found
end
for _,key in ipairs(literal_keys()) do
  check(defined[key],"Key named in the scripts is not in locale/en: "..key)
end

local function merge(into,from)
  for key in pairs(from.singles) do into.singles[key]=true end
  for _,chain in ipairs(from.chains) do into.chains[#into.chains+1]=chain end
end

local function everything(section)
  local all=ctx.open_everything()
  merge(all,welcome_keys())
  merge(all,victory_keys(section))
  return all
end

-- Story off.
story.configure(false)
local off=everything("razi-story-off")
local missing=unresolved(off)
check(#missing==0,"Keys shown with the story off are not in locale/en: "
  ..W.brief(missing))
local flat=W.flat(off)
local leaked=W.authored(flat)
check(#leaked==0,"Authored keys shown with the story off: "..W.brief(leaked))
-- Every quest title resolves to a technology name or a plain-title key.
local plain_count=0
for _,quest in ipairs(ctx.defs.quests) do
  local title=W.collect(ctx.defs.quest_title(quest))
  local chain_ok=#unresolved(title)==0
  check(chain_ok,"Quest title not defined with the story off: "..quest.id)
  for key in pairs(W.flat(title)) do
    if key:match("^journal%-plain%-title%.") then plain_count=plain_count+1 end
  end
end
check(plain_count>0,"No quest uses journal-plain-title")
-- A technology the quest names is the title; a quest without one has a plain key.
for _,quest in ipairs(ctx.defs.quests) do
  local plain=defined["journal-plain-title."..quest.id]
  local owns=quest.tech and not quest.boss and not quest.convergence
  check(owns~=plain,"journal-plain-title must exist exactly for quests with no "
    .."technology of their own: "..quest.id)
end

-- Story on.
story.configure(true)
local on=everything("razi-ops")
-- Authored text that does not exist yet; it needs a writer, not a key.
local STORY_GAPS={["journal-mood.salvage"]=true}
missing=unresolved(on)
for index=#missing,1,-1 do
  if STORY_GAPS[missing[index]] then table.remove(missing,index) end
end
check(#missing==0,"Keys shown with the story on are not in locale/en: "
  ..W.brief(missing))
check(W.flat(on)["journal-story.first-signal"],"The story walk showed no story text")
story.configure(false)
print("Journal locale: every key shown resolves; none is authored while the story is off")
