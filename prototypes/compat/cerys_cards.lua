local cerys_cards = {}

local standard_tech_card_weight = 1000

local function should_patch_cerys_card(name)
	if not name or not name:find("cerys", 1, true) then
		return false
	end

	return
		name:find("tech%-card") or
		name:find("tech_card", 1, true) or
		name:find("science%-pack")
end

local function patch_item_proto(proto)
	if not proto or not should_patch_cerys_card(proto.name) then
		return
	end

	proto.weight = standard_tech_card_weight

	-- Respect the field only when the source mod defines it.
	if proto.send_to_orbit_mode ~= nil then
		proto.send_to_orbit_mode = "automated"
	end
end

function cerys_cards.data_final_fixes()
	for _, tool in pairs(data.raw.tool or {}) do
		patch_item_proto(tool)
	end

	for _, item in pairs(data.raw.item or {}) do
		patch_item_proto(item)
	end
end

return cerys_cards
