-- Resolve the installed Athos science technology through its native
-- unlock-recipe effect. No duplicated research or guessed unlock rewards.
local M={}
function M.unlocking(recipe)
  local known=prototypes and prototypes.technology or {}
  local names={}
  for name,technology in pairs(known) do
    for _,effect in pairs(technology.effects or {}) do
      if effect.type=="unlock-recipe" and effect.recipe==recipe then
        names[#names+1]=name break
      end
    end
  end
  table.sort(names)
  return names[1]
end
M.quests={
  {id="athos-particulate",chapter="solaris",
   tech=M.unlocking("particulate-science-pack") or "particulate-science-pack",
   requires={"athos"}},
  {id="frontier-recovery-charter",chapter="network",
   tech="razi-frontier-recovery-charter",
   requires={"athos-particulate","nulla-robotic-science","interplanetary-trade"}}
}
return M
