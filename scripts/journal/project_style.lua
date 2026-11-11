-- Names and colours shared by the project dashboards: the caption helper, the palette and
-- the emblem of each project.
local dyson=require("scripts.dyson.dyson")
local L=function(k,...) return {"journal-ui."..k,...} end
-- Five build-and-expedition project dossiers. All completion values come from the
-- original mods: there is no fabricated megaproject percentage.
local HUES={
  ink={r=.933,g=.890,b=.808},
  quiet={r=.60,g=.66,b=.65},
  gold={r=.82,g=.69,b=.48},
  green={r=.58,g=.80,b=.66},
  unused={r=.39,g=.46,b=.51}
}
local PROJECT_ART={
  platform="item/space-platform-starter-pack",
  voyage="entity/thruster",
  skybridge="item/processing-unit",
  cargo="item/cargo-bay",
  beltbreaker="technology/rocket-turret",
  array="item/razi-archive-relay",
  ark="item/space-platform-foundation",
  dyson="razi-dyson-works-stage-",
  transceiver="technology/razi-intergalactic-transceiver-signal",
  ["nexus-trials"]="technology/nexus-convergence",
  convergence="technology/razi-convergence-commission"
}
local function art_for(id,force,statuses)
  if id=="dyson" then
    local recorded=statuses and statuses.dyson
    local finished=recorded and recorded[1] or select(1,dyson.status(force))
    return PROJECT_ART.dyson..math.min(6,finished)
  end
  local path=PROJECT_ART[id]
  if helpers and helpers.is_valid_sprite_path
    and not helpers.is_valid_sprite_path(path) then
    return "razi-journal-book-icon"
  end
  return path
end
return {L=L,HUES=HUES,art_for=art_for}
