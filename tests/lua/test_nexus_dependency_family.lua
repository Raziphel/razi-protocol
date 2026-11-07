-- The original Nexus family has native Factorio 2.1 support as of 1.3.6.
-- Nexus Bosses 2.5.1+ requires that original family. Never pull the deprecated
-- Updated forks into the same pack, or Factorio refuses to load mods.
local file = assert(io.open("info.json", "r"))
local text = assert(file:read("*a"))
file:close()

local section = assert(text:match('"dependencies"%s*:%s*%[(.-)%]'),
  "Missing mod dependency list")
local deps = {}
for item in section:gmatch('"([^"]+)"') do deps[item] = true end

local function check(ok, why) if not ok then error(why, 2) end end
check(deps["Nexus >= 1.3.6"], "Razi 3.x must load original Nexus 2.1")
check(deps["~ nexus-bosses >= 2.5.1"],
  "Nexus Bosses must be new enough to require original Nexus")
for _, deprecated in ipairs({
  "Nexus-Updated", "Nexus-Threat-Updated", "Nexus-Graphics-Updated"
}) do
  check(deps["! "..deprecated],
    "Explicitly block retired Nexus fork: "..deprecated)
  for entry in pairs(deps) do
    check(not entry:match("^[+~?]?%s*"..deprecated.."%s*[><=]"),
      "Razi cannot require the obsolete Nexus fork: "..entry)
  end
end
check(not deps["! Nexus"] and not deps["! Nexus-Threat"]
  and not deps["! Nexus-Graphics"],
  "The original Nexus family must be permitted")
print("Nexus 2.1 dependency-family regression passed")
