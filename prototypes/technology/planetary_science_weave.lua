-- Retired: imported science packs are not the price of freight.
-- Native planet discovery, source technology unlocks and actual imported
-- materials establish the economy's progression instead. No mod-owned
-- technology or research cost is mutated in this final-fixes pass.
-- Keep the module as a stable compatibility entry point.
local M={rules={}}
function M.data_final_fixes()
  return 0
end
return M
