---@diagnostic disable: missing-fields
-- Railgun turrets keep the combat subgroup assigned by their source mod.
local raw = {
	["item-group"] = { ["razi-infrastructure"] = {} },
	["item-subgroup"] = { turret = { group = "combat" } },
	item = { ["railgun-turret"] = { subgroup = "turret" } },
	recipe = {
		["railgun-turret"] = { subgroup = "turret", result = "railgun-turret" }
	}
}
rawset(_G, "data", {
	raw = raw,
	extend = function(_, prototypes)
		for _, prototype in ipairs(prototypes) do
			raw[prototype.type] = raw[prototype.type] or {}
			raw[prototype.type][prototype.name] = prototype
		end
	end
})

require("prototypes.ui.logistics_cleanup").data_final_fixes()

local function check(value, message)
	if not value then error(message, 2) end
end

check(raw.item["railgun-turret"].subgroup == "turret",
	"Railgun turret item left the source turret subgroup")
check(raw.recipe["railgun-turret"].subgroup == "turret",
	"Railgun turret recipe left the source turret subgroup")
check(raw["item-subgroup"]["razi-infrastructure-misc"] == nil,
	"Unused infrastructure misc subgroup was created")

print("test_logistics_cleanup: ok")
