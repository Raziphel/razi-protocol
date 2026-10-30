-- ru mirrors the player-facing mechanics. Story text is shown only with the
-- story on or in writer mode, and authored text will replace it; its ru comes
-- after that. The list comes from story.text() calls in
-- scripts/razi_journal*.lua, scripts/razi_journal_projects.lua,
-- scripts/razi_convergence.lua and scripts/razi_welcome.lua (project contexts
-- are journal-ui keys, the Convergence slots razi-ops keys), plus the archive
-- notices of scripts/razi_story_dispatch.lua, which run only with the story on.
local STORY_REPLACED_PREFIXES={
  ["journal-story"]={""},
  ["journal-title"]={""},
  ["journal-tip"]={""},
  ["journal-mood"]={""},
  ["journal-chapter-summary"]={""},
  ["journal-chapter-story"]={""},
  ["journal-chapter-dispatch"]={""},
  ["journal-record-title"]={""},
  ["journal-record-origin"]={""},
  ["journal-record-body"]={""},
  ["razi-industries-brief"]={""},
  ["razi-planet-charter"]={""},
  ["razi-star-signature"]={""},
  ["razi-welcome"]={""},
  ["razi-story"]={""},
  ["journal-ui"]={"project-context-"},
  ["razi-ops"]={
    "convergence-witness-testimony-",
    "convergence-blackbox-"
  }
}
local STORY_REPLACED_KEYS={
  ["razi-ops.convergence-won"]=true,
  ["razi-ops.convergence-archive-message"]=true,
  ["razi-ops.convergence-transmission-sealed"]=true,
  ["razi-ops.convergence-transmission-dyson"]=true,
  ["razi-ops.convergence-transmission-resonance"]=true,
  ["razi-ops.convergence-transmission-alignment"]=true
}

local function check(ok,message)
  if not ok then error(message,2) end
end

local function trim(value)
  return (value:gsub("^%s+",""):gsub("%s+$",""))
end

local function read(path)
  local file=assert(io.open(path,"r"))
  local text=file:read("*a")
  file:close()
  return text
end

local function files(directory)
  local handle=io.popen("ls "..directory.."/*.cfg 2>/dev/null")
  local result={}
  for path in handle:lines() do result[#result+1]=path end
  handle:close()
  return result
end

local function locale_keys(directory)
  local found={}
  for _,path in ipairs(files(directory)) do
    local section
    local line_number=0
    for line in read(path):gmatch("([^\n]*)\n?") do
      line_number=line_number+1
      local value=trim(line)
      if value~="" and not value:match("^[#;]") then
        local header=value:match("^%[(.-)%]$")
        if header then
          section=trim(header)
        else
          local name,text=value:match("^([^=]+)=(.*)$")
          if name and section then
            local key=section.."."..trim(name)
            found[key]={value=text,path=path,line=line_number}
          end
        end
      end
    end
  end
  return found
end

local function is_story_file(path)
  local name=path:match("([^/]+)$") or path
  return name:match("^story%-.*%.cfg$")~=nil
end

local function is_story_replaced(key)
  if STORY_REPLACED_KEYS[key] then return true end
  local section,name=key:match("^([^.]+)%.(.+)$")
  for _,prefix in ipairs(STORY_REPLACED_PREFIXES[section] or {}) do
    if prefix=="" or name:sub(1,#prefix)==prefix then return true end
  end
  return false
end

local function placeholders(value)
  local found={}
  for token in value:gmatch("__%d+__") do found[token]=true end
  return found
end

local function same_set(left,right)
  for token in pairs(left) do if not right[token] then return false end end
  for token in pairs(right) do if not left[token] then return false end end
  return true
end

local function count(value,pattern)
  local _,total=value:gsub(pattern,"")
  return total
end

local function markup_counts(value,tag)
  local open=count(value,"%["..tag.."[^%]]*%]")
  local close=count(value,"%[/"..tag.."%]")
  return open,close
end

local english=locale_keys("locale/en")
local russian=locale_keys("locale/ru")
local extra,missing,placeholder_mismatches,markup_mismatches={},{},{},{}

for key in pairs(russian) do
  if not english[key] then extra[#extra+1]=key end
end
for key,entry in pairs(english) do
  local translation=russian[key]
  if not translation and not is_story_file(entry.path) and not is_story_replaced(key) then
    missing[#missing+1]=key
  elseif translation then
    if not same_set(placeholders(entry.value),placeholders(translation.value)) then
      placeholder_mismatches[#placeholder_mismatches+1]=key
    end
    for _,tag in ipairs({"color","font"}) do
      local en_open,en_close=markup_counts(entry.value,tag)
      local ru_open,ru_close=markup_counts(translation.value,tag)
      if en_open~=en_close or ru_open~=ru_close then
        markup_mismatches[#markup_mismatches+1]=key.." ["..tag.."]"
      end
    end
  end
end

table.sort(extra)
table.sort(missing)
table.sort(placeholder_mismatches)
table.sort(markup_mismatches)
print(string.format("Russian locale: en=%d ru=%d extra=%d missing=%d placeholders=%d markup=%d",
  (function() local n=0 for _ in pairs(english) do n=n+1 end return n end)(),
  (function() local n=0 for _ in pairs(russian) do n=n+1 end return n end)(),
  #extra,#missing,#placeholder_mismatches,#markup_mismatches))

local function brief(values)
  local shown={}
  for index=1,math.min(#values,12) do shown[#shown+1]=values[index] end
  if #values>12 then shown[#shown+1]="..." end
  return table.concat(shown,", ")
end

check(#extra==0,"Russian locale has keys absent from English: "..brief(extra))
check(#missing==0,"English player-facing keys are missing in Russian: "..brief(missing))
check(#placeholder_mismatches==0,"Placeholder mismatch: "..brief(placeholder_mismatches))
check(#markup_mismatches==0,"Color/font markup mismatch: "..brief(markup_mismatches))
print("Russian locale: every player-facing key and placeholder is aligned")
