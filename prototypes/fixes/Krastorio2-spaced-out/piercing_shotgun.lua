local piercing_shotgun = {}

-- A copy-paste value of Krastorio2-spaced-out 2.0.19: the piercing shotgun shell fires plain shotgun pellets
-- (6 damage) instead of piercing ones (10): its second action names shotgun-pellet
-- (prototypes/updates/base/weapons-realistic.lua:1540). It takes the piercing pellet when that projectile exists.
function piercing_shotgun.data_final_fixes()
	local shell = data.raw.ammo and data.raw.ammo["piercing-shotgun-shell"]
	local actions = shell and shell.ammo_type and shell.ammo_type.action
	if type(actions) == "table" and data.raw.projectile and data.raw.projectile["piercing-shotgun-pellet"] then
		for _, action in pairs(actions) do
			local delivery = action.action_delivery
			if delivery and delivery.type == "projectile" and delivery.projectile == "shotgun-pellet" then
				delivery.projectile = "piercing-shotgun-pellet"
				log("razi-protocol: piercing-shotgun-shell fires piercing-shotgun-pellet")
			end
		end
	end
end

return piercing_shotgun
