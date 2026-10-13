-- Keep the retired development feature from returning to Calidus.
local function source(path)
  local f=assert(io.open(path,"r"))
  local s=f:read("*a")
  f:close()
  return s
end
assert(not source("data.lua"):find("calidus_expansion",1,true))
assert(not source("data-final-fixes.lua"):find("calidus_expansion",1,true))
assert(not source("prototypes/system/galaxy_layout.lua"):
  find("razi-calidus-drift",1,true))
local route=source("prototypes/system/route_reconcile.lua")
assert(route:find('route.from=="razi-calidus-drift"',1,true))
assert(route:find('route.to=="razi-calidus-drift"',1,true))
print("Retired Calidus Drift fixture passed")
