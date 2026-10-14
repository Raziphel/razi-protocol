-- Read-only Stelllar Works. Research is real; satellites and network MW
-- are unknown until the source mod exposes an official telemetry API.
local M={}
local L=function(name,...) return {"razi-ops."..name,...} end
local runtime=require("scripts.galactic_dyson_runtime")
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
   if t and not (t.prototype and t.prototype.hidden) then
     total=total+1
     if t.researched then completed=completed+1 end
     stages[#stages+1]={tech=t,heading=stage[2]}
   end
 end
 return completed,total,stages
end
function M.research_phase(completed)
 if completed>=6 then return "mastery" end
 if completed>=4 then return "distribution" end
 if completed>=3 then return "construction" end
 if completed>=2 then return "plasma" end
 return "survey"
end
local function inspection(parent,player)
 local status=runtime.snapshot(player.force)
 local frame=parent.add{type="frame",direction="vertical",
   style="inside_shallow_frame"}
 frame.style.horizontally_stretchable=true
 local title=label(frame,L("dyson-infrastructure-heading"))
 title.style.font="default-bold"
 if status.physical_available then
   label(frame,L("dyson-receivers",tostring(status.receivers)))
   if #status.sites==0 then
     label(frame,L("dyson-no-sites"))
   else
     for i=1,math.min(#status.sites,12) do
       local site=status.sites[i]
       label(frame,L("dyson-receiver-site",site.name,tostring(site.count)))
     end
     if #status.sites>12 then
       label(frame,L("dyson-site-overflow",tostring(#status.sites-12)))
     end
   end
 else
   label(frame,L("dyson-receivers-unknown"))
 end
 label(frame,L("dyson-source-telemetry-unknown"))
end
function M.render(parent,player,options)
 options=options or {}
 if not options.embedded then
   local heading=parent.add{type="flow",direction="horizontal"}
   heading.style.horizontally_stretchable=true
   local title=label(heading,L("dyson-title"))
   title.style.font="heading-2"
 end
 local completed,total,stages=M.status(player.force)
 local phase=M.research_phase(completed)
 local hero=parent.add{type="frame",direction="horizontal",
   style="inside_deep_frame"}
 hero.style.padding=12
 hero.style.horizontally_stretchable=true
 local art=hero.add{type="sprite",
   sprite="razi-dyson-works-stage-"..math.min(6,completed)}
 art.resize_to_sprite=false
 local art_size=options.width and options.width<540 and 80 or 128
 art.style.width=art_size
 art.style.height=art_size
 art.style.stretch_image_to_widget_size=true
 local copy=hero.add{type="flow",direction="vertical"}
 copy.style.horizontally_stretchable=true
 local phase_title=label(copy,L("dyson-phase-"..phase))
 phase_title.style.font="heading-2"
 phase_title.style.font_color={r=.94,g=.90,b=.79}
 label(copy,L("dyson-subtitle"))
 label(copy,L("dyson-stage-progress",tostring(completed),tostring(total)))
 if not options.embedded then
   local visual=label(copy,L("dyson-art-stage",tostring(math.min(6,completed))))
   visual.style.font="default-bold"
   visual.style.font_color={r=.70,g=.72,b=.75}
 end
 local progress=copy.add{type="progressbar",
   value=total>0 and completed/total or 0}
 progress.style.horizontally_stretchable=true
 label(copy,L("dyson-phase-disclaimer"))
 inspection(parent,player)
 local research=label(parent,L("dyson-research-heading"))
 research.style.font="default-bold"
 local scroll=options.embedded and parent
   or parent.add{type="scroll-pane",direction="vertical"}
 if not options.embedded then
   scroll.style.height=math.max(200,math.min(310,
     math.floor(player.display_resolution.height/math.max(player.display_scale,1)*.30)))
   scroll.style.horizontally_stretchable=true
 end
 for _,stage in ipairs(stages) do
   -- Timeline entries read as engineering milestones, not repeated tiles.
   local frame=scroll.add{type="flow",direction="vertical"}
   frame.style.horizontally_stretchable=true
   frame.style.vertical_spacing=4
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
     if stage.tech.enabled==false then
       label(frame,L("dyson-disabled"))
     elseif #missing==0 then
       label(frame,L("dyson-ready"))
     end
   end
   scroll.add{type="line",direction="horizontal"}
 end
 if total==0 then label(scroll,L("dyson-unavailable")) end
 label(parent,L("dyson-satellites"))
 label(parent,L("dyson-safety"))
end
return M
