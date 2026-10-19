-- Regression for the duplicated green route visible in Factorio.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(v,msg) if not v then error(msg,2) end end
local raw={planet={
  a={distance=10,orientation=.25},
  b={distance=68,orientation=.25},
  c={distance=35,orientation=.5},
  d={distance=72,orientation=.5}},
 ["space-location"]={
  ["razi-umbra-belt-inner"]={distance=12,orientation=.25},
  ["razi-umbra-belt-outer"]={distance=22,orientation=.25}},
 ["space-connection"]={},
 ["utility-sprites"]={default={starmap_star={layers={
  {filename="__base__/graphics/native-sun.png"}}}}}}
rawset(_G,"data",{raw=raw})
rawset(_G,"mods",{})
rawset(_G,"settings",{startup={
 ["razi-route-overlay-mode"]={value="danger"},
 ["razi-route-overlay-scope"]={value="all"},
 ["razi-quality-asteroids"]={value=true}}})
local m=require("prototypes.system.route_highlights")
local safe={from="a",to="b",shape="line",asteroid_spawn_definitions={}}
local medium={from="c",to="d",shape="line",
 asteroid_spawn_definitions={{asteroid="medium-metallic-asteroid",probability=.2}}}
local huge={from="c",to="d",shape="line",
 asteroid_spawn_definitions={{asteroid="huge-metallic-asteroid",probability=.2}}}
local belt={from="razi-umbra-belt-inner",to="razi-umbra-belt-outer",
 shape="line",asteroid_spawn_definitions={}}
check(m.route_color_level(medium)>=1 and m.route_color_level(huge)>=1,
 "Unified difficulty must be determined by campaign route, not asteroid sizes")
check(#m.strokes_for_connection(safe,"danger","all")>10,
 "Safe straight route must have a continuous blue path, not one color pip")
check(#m.strokes_for_connection(medium,"danger","all")>5,
 "Medium route needs real teal/green connected ribbon segments")
check(#m.strokes_for_connection(huge,"danger","all")>5,
 "Severe route must have real colored geometry")
check(#m.strokes_for_connection(belt,"danger","major")>=2,
 "Belt crossing must visibly be a colored line through its own field")
-- Five chart units is a local hop, not a thick interstellar highway.
-- The original native route (and its tooltip) remain untouched.
raw.planet.near={distance=15,orientation=.25}
local near={from="a",to="near",shape="line",
  length=1000,asteroid_spawn_definitions={}}
check(#m.strokes_for_connection(near,"danger","all")==0,
 "A 1,000 km local hop should keep its native line without extra ribbons")
check(#m.strokes_for_connection(belt,"danger","all")>=2,
 "A nearby belt crossing must not lose its critical hazard marker")
local ribbons=m.strokes_for_connection(safe,"danger","all")
local first=ribbons[1]
local ribbon_module=require("prototypes.system.route_ribbons")
check(first.filename==ribbon_module.sheet
  and first.size[1]==64 and first.x<1024 and first.y<512
  and first.tint.b>first.tint.r,
  "Real starter line must use the 128-direction blue ribbon atlas")
check(type(first.shift[1])=="number" and type(first.shift[2])=="number",
  "Generated ribbons require absolute native-map pixel coordinates")
check(m.marker_for_connection==nil and m.threat_tier==nil,
 "Retired dot badges and five-tier danger must not return")
check(#m.strokes_for_connection(safe,"chapter","all")>10,
 "Chapter view must preserve continuous ten-grade lines")
local palette=require("scripts.razi_asteroid_difficulty")
check(#palette.route_colors==10 and #palette.route_color_hex==10,
  "Ten independent quality colors are required")
for i=1,10 do
  local color=palette.route_color(i)
  check(color and color.r>=0 and color.r<=1
    and color.g>=0 and color.g<=1
    and color.b>=0 and color.b<=1,"Invalid stage color")
  if i>1 then
    local previous=palette.route_color(i-1)
    check(math.abs(previous.r-color.r)+math.abs(previous.g-color.g)
      +math.abs(previous.b-color.b)>.09,"Adjacent route levels look identical")
  end
end
check(palette.route_color(1).b>palette.route_color(1).r,
  "Level 1 must be blue")
check(palette.route_color(10).r>palette.route_color(10).g*2,
  "Level 10 must be red")
check(m.color_for_route(safe,"danger")==palette.route_color(m.route_color_level(safe)),
  "Safe route must use Razi's quality color palette")
check(m.color_for_route(belt,"chapter")==palette.route_color(m.route_color_level(belt)),
  "Chapter mode must not hide the chosen danger grade")
local arc={from="c",to="d",shape="arc",
 asteroid_spawn_definitions={{asteroid="huge-metallic-asteroid",probability=.2}}}
check(#m.strokes_for_connection(arc,"danger","all")>0,
 "Default Factorio arc geometry must be rendered, not silently omitted")
raw["space-connection"]={safe=safe,medium=medium,huge=huge,belt=belt}
local layers=raw["utility-sprites"].default.starmap_star.layers
check(m.data_final_fixes()>20,
 "Map renderer must emit enough connected colored strokes to cover routes")
check(#layers>1,
  "Ribbon atlas was not added to the starmap image layers")
local total=#layers
check(m.data_final_fixes()==0 and #layers==total,
 "Do not duplicate warning sprites on another data pass")
settings.startup["razi-route-overlay-mode"].value="off"
layers[1]={filename="__razi-protocol__/graphics/route-highlights/continuous-strokes.png"}
check(m.data_final_fixes()==0 and #layers==total-1,
 "Old stretched route sprites must be removed even in Off mode")
settings.startup["razi-quality-asteroids"].value=false
check(m.route_color_level(huge)~=nil
  and m.color_for_route(huge,"danger")==
    palette.route_color(m.route_color_level(huge)),
  "Map danger colors remain 1-10 even if quality enemies are disabled")
settings.startup["razi-quality-asteroids"].value=true
print("Route sprite doubling and severe hazard regression passed")
