-- Compact read-only overview for the existing SLP Dyson Sphere 2.1 port.
-- Never mirror or mutate the source mod's satellite/repeater state. Those
-- structures have their own controls; tech research is not physical progress.
local M={}
local L=function(name,...) return {"razi-ops."..name,...} end
M.stages={
 {"planet-discovery-sunorbit","dyson-outer"},
 {"slp-solar-system-sun2","dyson-inner"},
 {"slp-dyson-sphere","dyson-construction"},
 {"slp-dyson-sphere-grounded","dyson-repeater"},
 {"ds-energy-loader-mk2","dyson-mk2"},
 {"ds-energy-loader-mk3","dyson-mk3"}
}
local function label(parent,caption)
 return parent.add{type="label",caption=caption}
end
function M.status(force)
 local stages,total,completed={},0,0
 for _,stage in ipairs(M.stages) do
   local t=force.technologies[stage[1]]
   if t then
     total=total+1
     if t.researched then completed=completed+1 end
     stages[#stages+1]={tech=t,heading=stage[2]}
   end
 end
 return completed,total,stages
end
function M.render(parent,player)
 local head=label(parent,L("dyson-title"))
 head.style.font="heading-2"
 label(parent,L("dyson-subtitle"))
 local completed,total,stages=M.status(player.force)
 label(parent,L("dyson-stage-progress",tostring(completed),tostring(total)))
 if total>0 then
   local progress=parent.add{type="progressbar",
     value=completed/math.max(total,1)}
   progress.style.horizontally_stretchable=true
 end
 local scroll=parent.add{type="scroll-pane",direction="vertical"}
 scroll.style.height=math.max(240,math.min(480,
   math.floor(player.display_resolution.height/math.max(player.display_scale,1)*0.50)))
 scroll.style.horizontally_stretchable=true
 for _,stage in ipairs(stages) do
   local frame=scroll.add{type="frame",direction="vertical",
     style="inside_shallow_frame"}
   frame.style.horizontally_stretchable=true
   local h=frame.add{type="flow",direction="horizontal"}
   local caption=label(h,L(stage.heading))
   caption.style.font="default-bold"
   label(h,stage.tech.researched and L("dyson-completed")
      or L("dyson-pending"))
   if not stage.tech.researched then
     local missing={}
     for _,prereq in pairs(stage.tech.prerequisites or {}) do
       if not prereq.researched then missing[#missing+1]=prereq end
     end
     table.sort(missing,function(a,b)return a.name<b.name end)
     for i=1,math.min(#missing,3) do
       label(frame,{"",L("dyson-requires")," ",missing[i].localised_name})
     end
     if #missing==0 then label(frame,L("dyson-ready")) end
   end
 end
 if total==0 then label(parent,L("dyson-unavailable")) end
 label(parent,L("dyson-satellites"))
 label(parent,L("dyson-safety"))
end
return M
