-- On-demand research overview for the large Razi planet pack.
-- No periodic scans, automatic queue modification or hidden world unlocks.
local M={}
local function L(key,...) return {"razi-ops."..key,...} end
local systems={
  {"calidus","space-science-pack","calidus-tech-card",
    {"planet-discovery-muluna"}},
  {"solaris","solaris-discovery","solaris-tech-card",
    {"planet-discovery-vulcanus","planet-discovery-castra",
     "planet-discovery-arig","planet-discovery-hyarion",
     "planet-discovery-tellus","planet-discovery-corrundum"}},
  {"nyxaris","nyxaris-discovery","nyxaris-tech-card",
    {"planet-discovery-gleba","planet-discovery-moshine",
     "planet-discovery-apia-carnova","panglia_planet_discovery_panglia"}},
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
  {"deep-space","stellar-discovery-solar-system-edge","deep-space-tech-card",
    {"razi-outer-frontier-mastery","razi-singularity-theory",
     "razi-singularity-test-fire","razi-stable-intergalactic-singularity",
     "razi-intergalactic-transceiver-signal"}}
}
M.systems=systems
-- Eight restrained chapter accents, reused for one short progress bar and
-- a single heading. The actual tech-card icons are source-owned assets.
M.palette={
  calidus={r=.94,g=.77,b=.46},
  solaris={r=.94,g=.56,b=.37},
  nyxaris={r=.44,g=.80,b=.65},
  vibrant={r=.59,g=.62,b=.93},
  vespera={r=.83,g=.87,b=.91},
  beetlejuice={r=.91,g=.52,b=.70},
  umbra={r=.81,g=.55,b=.38},
  ["deep-space"]={r=.57,g=.68,b=.91}
}
-- Use the same declaration as data-stage registration so the Campaign
-- never advertises freight alternatives that were not installed.
local multiplex_by_card={}
for _,rule in ipairs(require("prototypes.compat.system_card_manufacturing").rules) do
  multiplex_by_card[rule.card]=rule.name
end
M.multiplex_by_card=multiplex_by_card
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
-- A research unit's price alone hides the actual number of late-tier
-- cards needed. Read the installed technology rather than guessing a
-- fixed K2SO science mixture or changing the game's research cost.
function M.direct_science_demand(technology)
  local count=technology and technology.research_unit_count
  if type(count)~="number" or count<=0 then return {} end
  local result={}
  for _,pack in ipairs(technology.research_unit_ingredients or {}) do
    local name=pack.name or pack[1]
    local amount=pack.amount or pack[2] or 1
    if name and type(amount)=="number" and amount>0 then
      result[#result+1]={name=name,count=count*amount}
    end
  end
  table.sort(result,function(a,b) return a.name<b.name end)
  return result
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
    head.style.vertical_align="center"
    -- A single 20px science-card sprite; never a scaled-up technology icon.
    if prototypes and prototypes.item and prototypes.item[system[3]] then
      local marker=head.add{type="sprite",sprite="item/"..system[3],
        resize_to_sprite=false}
      marker.style.size=20
      marker.style.stretch_image_to_widget_size=true
    end
    local label_name=label(head,L("group-"..system[1]))
    label_name.style.font="default-bold"
    label_name.style.font_color=M.palette[system[1]]
    local actual=discoveries[system[1]]
    local finished,total,pending=M.progress(player.force,
      actual and #actual>0 and actual or system[4])
    label(head,L("campaign-count",tostring(finished),tostring(total)))
    if total>0 then
      local bar=section.add{type="progressbar",value=finished/total}
      bar.style.horizontally_stretchable=true
      bar.style.height=5
      bar.style.color=M.palette[system[1]]
    end
    local gate=player.force.technologies[system[2]]
    if gate then
      local gate_label=label(section,{"",L("campaign-gate")," ",
        gate.researched and L("atlas-done") or L("atlas-pending")," ",
        name(gate,system[2])})
      if not gate.researched then
        local demand=M.direct_science_demand(gate)
        if #demand>0 then
          label(section,L("campaign-science-demand"))
          for i=1,math.min(4,#demand) do
            local item=demand[i]
            local proto=prototypes and prototypes.item
              and prototypes.item[item.name]
            label(section,{"","  ",tostring(item.count)," × ",
              proto and proto.localised_name or item.name})
          end
          if #demand>4 then
            label(section,L("campaign-science-more",tostring(#demand-4)))
          end
        end
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
    local freight_id=multiplex_by_card[system[3]]
    local freight=freight_id and player.force.recipes
      and player.force.recipes[freight_id]
    if freight then
      label(section,{"  ",L(freight.enabled
        and "campaign-multiplex-ready" or "campaign-multiplex-pending")})
    end
    for i=1,math.min(3,#pending) do
      label(section,{"",L("campaign-pending")," ",name(pending[i],pending[i].name)})
    end
  end
end
return M
