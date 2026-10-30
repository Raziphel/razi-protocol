---@diagnostic disable: unnecessary-assert, param-type-mismatch, need-check-nil, inject-field
-- The slot list (docs/story-slots.md, built by tools/story_slots.lua) is
-- current, and every key in locale/en/story-*.cfg names a real slot.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local slots=require("scripts.razi_story_slots")
local generator=dofile("tools/story_slots.lua")

local function read(path)
  local file=assert(io.open(path,"r"),"cannot open "..path)
  local text=file:read("*a")
  file:close()
  return text
end

check(read("docs/story-slots.md")==generator.generate(),
  "docs/story-slots.md is out of date: run lua tools/story_slots.lua --write")

-- Every kind: one section in one file, no section used twice.
local owner={}
for _,kind in ipairs(slots.order) do
  local slot=slots.kinds[kind]
  check(slot,"Kind in the order but not defined: "..kind)
  check(slot.length and slot.length>0 and slot.where and slot.file and slot.section,
    "Incomplete slot kind: "..kind)
  check(not owner[slot.section],"Section used by two kinds: "..slot.section)
  owner[slot.section]={kind=kind,file=slot.file}
  check(#generator.ids(kind)>0,"A kind with no slots: "..kind)
end
local count=0
for _ in pairs(slots.kinds) do count=count+1 end
check(count==#slots.order,"A kind is missing from the order")

-- Every locale file of the writer: known sections, known ids.
local ids={}
for _,kind in ipairs(slots.order) do
  local set={}
  for _,id in ipairs(generator.ids(kind)) do set[id]=true end
  ids[kind]=set
end
local keys=0
for _,name in ipairs(slots.files) do
  local section
  local seen={}
  for line in assert(io.open("locale/en/"..name..".cfg","r")):lines() do
    local head=line:match("^%[([^%]]+)%]%s*$")
    if head then
      local entry=owner[head]
      check(entry,name..": unknown section ["..head.."]")
      check(entry.file==name,name..": section ["..head.."] belongs to "..entry.file..".cfg")
      section=entry
      seen[head]=true
    elseif line:match("^[^#;%s][^=]*=") then
      check(section,name..": a key before any section: "..line)
      local key=line:match("^([^=]+)=")
      check(ids[section.kind][key],
        name..": "..key.." is not a slot of "..section.kind.." (see docs/story-slots.md)")
      keys=keys+1
    end
  end
  for _,kind in ipairs(slots.order) do
    local slot=slots.kinds[kind]
    if slot.file==name then
      check(seen[slot.section],name..": section ["..slot.section.."] is missing")
    end
  end
end
print("Story slots: list current, "..keys.." keys in locale/en/story-*.cfg, all are slots")
