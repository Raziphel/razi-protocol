-- Non-mechanical editorial briefs for native planetary journal milestones.
-- No world is required to be explored in a particular order.
local briefs={
  castra="castra",
  moshine="moshine",
  gleba="gleba",
  fulgora="fulgora",
  paracelsin="paracelsin",
  aquilo="aquilo",
  rubia="rubia",
  panglia="panglia",
  athos="athos",
  nulla="nulla",
  tenebris="tenebris",
  vesta="vesta"
}
local M={}
function M.for_quest(quest)
  return quest and briefs[quest.id] or nil
end
M.briefs=briefs
return M
