---@diagnostic disable: unnecessary-assert
-- The journal draws its status marks with rich-text sprites. Geometric glyphs
-- such as check marks, circles and triangles are missing from the default
-- fonts, so no caption or locale string of the journal may contain them.
-- The authored welcome header (story layer) is not checked.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,message) if not ok then error(message,2) end end

local GLYPHS={"✓","●","○","▾","▸","◇","↻"}
local function read(path)
  local file=assert(io.open(path,"r"))
  local text=file:read("*a")
  file:close()
  return text
end

local handle=assert(io.popen("ls scripts/razi_journal*.lua scripts/galactic_dyson.lua "
  .."scripts/razi_convergence*.lua scripts/razi_welcome.lua scripts/razi_story*.lua "
  .."locale/en/razi_journal*.cfg locale/en/galactic_operations.cfg "
  .."locale/en/razi_story_off.cfg locale/en/razi_audit.cfg"))
local found={}
for path in handle:lines() do
  local text=read(path)
  for _,glyph in ipairs(GLYPHS) do
    if text:find(glyph,1,true) then found[#found+1]=path..": "..glyph end
  end
end
handle:close()
check(#found==0,"Glyphs missing from the game fonts: "..table.concat(found,", "))

local marks=require("scripts.razi_journal_marks")
for name,mark in pairs(marks) do
  check(mark:match("^%[img=utility/[%w_]+%]$"),"Mark is not a utility sprite: "..name)
end
print("Journal glyphs: no font-dependent glyphs in captions or locale")
