-- Non-mechanical, native-milestone-linked industrial dossier references.
-- These are suggested *relationships*, not mandatory routing or quest gates.
local briefs={
  castra="castra",
  moshine="moshine",
  gleba="gleba",
  fulgora="fulgora",
  paracelsin="paracelsin",
  muria="muria",
  aquilo="aquilo",
  rubia="rubia",
  panglia="panglia",
  athos="athos",
  nulla="nulla",
  tenebris="tenebris",
  vesta="vesta"
}
-- Never assume a suggested world is installed or unlocked.
-- Journal filters links through M.available() at the time of viewing.
local connections={
  castra={"arig","hyarion"},
  moshine={"panglia","paracelsin"},
  gleba={"moshine","rubia"},
  fulgora={"paracelsin","aquilo"},
  paracelsin={"rubia","moshine"},
  muria={"rubia","aquilo"},
  aquilo={"muria","rubia","nulla"},
  rubia={"muria","aquilo","tenebris","vesta"},
  panglia={"moshine","gleba"},
  athos={"nulla","outer-mastery"},
  nulla={"athos","outer-mastery"},
  tenebris={"vesta","rubia"},
  vesta={"outer-mastery","tenebris"}
}
local M={}
function M.for_quest(quest)
  return quest and briefs[quest.id] or nil
end
function M.related(quest,by_id)
  local result={}
  if not (quest and by_id) then return result end
  for _,id in ipairs(connections[quest.id] or {}) do
    local target=by_id[id]
    if target and target.id~=quest.id then result[#result+1]=target end
  end
  return result
end
M.briefs=briefs
M.connections=connections
return M
