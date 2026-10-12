-- On-demand research overview for the large Razi planet pack.
-- No periodic scans, automatic queue modification or hidden world unlocks.
local M={}
local function L(key,...) return {"razi-ops."..key,...} end
local systems={
  {"calidus","space-science-pack","calidus-tech-card",
    {"planet-discovery-muluna","moon-discovery-eneas"}},
  {"solaris","solaris-discovery","solaris-tech-card",
    {"planet-discovery-vulcanus","planet-discovery-castra",
     "planet-discovery-arig","planet-discovery-hyarion",
     "planet-discovery-tellus","planet-discovery-corrundum"}},
  {"nyxaris","nyxaris-discovery","nyxaris-tech-card",
    {"planet-discovery-gleba","planet-discovery-moshine",
     "planet-discovery-apia-carnova"}},
  {"vibrant","vibrant-discovery","vibrant-tech-card",
    {"planet-discovery-fulgora","moon-discovery-cerys",
     "planet-discovery-ribbonia",
     "planet-discovery-paracelsin"}},
  {"vespera","vespera-discovery","vespera-tech-card",
    {"planet-discovery-muria","planet-discovery-aquilo",
     "planet-discovery-rubia","planet-discovery-maraxsis"}},
  {"beetlejuice","beetlejuice-discovery","beetlejuice-tech-card",
    {"planet-discovery-cubium","linox-technology_planet-discovery-linox",
     "planet-discovery-secretas","planet-discovery-frozeta"}},
  {"umbra","umbra-discovery","umbra-tech-card",
    {"planet-discovery-tenebris","planet-discovery-crucible",
     "planet-discovery-vesta"}},
  {"deep-space","razi-outer-frontier-mastery","deep-space-tech-card",
    {"razi-singularity-theory","razi-singularity-test-fire",
     "razi-stable-intergalactic-singularity"}}
}
M.systems=systems
local function name(t,id)
  return t and t.localised_name or id
end
function M.progress(force,milestones)
  local finished,total,pending=0,0,{}
  for _,id in ipairs(milestones) do
    local tech=force.technologies[id]
    if tech then
      total=total+1
      if tech.researched then finished=finished+1
      else pending[#pending+1]=tech end
    end
  end
  return finished,total,pending
end
function M.blockers(technology,limit)
  local missing={}
  for _,prior in pairs(technology.prerequisites or {}) do
    if not prior.researched then missing[#missing+1]=prior end
  end
  table.sort(missing,function(a,b) return a.name<b.name end)
  local result={}
  for i=1,math.min(#missing,limit or 3) do result[i]=missing[i] end
  return result,#missing
end
-- Index the real installed planet unlock effects once per explicit UI
-- refresh, so supported moons/side worlds appear without maintaining a
-- fragile per-mod list of guessed technology identifiers.
function M.discovery_index(force)
  local catalog=require("scripts.galactic_catalog")
  local by_group={}
  local seen={}
  for _,tech in pairs(force.technologies or {}) do
    local proto=tech.prototype
    for _,effect in ipairs(proto and proto.effects or {}) do
      if effect.type=="unlock-space-location" and effect.space_location then
        local group=catalog.system(effect.space_location)
        if group~="unassigned" then
          by_group[group]=by_group[group] or {}
          seen[group]=seen[group] or {}
          if not seen[group][tech.name] then
            seen[group][tech.name]=true
            by_group[group][#by_group[group]+1]=tech.name
          end
        end
      end
    end
  end
  for _,names in pairs(by_group) do table.sort(names) end
  return by_group
end
local function label(parent,caption)
  return parent.add{type="label",caption=caption}
end
function M.render(parent,player)
  local header=parent.add{type="flow",direction="horizontal"}
  local title=label(header,L("campaign-title"))
  title.style.font="heading-2"
  label(parent,L("campaign-explanation"))
  local pane=parent.add{type="scroll-pane",direction="vertical"}
  pane.style.horizontally_stretchable=true
  pane.style.height=math.max(260,math.min(530,
    math.floor(player.display_resolution.height/math.max(player.display_scale,1)*0.55)))
  local discoveries=M.discovery_index(player.force)
  for _,system in ipairs(systems) do
    local section=pane.add{type="frame",style="inside_shallow_frame",
      direction="vertical"}
    section.style.horizontally_stretchable=true
    local head=section.add{type="flow",direction="horizontal"}
    local label_name=label(head,L("group-"..system[1]))
    label_name.style.font="default-bold"
    local actual=discoveries[system[1]]
    local finished,total,pending=M.progress(player.force,
      actual and #actual>0 and actual or system[4])
    label(head,L("campaign-count",tostring(finished),tostring(total)))
    local gate=player.force.technologies[system[2]]
    if gate then
      local gate_label=label(section,{"",L("campaign-gate")," ",
        gate.researched and L("atlas-done") or L("atlas-pending")," ",
        name(gate,system[2])})
      if not gate.researched then
        local missing,n=M.blockers(gate,3)
        if n==0 then label(section,L("campaign-ready"))
        else
          for _,tech in ipairs(missing) do
            label(section,{"",L("campaign-blocker")," ",name(tech,tech.name)})
          end
          if n>#missing then label(section,L("campaign-more",tostring(n-#missing))) end
        end
      end
    end
    local recipe=player.force.recipes and player.force.recipes[system[3]]
    label(section,{"",L("campaign-card")," ",
      recipe and recipe.enabled and L("campaign-card-ready")
        or L("campaign-card-pending")})
    for i=1,math.min(3,#pending) do
      label(section,{"",L("campaign-pending")," ",name(pending[i],pending[i].name)})
    end
  end
end
return M
