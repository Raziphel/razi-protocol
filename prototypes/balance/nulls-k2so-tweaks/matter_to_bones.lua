local matter_to_bones = {}

-- nulls-k2so-tweaks (Carnova) adds matter conversion to and from bones on purpose: its optional additional matter
-- recipes make 10 bones from 2 matter (k2so-tweaks/patches/expanded-matter-recipes.lua:95-101). Advanced bone
-- processing makes from one bone four bone meal, a calcite (2 matter) and phosphorus, so a round bones -> matter ->
-- bones multiplies several times over even at the base productivity of the machine, and stone or ore bought with
-- matter feeds it. Closing it is a decision of this mod, not a mistake of that one: matter no longer makes bones;
-- bones still sell for matter (kr-bones-to-matter stays).
function matter_to_bones.data_final_fixes()
	require("prototypes.balance.common.hide_recipes").hide({ "kr-matter-to-bones" })
end

return matter_to_bones
