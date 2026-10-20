-- Read-only Stelllar Works. Research is real; satellites and network MW
-- are unknown until the source mod exposes an official telemetry API.
local M={}
local L=function(name,...) return {"razi-ops."..name,...} end
local runtime=require("scripts.galactic_dyson_runtime")
local operations=require("scripts.razi_helios_operations")
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
-- Player-visible research milestones are real source-owned or Razi techs.
-- Do not fabricate satellite production or delivered MW measurements.
local helios_stages={
 "razi-helios-corona-engineering",
 "razi-helios-swarm-engineering",
 "razi-helios-relay-engineering"
}
local helios_products={
 ["razi-helios-corona-engineering"]="razi-helios-corona-shield",
 ["razi-helios-swarm-engineering"]="razi-helios-stellar-frame",
 ["razi-helios-relay-engineering"]="razi-helios-relay-matrix"
}
-- Recorded production, not simulated construction progress or satellite MW.
-- Read only when the journal is displayed; no tick scans or cached guesses.
function M.component_counts(force)
 local counts={}
 if not (game and game.surfaces and force.get_item_production_statistics) then
   return counts
 end
 for _,surface in pairs(game.surfaces) do
   local stats=force.get_item_production_statistics(surface)
   if stats and stats.valid~=false then
     for _,name in pairs(helios_products) do
       counts[name]=(counts[name] or 0)+(stats.get_input_count(name) or 0)
     end
   end
 end
 return counts
end
local function helios_progress(parent,force)
 local existing={}
 for _,name in ipairs(helios_stages) do
   local tech=force.technologies and force.technologies[name]
   if tech then existing[#existing+1]=tech end
 end
 if #existing==0 then return end
 local frame=parent.add{type="frame",style="inside_shallow_frame",
   direction="vertical"}
 frame.style.horizontally_stretchable=true
 local title=label(frame,L("dyson-helios-heading"))
 title.style.font="default-bold"
 label(frame,L("dyson-helios-summary"))
 local counts=M.component_counts(force)
 local complete=0
 for _,technology in ipairs(existing) do
   if technology.researched then complete=complete+1 end
   local row=frame.add{type="flow",direction="horizontal"}
   row.style.horizontal_spacing=8
   local mark=label(row,technology.researched and "✓" or "○")
   mark.style.font_color=technology.researched
     and {r=.55,g=.83,b=.68} or {r=.85,g=.70,b=.46}
   label(row,technology.localised_name)
   local product=helios_products[technology.name]
   if product and counts[product] then
     label(frame,{"",{"item-name."..product},": ",
       tostring(counts[product])," ",L("dyson-helios-produced")})
   end
 end
 label(frame,L("dyson-helios-progress",
   tostring(complete),tostring(#existing)))
end
local function commission(parent,player)
 if not (player.force.technologies
   and player.force.technologies["razi-helios-grid-commission"]) then
   return
 end
 local req=operations.targets()
 if req.outer==0 then return end
 local result=operations.status(player.force)
 local frame=parent.add{type="frame",direction="vertical",
   style="inside_shallow_frame"}
 frame.style.horizontally_stretchable=true
 local heading=label(frame,L("helios-commission-heading"))
 heading.style.font="default-bold"
 label(frame,L("helios-commission-guidance"))
 local surge,remaining=operations.coronal_surge(game.tick or 0)
 if surge then
   local warning=label(frame,L("helios-surge-active",tostring(remaining)))
   warning.style.font_color={r=.94,g=.52,b=.38}
 end
 local inv=player.get_main_inventory()
 for _,name in ipairs({"outer","inner"}) do
   local spec=operations.stages[name]
   local done=result[name]
   local required=req[name]
   local entry=frame.add{type="flow",direction="vertical"}
   entry.style.vertical_spacing=3
   local status=label(entry,L("helios-"..name.."-progress",
     tostring(done),tostring(required)))
   status.style.font_color=done>=required
     and {r=.55,g=.83,b=.68} or {r=.85,g=.70,b=.46}
   if done<required then
     local seconds,ready=operations.hold_seconds(player,name)
     local carrying=inv and inv.valid and inv.get_item_count(spec.item) or 0
     label(entry,L("helios-carried",tostring(carrying)))
     label(entry,L("helios-hold",tostring(seconds),
       tostring(math.floor(spec.hold/60))))
     local deliver=entry.add{type="button",
       caption=L("helios-deliver-"..name),
       tags={razi_ops_action="helios-deliver",value=name}}
     -- Allow a click to recheck elapsed time and redraw after station-keeping.
     deliver.enabled=carrying>0
       and ((player.force.technologies[spec.tech] or {}).researched==true)
       and (name=="outer" or result.outer>=req.outer)
   end
 end
 local grid_title=label(frame,L("helios-grid-title",
   tostring(result.worlds),tostring(req.grid)))
 grid_title.style.font="default-bold"
 label(frame,L("helios-grid-installed",
   tostring(result.grid.installed),tostring(result.grid.powered)))
 for i=1,math.min(#result.grid.worlds,8) do
   local site=result.grid.worlds[i]
   label(frame,L("helios-grid-site",site.name,
     tostring(site.powered),tostring(site.installed)))
 end
 if result.complete then
   local finished=label(frame,L("helios-commission-complete"))
   finished.style.font_color={r=.55,g=.83,b=.68}
 end
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
 hero.style.padding=10
 hero.style.horizontally_stretchable=true
 local art=hero.add{type="sprite",
   sprite="razi-dyson-works-stage-"..math.min(6,completed)}
 art.resize_to_sprite=false
 local art_size=options.width and options.width<540 and 72 or 96
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
 if not options.embedded then label(copy,L("dyson-phase-disclaimer")) end
 helios_progress(parent,player.force)
 commission(parent,player)
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
   frame.style.vertical_spacing=3
   local h=frame.add{type="flow",direction="horizontal"}
   h.style.horizontal_spacing=8
   h.style.vertical_align="center"
   local marker=label(h,stage.tech.researched and "✓" or "○")
   marker.style.font_color=stage.tech.researched
      and {r=.55,g=.83,b=.68} or {r=.85,g=.70,b=.46}
   local caption=label(h,L(stage.heading))
   caption.style.font="default-bold"
   local state=label(h,stage.tech.researched and L("dyson-completed")
      or L("dyson-pending"))
   state.style.font_color=stage.tech.researched
      and {r=.55,g=.83,b=.68} or {r=.85,g=.70,b=.46}
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
