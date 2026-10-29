---@diagnostic disable: assign-type-mismatch
-- Event-driven physical project regression fixture. No Factorio save required.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,message) if not v then error(message,2) end end
storage={}
local catalog={
  nauvis="calidus",fulgora="vibrant",gleba="nyxaris"
}
package.loaded["scripts.galactic_catalog"]={
  system=function(name) return catalog[name] or "unassigned" end
}
package.loaded["scripts.razi_catapult_network"]={
  snapshot=function()
    return {installed=true,enabled=true,entries={{
      id="razi-test-link",source="nauvis",target="fulgora",
      source_researched=true,target_researched=true
    }}}
  end
}
prototypes={entity={["orbital-cannon-launcher"]={type="assembling-machine"}}}
local surface={}
local ark_qualification_queries=0
function surface.count_entities_filtered(q)
  ark_qualification_queries=ark_qualification_queries+1
  if q.name=="thruster" then return 3 end
  if q.type=="ammo-turret" then return 4 end
  if q.type=="assembling-machine" then return 2 end
  return 1
end
local force={index=1,platforms={}}
game={planets={nauvis={surface=surface},fulgora={surface=surface}},surfaces={}}
local m=require("scripts.razi_great_projects")
local start={valid=true,hub={valid=true},index=101,force=force,name="Beltwright",
  scheduled_for_deletion=0,weight=1250000,surface=surface,
  completed_trips=5,last_visited_space_location={name="asteroid-belt-inner-edge"},
  space_connection={from={name="asteroid-belt-inner-edge"},
    to={name="asteroid-belt-outer-edge"}}}
force.platforms[1]=start
check(not m.observe(start),"Departure must not imply successful crossing")
local captured=ark_qualification_queries
check(captured==3,"New departure must sample the three Ark entity groups")
for i=1,20 do
  check(not m.observe(start),"Same crossing must remain pending")
end
check(ark_qualification_queries==captured,
  "Repeated construction events must not rescan Ark entity groups")
start.space_connection=nil
start.space_location={name="asteroid-belt-outer-edge"}
start.completed_trips=6
check(m.observe(start),"Completed first physical belt crossing should count")
check(select(1,m.beltbreaker(force))==1,"Vibrant crossing recorded")
start.space_connection={from={name="razi-umbra-belt-inner"},
  to={name="razi-umbra-belt-outer"}}
start.last_visited_space_location={name="razi-umbra-belt-inner"}
start.completed_trips=6
m.observe(start)
start.space_connection=nil
start.space_location={name="razi-umbra-belt-outer"}
start.completed_trips=7
check(m.observe(start),"Umbra crossing must be a separate route")
check(select(1,m.beltbreaker(force))==2,"Both belts complete")
start.space_connection={from={name="vesta"},to={name="solar-system-edge"}}
start.last_visited_space_location={name="vesta"}
m.observe(start)
check(select(1,m.ark(force))==0,"A stationary heavy ship is not an Ark victory")
start.space_connection=nil
start.space_location={name="solar-system-edge"}
start.completed_trips=8
check(m.observe(start),"A qualifying deep space arrival should count")
check(select(1,m.ark(force))==1,"Ark should complete after actual expedition")
local source={planet={name="nauvis"}}
local destination={planet={name="fulgora"}}
local qty=20
local sealed=0
local inv={
  get_item_count=function(id)
    if id=="processing-unit" then return qty end
    if id=="razi-skybridge-consignment" then return sealed end
    return 0
  end,
  can_insert=function() return true end,
  remove=function(spec)
    if spec.name=="processing-unit" then qty=qty-spec.count
    else sealed=sealed-spec.count end
    return spec.count
  end,
  insert=function(spec) sealed=sealed+spec.count return spec.count end
}
local player={valid=true,character={valid=true},force=force,
  physical_surface=source,get_main_inventory=function() return inv end}
check(select(1,m.skybridge(force))==1,"Real physical endpoints establish one stage")
check(m.sign(player,"nauvis","fulgora"),"Outbound manifest needs installed source pair")
check(qty==0 and sealed==1,"Freight issue must consume real materials")
player.physical_surface=destination
check(m.deliver(player),"Destination confirmation consumes the transported receipt")
check(sealed==0 and select(1,m.skybridge(force))==3,"Physical freight handoff completes")
local function relay(name,power)
  return {planet={name=name},find_entities_filtered=function()
    return {{valid=true,energy=power}}
  end}
end
game.surfaces={relay("nauvis",100),relay("fulgora",100),relay("gleba",100)}
check(select(1,m.array(force))==3 and m.recovered(force)==3,
  "Three powered systems unlock all three archive messages")
game.surfaces={}
check(m.recovered(force)==3,"Recovered stories survive relay removal")
local destination_force={index=2,platforms={}}
m.forces_merged{source_index=1,destination=destination_force}
check(select(1,m.ark(destination_force))==1
  and select(1,m.beltbreaker(destination_force))==2
  and m.recovered(destination_force)==3,
  "Merging forces must preserve all permanent achievements")
print("Great Projects: catapult evidence, belt routes, Ark and archive passed")
