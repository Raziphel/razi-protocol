-- The singularity finale pulls together the planets you have discovered.
-- Look up their existing world-unlock research rather than hardcoding tech IDs.
local M={}
local techs=function() return data.raw.technology or {} end
local worlds={
  -- Calidus
  "muluna",
  -- Solaris
  "vulcanus","castra","arig","hyarion","tellus","corrundum",
  "igrys",
  -- Nyxaris
  "gleba","moshine","apia-carnova-orbit","panglia",
  "foliax","rabbasca","velora",
  -- Vibrant
  "fulgora","cerys","ribbonia","paracelsin",
  "khemia","ferrum",
  -- Vespera
  "muria","aquilo","rubia","maraxsis","obsidiax",
  "bm-balack",
  -- Beetlejuice
  "cubium","linox-planet_linox","secretas","frozeta",
  -- Umbra
  "tenebris","crucible","vesta","carna","arcanyx"
}
M.worlds=worlds

local function present(name)
  return (data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
end

local function reaches(start,target,seen)
  if start==target then return true end
  if not techs()[start] then return false end
  seen=seen or {}
  if seen[start] then return false end
  seen[start]=true
  for _,parent in ipairs(techs()[start].prerequisites or {}) do
    if reaches(parent,target,seen) then return true end
  end
  return false
end

local function index_destination_unlocks()
  -- One indexed pass through technologies avoids rescanning several thousand
  -- prototypes for every one of Razi's planets.
  local result={}
  for name,t in pairs(techs()) do
    if t.enabled~=false and not t.hidden then
      for _,effect in ipairs(t.effects or {}) do
        if effect.type=="unlock-space-location" and effect.space_location then
          local list=result[effect.space_location]
          if not list then list={} result[effect.space_location]=list end
          list[#list+1]=name
        end
      end
    end
  end
  for _,options in pairs(result) do table.sort(options) end
  return result
end

function M.data_final_fixes()
  local finale=techs()["razi-stable-intergalactic-singularity"]
  if not finale then return end
  local unlocks=index_destination_unlocks()
  local existing={}
  finale.prerequisites=finale.prerequisites or {}
  for _,prerequisite in ipairs(finale.prerequisites) do
    existing[prerequisite]=true
  end
  for _,world in ipairs(worlds) do
    if present(world) then
      for _,candidate in ipairs(unlocks[world] or {}) do
        -- Never cause a research loop. Worlds with late-game source-owned
        -- prerequisites (e.g. promethium) may need an author-specific
        -- milestone after runtime validation.
        if candidate~="razi-stable-intergalactic-singularity"
          and not reaches(candidate,"razi-stable-intergalactic-singularity")
          and not reaches("razi-stable-intergalactic-singularity",candidate) then
          if not existing[candidate] then
            finale.prerequisites[#finale.prerequisites+1]=candidate
            existing[candidate]=true
          end
          break
        end
      end
    end
  end
end

return M
