-- Builds docs/story-slots.md, the list of the text slots of the storyline.
--
--   lua tools/story_slots.lua            print the list
--   lua tools/story_slots.lua --write    write docs/story-slots.md
--
-- Run it from the repository root. It reads the ids from the scripts that
-- show the text (quests, chapters, records, projects, welcome, Convergence)
-- and the slot kinds from scripts/razi_story_slots.lua. It never reads a
-- locale file: the list holds no text, only where text goes.
-- tests/lua/test_story_slots.lua fails when docs/story-slots.md is out of date.
package.path="./?.lua;./?/init.lua;"..package.path

local slots=require("scripts.razi_story_slots")
local defs=require("scripts.razi_journal_data")
---@type table[]
local records=require("scripts.razi_journal_records")
local briefs=require("scripts.razi_planet_briefs")
local projects=require("scripts.razi_journal_projects")
local welcome=require("scripts.razi_welcome")
local convergence=require("scripts.razi_convergence")

local M={}

local function sorted_keys(map)
  local list={}
  for key in pairs(map) do list[#list+1]=key end
  table.sort(list)
  return list
end

local function code(value) return "`"..value.."`" end

local function codes(list)
  local out={}
  for _,value in ipairs(list) do out[#out+1]=code(value) end
  return table.concat(out,", ")
end

-- What opens a quest, in words.
local function opens(quest)
  local parts={}
  if quest.convergence then
    parts[#parts+1]="Convergence stage "..code(quest.convergence)
  elseif quest.boss then
    parts[#parts+1]="Nexus boss "..code(quest.boss)
  elseif quest.tech then
    parts[#parts+1]="research "..code(quest.tech)
  elseif quest.world then
    parts[#parts+1]="discovery of "..code(quest.world)
  end
  if quest.requires and #quest.requires>0 then
    parts[#parts+1]="after quests "..codes(quest.requires)
  end
  return table.concat(parts,", ")
end

-- Rows of every kind: {id, where-detail, when}.
local function rows_for(kind)
  local rows={}
  local function add(id,detail,when) rows[#rows+1]={id=id,detail=detail,when=when} end
  if kind:match("^quest%-") and not (kind=="quest-brief" or kind=="quest-charter") then
    for _,quest in ipairs(defs.quests) do
      add(quest.id,"chapter "..code(quest.chapter),"quest opens with "..opens(quest))
    end
  elseif kind=="quest-brief" then
    for _,id in ipairs(sorted_keys(briefs.briefs)) do
      add(id,"quest "..code(id),"quest "..code(id).." is open")
    end
  elseif kind=="quest-charter" then
    for _,id in ipairs(sorted_keys(briefs.charters)) do
      add(id,"quest "..code(id),"quest "..code(id).." is open")
    end
  elseif kind=="chapter-star" then
    for _,chapter in ipairs(defs.chapters) do
      if briefs.stars[chapter.id] then
        add(chapter.id,"chapter "..code(chapter.id),"chapter cover is open")
      end
    end
  elseif kind:match("^chapter%-") then
    for _,chapter in ipairs(defs.chapters) do
      add(chapter.id,"chapter "..code(chapter.id),
        kind=="chapter-mood" and "chapter cover or a quest of the chapter is open"
          or "chapter cover is open")
    end
  elseif kind:match("^record%-") then
    for _,record in ipairs(records) do
      local series=record.id:sub(1,5)~="corp-" and "legacy"
        or record.series=="field" and "field" or "corporate"
      add(record.id,series.." record","quest "..code(record.unlock).." is complete")
    end
  elseif kind=="project-context" then
    for _,id in ipairs(projects.plain_ids) do
      add(id,"project "..code(id),"Projects tab, project "..code(id).." is open")
    end
  elseif kind=="welcome" then
    local function stage(status)
      for _,item in ipairs(welcome.stages) do
        if item.status==status then
          return item.research and ("research "..code(item.research)
            .." is done and no later stage") or "before the first stage"
        end
      end
    end
    add("header","first line","first join")
    add("identification","second line","first join")
    for index=#welcome.stages,1,-1 do
      add(welcome.stages[index].status,"third line",stage(welcome.stages[index].status))
    end
    add("intro","fourth line","first join")
    for index=#welcome.stages,1,-1 do
      local status=welcome.stages[index].status
      add(status:gsub("^status%-","priority-"),"fifth line",stage(status))
    end
    add("journal","sixth line, gets the unread count as __1__ and the spoiler setting as __2__",
      "first join")
    add("links","seventh line","first join")
    add("admin","eighth line","first join, admins only")
  elseif kind=="finale-testimony" then
    for _,system in ipairs(convergence.witness_systems) do
      add(system,"star system "..code(system),"a powered radar stands in the system")
    end
  elseif kind=="finale-blackbox" then
    local when={"Deep Space shipments are complete","Resonance shipments are complete",
      "the final shipment is accepted"}
    for index,text in ipairs(when) do add(tostring(index),"note "..index,text) end
  elseif kind=="finale-beat" then
    for _,beat in ipairs(convergence.transmission_beats) do
      add(beat.id,"beat at "..math.floor(beat.tick/60).." s","the transmission runs")
    end
  elseif kind=="finale" then
    add("won","panel line","the final shipment is accepted")
    add("archive-message","archive frame","the final shipment is accepted")
    add("blackbox-heading","black box frame heading","the first black box is recovered")
  end
  return rows
end

-- The ids of one kind, in list order.
function M.ids(kind)
  local ids={}
  for _,row in ipairs(rows_for(kind)) do ids[#ids+1]=row.id end
  return ids
end

function M.generate()
  local out={}
  local function line(text) out[#out+1]=text end
  line("# Story slots")
  line("")
  line("Generated by `lua tools/story_slots.lua --write`. Do not edit by hand.")
  line("")
  line("Each row is one place in the game where story text goes. The text is written in the")
  line("`.cfg` file and section named in the first column, as `key=text` with the key from the")
  line("second column. A slot without text shows a stub in writer mode. The length is an")
  line("estimate of how many characters fit without scrolling at 1920x1080, interface scale")
  line("100 %. How to write and test: [writing-guide.md](writing-guide.md).")
  line("")
  line("Not covered: the planet and route descriptions and the victory screen text. Those are")
  line("set when the game loads or for the whole game, so writer mode cannot show them.")
  for _,kind in ipairs(slots.order) do
    local slot=slots.kinds[kind]
    local rows=rows_for(kind)
    line("")
    line("## "..kind)
    line("")
    line("`locale/en/"..slot.file..".cfg`, section `["..slot.section.."]`: "..slot.where..". "
      ..#rows.." slots.")
    line("")
    line("| File and section | Key | Where seen | When it appears | Length |")
    line("| --- | --- | --- | --- | --- |")
    for _,row in ipairs(rows) do
      line("| "..slot.file..".cfg `["..slot.section.."]` | `"..row.id.."` | "..slot.where
        .."; "..row.detail.." | "..row.when.." | "..slot.length.." |")
    end
  end
  line("")
  return table.concat(out,"\n")
end

local function main()
  if arg and arg[1]=="--write" then
    local file=assert(io.open("docs/story-slots.md","w"))
    file:write(M.generate())
    file:close()
  else
    io.write(M.generate())
  end
end

if arg and arg[0] and arg[0]:match("^tools/story_slots%.lua$") then main() end
return M
