-- Legacy interface retained for mod revisions and tests.
-- The original static directional-strokes renderer is retired. Its fixed
-- sprites could not stay aligned to live Factorio arcs/planet positions.
-- Native route visuals now have a single owner: the optional installation
-- of Space Route Overlay (valent125, Factorio 2.1). Razi provides the
-- underlying native connection geometry and independent danger tooltips.
local M={}
local hazards=require("prototypes.system.route_hazards")

function M.color_for_route(route)
  return hazards.color(route)
end

function M.color_for_guide(_,route)
  return hazards.color(route)
end

function M.strokes_for_connection()
  return {}
end

function M.layers_for_guide()
  return {}
end

function M.field_marker()
  return nil
end

function M.data_final_fixes()
  -- Intentionally no sprite mutations. If Space Route Overlay is absent,
  -- Factorio draws its normal native routes without a broken substitute.
  return 0
end

return M
