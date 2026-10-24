-- Single switch for the story text.
--
-- Story text is prose on top of the mechanics: the expedition briefings and
-- headings appended to planet and location descriptions, and the "field
-- dispatch" notes on route tooltips. While the switch is off none of it is
-- referenced, so the descriptions stay as the source mods wrote them and the
-- route tooltips list only facts. The locale entries stay in the files.
--
-- Turn the story text on by changing ENABLED below. Tests call configure()
-- to try both states.
local ENABLED=false

local M={}
local enabled_flag=false

function M.enabled() return enabled_flag end

-- Applies the switch. Runs once at load.
function M.configure(value)
  enabled_flag=value==true
end

M.configure(ENABLED)
return M
