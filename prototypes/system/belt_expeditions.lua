-- Final harvest pass for the Razi-owned asteroid belts.
-- These are ordinary Space Age locations/connections, not simulated entities.
-- Reuse the route authority's approved physical crossings after its pruning.
local M={}
local profiles=require("prototypes.system.asteroid_profiles")
local reconcile=require("prototypes.system.route_reconcile")

M.crossings={
  {system="vibrant",inner="asteroid-belt-inner-edge",
   outer="asteroid-belt-outer-edge",length=5000,pressure=1.25},
  {system="vespera",inner="razi-vespera-belt-inner",
   outer="razi-vespera-belt-outer",length=6500,pressure=1.50},
  {system="umbra",inner="razi-umbra-belt-inner",
   outer="razi-umbra-belt-outer",length=8000,pressure=1.70}
}
local function exists(id)
 return (data.raw.planet or {})[id]
  or (data.raw["space-location"] or {})[id]
end
function M.data_final_fixes()
 local routes=data.raw["space-connection"] or {}
 local result={vibrant=false,vespera=false,umbra=false}
 for _,belt in ipairs(M.crossings) do
  if exists(belt.inner) and exists(belt.outer) then
   local key=reconcile.pair_key(belt.inner,belt.outer)
   for _,route in pairs(routes) do
    if route.from and route.to
     and reconcile.pair_key(route.from,route.to)==key then
     -- Do not replace the source route, change its name or its native
     -- passenger schedule. In particular, preserve Vibrant's old ID.
     profiles.apply_field(route,belt.pressure)
     profiles.enrich_belt_crossing(route,belt.system)
     result[belt.system]=true
     break
    end
   end
  end
 end
 if type(log)=="function" then
  log("[Razi Protocol/belts] Native crossing harvest: Vibrant="..
    tostring(result.vibrant)..", Vespera="..tostring(result.vespera)..
    ", Umbra="..tostring(result.umbra))
 end
 return result
end
return M
