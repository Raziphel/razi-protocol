-- Solar difficulty must agree across quality asteroids, map colors and
-- route hover class. Test known SLP names and technology-discovered IDs.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,message) if not value then error(message,2) end end
package.loaded["scripts.galactic_catalog"]={system=function(name)
 return (name=="nauvis" or name=="muluna" or name=="sye-calidus")
   and "calidus" or "unassigned"
end}
rawset(_G,"data",{raw={technology={
 ["planet-discovery-sunorbit"]={
  effects={{type="unlock-space-location",space_location="custom-stellar-outer"}}},
 ["slp-solar-system-sun2"]={
  effects={{type="unlock-space-location",space_location="custom-stellar-inner"}}}
}}})
package.loaded["scripts.razi_asteroid_difficulty"]=nil
local quality=require("scripts.razi_asteroid_difficulty")
local hazard=require("prototypes.system.route_hazards")
quality.prepare_routes({
 source={from="nauvis",to="custom-stellar-outer",length=125000},
 closer={from="custom-stellar-outer",to="custom-stellar-inner",length=65000}
})
check(quality.location_level("nauvis")==1,
 "Ordinary Nauvis should remain difficulty 1")
check(quality.location_level("custom-stellar-outer")==9
 and quality.location_level("custom-stellar-inner")==10,
 "Source technology orbital destinations must inherit HELIOS tiers")
local routes={
 outer={from="nauvis",to="custom-stellar-outer",length=125000},
 inner={from="custom-stellar-outer",to="custom-stellar-inner",length=65000},
 reverse={from="custom-stellar-outer",to="nauvis",length=125000},
 moon={from="nauvis",to="muluna",length=12000}
}
local o1,o2=quality.route_range(routes.outer)
local i1,i2=quality.route_range(routes.inner)
check(o1==8 and o2==9,
 "Solar approach should be Level 8–9, not Level 1")
check(i1==9 and i2==10,
 "Inner stellar transit should be Level 9–10")
check(quality.route_color_richtext(o2)=="#FC5E47"
 and quality.route_color_richtext(i2)=="#F0364A",
 "Real peak difficulty must drive orange/red route ribbons")
check(quality.route_range(routes.reverse)==o1,
 "Opposite stellar travel direction must retain high hazard")
check(quality.route_level(routes.moon,.5)==1,
 "Stellar rules must never inflate normal lunar shuttles")
check(hazard.kind(routes.outer)=="stellar-approach"
 and hazard.kind(routes.inner)=="stellar-inner"
 and hazard.kind(routes.moon)=="local",
 "Route classes should reflect true stellar danger")
check(quality.location_level("sun-orbit")==9
 and quality.location_level("close-sun-orbit")==10,
 "Stable upstream SLP orbital names must remain supported")
print("HELIOS quality levels, source locations, danger ribbons and route classes passed")
