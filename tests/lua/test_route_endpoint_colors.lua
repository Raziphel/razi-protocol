-- Native route ribbons: planet endpoint coverage and fair layer budgets.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(value,msg) if not value then error(msg,2) end end
package.loaded["prototypes.system.route_hazards"]={
 is_belt_crossing=function(route) return route.belt or false end,
 kind=function(route)
   if route.solar then return "stellar-approach" end
   return route.belt and "belt-crossing" or "local"
 end}
package.loaded["scripts.razi_asteroid_difficulty"]={
 route_level=function(route) return route.solar and 9 or 3 end,
 color_level=function(n) return n end,
 route_color=function() return {r=1,g=.4,b=.2} end}
rawset(_G,"settings",{startup={}})
local ribbons=require("prototypes.system.route_ribbons")
local locations={
 nauvis={x=0,y=0},sunorbit={x=80,y=0},inner={x=140,y=0},
 muluna={x=3.5,y=0},neighbor={x=1.15,y=0},
 overlapping={x=.25,y=0}}
local owner={
 is_navigation_highlight=function() return true end,
 is_major=function() return true end,
 position=function(name) return locations[name] end,
 route_path=function(route,a,b)
   local dx,dy=b.x-a.x,b.y-a.y
   local length=math.sqrt(dx*dx+dy*dy)
   return function(t)
     return {x=a.x+dx*t,y=a.y+dy*t}
   end,length
 end
}
local function route(name,stop,solar)
 return {name=name,from="nauvis",to=stop,solar=solar}
end
local long=ribbons.candidate(owner,route("nauvis-sun","sunorbit",true),
 "danger","all")
check(long and long.trim<=.65 and long.covered>long.length-1.31,
 "Long Sun approach retains too much uncoloured grey near planet icon")
local local_route=ribbons.candidate(owner,
 route("nauvis-muluna","muluna",false),"danger","all")
check(local_route and local_route.covered>2,
 "Nearby moon route should be coloured, not silently skipped")
local tiny=ribbons.candidate(owner,
 route("nauvis-neighbor","neighbor",false),"danger","all")
check(tiny and tiny.covered>.8,
 "Near-adjacent valid native connections should remain visible")
local collision=ribbons.candidate(owner,
 route("overlap","overlapping",false),"danger","all")
check(collision==nil,
 "Overlapping destination markers must not grow fake ribbons")
check(#ribbons.strokes_for_connection(owner,
 route("sun","sunorbit",true),"danger","all")>0,
 "Solar path must render actual coloured sprite chords")
check(#ribbons.strokes_for_connection(owner,
 route("moon","muluna",false),"danger","all")>0,
 "Short local path must render actual coloured sprite chords")
local rows={
 {covered=125,pieces=40,stellar=true},
 {covered=65,pieces=25,belt=true},
 {covered=3,pieces=1},
 {covered=25,pieces=10}
}
ribbons.allocate(rows,140,13.5)
for _,row in ipairs(rows) do
 check(row.draw_pieces>=math.ceil(row.covered/13.5),
 "A paintable route was skipped or stretched beyond width limit")
end
check(rows[3].draw_pieces>=1,
 "Small local transfers must receive atlas space")
local scarce={
 {covered=65,pieces=24,stellar=true},
 {covered=400,pieces=100},
 {covered=3,pieces=1}
}
ribbons.allocate(scarce,12,13.5)
check(scarce[1].draw_pieces>=5,
 "Critical Sun expeditions must receive enough segments to remain painted")
check(scarce[3].draw_pieces>=1,
 "Short links should use spare budget even if a long route cannot fit")
print("Route endpoints, moon links, solar priority and atlas budgets passed")
