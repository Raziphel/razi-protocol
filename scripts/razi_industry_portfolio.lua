-- A read-only overview of optional source-backed factory partnerships.
-- Drawn only when the Cargo Network page opens; no per-tick scans or storage.
-- Technology and recipe prototypes, not speculative cargo, determine entries.
local M={}
local journal=require("scripts.razi_journal_industry")
local cargo=require("scripts.galactic_trade_catalog")

local priority={ready=1,researched=2,blocked=3,disabled=4}
function M.snapshot(force,limit)
  local found={available=0,ready=0,researched=0,blocked=0,disabled=0,
    entries={}}
  if not force then return found end
  local technologies=force.technologies or {}
  local recipes=prototypes and prototypes.recipe or {}
  for _,quest in ipairs(journal.quests) do
    local tech=technologies[quest.tech]
    local recipe=recipes[quest.tech]
    if tech and recipe and (not tech.prototype or not tech.prototype.hidden) then
      local state=cargo.state(tech)
      if priority[state.status] then
        found.available=found.available+1
        found[state.status]=found[state.status]+1
        found.entries[#found.entries+1]={
          quest=quest,technology=tech,recipe=recipe,status=state.status,
          site=quest.site
        }
      end
    end
  end
  table.sort(found.entries,function(a,b)
    local a_rank=priority[a.status] or 10
    local b_rank=priority[b.status] or 10
    if a_rank~=b_rank then return a_rank<b_rank end
    return a.quest.id<b.quest.id
  end)
  local length=math.max(0,math.floor(limit or 8))
  while #found.entries>length do
    table.remove(found.entries)
  end
  return found
end
return M
