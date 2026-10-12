-- Lightweight cross-system technology bridges for the existing Razi
-- worlds. Source planet unlock techs are discovered from real effects,
-- not guesses. No new recipes, science packs or additional surfaces.
local M={}
M.bridges={
  {"planet-discovery-corrundum","planet-discovery-apia-carnova"},
  {"planet-discovery-secretas","planet-discovery-tenebris"},
  {"planet-discovery-crucible","planet-discovery-cubium"},
  {"planet-discovery-frozeta","planet-discovery-crucible"}
}
M.phases={
  -- Pairwise gateways remain independent; only previously researched
  -- planet discoveries are candidates for the next paired frontier.
  {gates={"vibrant-discovery","vespera-discovery"},
   worlds={"igrys","foliax"}},
  {gates={"beetlejuice-discovery","umbra-discovery"},
   worlds={"cerys","obsidiax"}}
}
local function tech(name) return (data.raw.technology or {})[name] end
local function present(name)
  return (data.raw.planet or {})[name]
    or (data.raw["space-location"] or {})[name]
end
local function ancestor(start,wanted,seen)
  if start==wanted then return true end
  local node=tech(start)
  if not node then return false end
  seen=seen or {}
  if seen[start] then return false end
  seen[start]=true
  for _,parent in ipairs(node.prerequisites or {}) do
    if ancestor(parent,wanted,seen) then return true end
  end
  return false
end
local function active(name)
  local t=tech(name)
  return t and t.hidden~=true and t.enabled~=false
end
function M.safe_link(target,parent)
  if target==parent or not active(target) or not active(parent)
    or ancestor(parent,target) then return false end
  if not ancestor(target,parent) then
    local t=tech(target)
    t.prerequisites=t.prerequisites or {}
    t.prerequisites[#t.prerequisites+1]=parent
  end
  return true
end
local function native_unlocks()
  -- Build once from actual technology effects, not one catalogue scan
  -- per optional world. Stable ordering across repeated Factorio loads.
  local by_world={}
  for id,t in pairs(data.raw.technology or {}) do
    if active(id) then
      for _,effect in ipairs(t.effects or {}) do
        if effect.type=="unlock-space-location" and effect.space_location then
          local list=by_world[effect.space_location]
          if not list then list={} by_world[effect.space_location]=list end
          list[#list+1]=id
        end
      end
    end
  end
  for _,list in pairs(by_world) do table.sort(list) end
  return by_world
end
local function native_unlock(name,by_world)
  if not present(name) then return nil end
  for _,id in ipairs(by_world[name] or {}) do
    local t=tech(id)
    if t and (t.research_trigger
      or (t.unit and t.unit.ingredients and #t.unit.ingredients>0)) then
      return id
    end
  end
end
function M.data_final_fixes()
  for _,edge in ipairs(M.bridges) do M.safe_link(edge[1],edge[2]) end
  local sources=native_unlocks()
  for _,phase in ipairs(M.phases) do
    for _,name in ipairs(phase.worlds) do
      local candidate=native_unlock(name,sources)
      local safe=candidate~=nil
      if safe then
        -- Check BOTH parallel gates BEFORE touching either. An optional
        -- source that depends on a new frontier must not destroy the
        -- freedom to choose its paired systems in either order.
        for _,gateway in ipairs(phase.gates) do
          if not active(gateway) or ancestor(candidate,gateway) then
            safe=false;break
          end
        end
      end
      -- Some source mods place later-world sciences directly into a
      -- discovery's unit without making that pack a tech prerequisite.
      -- If the science technology exists and itself needs the next
      -- gateway, do not gate that gateway behind this source.
      if safe then
        for _,ingredient in ipairs((tech(candidate).unit or {}).ingredients or {}) do
          local pack=ingredient.name or ingredient[1]
          for _,gateway in ipairs(phase.gates) do
            if tech(pack) and ancestor(pack,gateway) then
              safe=false
              break
            end
          end
          if not safe then break end
        end
      end
      if safe then
        for _,gateway in ipairs(phase.gates) do
          M.safe_link(gateway,candidate)
        end
      end
    end
  end
end
return M
