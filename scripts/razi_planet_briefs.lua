-- Non-mechanical, native-milestone-linked industrial dossier references.
-- These are suggested *relationships*, not mandatory routing or quest gates.
local briefs={
  vulcanus="vulcanus",
  castra="castra",
  moshine="moshine",
  gleba="gleba",
  fulgora="fulgora",
  paracelsin="paracelsin",
  muria="muria",
  maraxsis="maraxsis",
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
  vulcanus={"castra"},
  castra={"vulcanus","arig","hyarion"},
  moshine={"gleba","panglia","paracelsin"},
  gleba={"moshine","rubia"},
  fulgora={"paracelsin","aquilo"},
  paracelsin={"rubia","moshine"},
  muria={"rubia","aquilo"},
  maraxsis={"rubia","aquilo"},
  aquilo={"muria","rubia","nulla"},
  rubia={"muria","aquilo","maraxsis","tenebris","vesta"},
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

-- B.1 planetary field charters are optional OPERATING ADVICE, not
-- technologies, saved missions, shipment evidence or progression gates.
-- Both the Journal and the recipe-backed Freight Desk share these keys.
local charters={
  muluna=true,
  vulcanus=true,
  castra=true,
  arig=true,
  hyarion=true,
  tellus=true,
  corrundum=true,
  gleba=true,
  moshine=true,
  apia=true,
  panglia=true,
  fulgora=true,
  cerys=true,
  ribbonia=true,
  paracelsin=true,
  muria=true,
  athos=true,
  rubia=true,
  aquilo=true,
  nulla=true,
  maraxsis=true,
  cubium=true,
  linox=true,
  secretas=true,
  frozeta=true,
  tenebris=true,
  crucible=true,
  vesta=true,
  abacayba=true,
}
-- These links point only to existing Codex IDs. They are filtered against
-- actually installed and spoiler-visible milestones at render time.
local charter_paths={
  muluna={"space-science","solaris-gate"},
  vulcanus={"castra","corrundum"},
  castra={"arig","hyarion"},
  arig={"hyarion","tellus"},
  hyarion={"arig","tellus"},
  tellus={"corrundum"},
  corrundum={"vibrant-gate","vespera-gate"},
  gleba={"moshine","apia"},
  moshine={"panglia","gleba"},
  apia={"panglia","vibrant-gate"},
  panglia={"panglia-biooptic-trade","panglia-optical-return"},
  fulgora={"cerys","paracelsin"},
  cerys={"paracelsin"},
  ribbonia={"asteroid-belt"},
  paracelsin={"beetlejuice-gate","umbra-gate"},
  muria={"athos","rubia"},
  athos={"athos-particulate","frontier-recovery-charter"},
  rubia={"aquilo","maraxsis"},
  aquilo={"nulla","maraxsis"},
  nulla={"nulla-robotic-science","frontier-recovery-charter"},
  maraxsis={"seadragon","beetlejuice-gate"},
  cubium={"linox","secretas"},
  linox={"outer-mastery"},
  secretas={"frozeta"},
  frozeta={"outer-mastery"},
  tenebris={"crucible","vesta"},
  crucible={"vesta"},
  vesta={"abacayba","outer-mastery"},
  abacayba={"outer-mastery"},
}
function M.charter_for_quest(quest)
  return quest and charters[quest.id] and quest.id or nil
end
function M.charter_for_site(site)
  return type(site)=="string" and charters[site] and site or nil
end
function M.visible_related(quest,by_id,visible,limit)
  local result={}
  if not (quest and by_id and type(visible)=="function") then return result end
  local max=math.max(0,math.min(3,math.floor(tonumber(limit) or 2)))
  if max==0 then return result end
  local seen={}
  for _,id in ipairs(charter_paths[quest.id] or connections[quest.id] or {}) do
    local target=by_id[id]
    if target and target.id~=quest.id and not seen[id] and visible(target) then
      seen[id]=true
      result[#result+1]=target
      if #result>=max then break end
    end
  end
  return result
end
M.charters=charters
M.charter_paths=charter_paths
-- Chapter-level system personalities. Only show a signature on its own
-- already visible chapter cover; never unveil a sealed destination.
local stars={
  calidus=true,solaris=true,nyxaris=true,vibrant=true,
  vespera=true,beetlejuice=true,umbra=true
}
function M.star_charter(id)
  return type(id)=="string" and stars[id] and id or nil
end
M.stars=stars
-- Optional detours with REAL physical project evidence. These are links to
-- existing source-backed projects, not another set of completion counters.
local charter_projects={
  muluna="voyage",
  vulcanus="skybridge",castra="skybridge",arig="skybridge",
  hyarion="skybridge",gleba="skybridge",moshine="skybridge",
  muria="skybridge",rubia="skybridge",maraxsis="skybridge",
  aquilo="skybridge",fulgora="beltbreaker",ribbonia="beltbreaker",
  paracelsin="beltbreaker",tenebris="beltbreaker",crucible="beltbreaker",
  vesta="array",linox="ark",secretas="ark",frozeta="ark",
  abacayba="ark"
}
function M.project_for_quest(quest)
  return quest and charter_projects[quest.id] or nil
end
M.charter_projects=charter_projects

M.briefs=briefs
M.connections=connections
return M
