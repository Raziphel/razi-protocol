package.path="./?.lua;./?/init.lua;"..package.path
local M=require("prototypes.system.location_icons")
local function assert_ok(v,m) if not v then error(m,2) end end
local locations,filenames={},{}
local count=0
for id,filename in pairs(M.icons) do
  assert_ok(not filenames[filename],"Duplicate navigation art for "..id)
  filenames[filename]=true
  locations[id]={name=id,orbit={distance=31},solar_power_in_space=17}
  count=count+1
end
assert_ok(count==11,"Must have seven gateways and four belt-rim markers")
locations["external-source-location"]={icon="__other__/test.png"}
local routes={connection={length=8000}}
rawset(_G,"data",{raw={["space-location"]=locations,["space-connection"]=routes}})
M.data_final_fixes()
for id,filename in pairs(M.icons) do
  local p=locations[id]
  assert_ok(p.icon==filename and p.starmap_icon==filename,"Wrong artwork for "..id)
  assert_ok(p.icon_size==64 and p.starmap_icon_size==64,"Wrong dimensions for "..id)
  assert_ok(p.orbit.distance==31 and p.solar_power_in_space==17,"Artwork changed orbital data")
end
assert_ok(locations["external-source-location"].icon=="__other__/test.png","Changed external art")
assert_ok(routes.connection.length==8000,"Changed route length")
M.data_final_fixes()
assert_ok(locations["sye-umbra"].starmap_icon==M.icons["sye-umbra"],"Not idempotent")
print("Unique Factorio starmap location icons passed")
