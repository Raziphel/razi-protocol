local aquilo_data_card = {}

-- Eneas 1.0.10 declares an Aquilo data card (prototypes/item.lua:103-114) beside the Gleba, Vulcanus and Fulgora cards,
-- but no recipe makes or uses it and it has no name in any language (its locale has no item-name.aquilo-data-card). It
-- sat in Factoriopedia as "Unknown key: item-name.aquilo-data-card", and Cargo Crates gave it a packing and an unpacking
-- recipe under the same unknown name. The card, its crate and the two crate recipes are hidden; the name
-- (locale/*/eneas.cfg) covers the recycling, crushing and similar recipes that other mods generate from the card.
local function hide(prototype, name)
	if prototype and not prototype.hidden then
		prototype.hidden = true
		log("razi-protocol: " .. name .. " is hidden, nothing makes or uses the Aquilo data card of Eneas")
	end
end

function aquilo_data_card.data_final_fixes()
	local card = data.raw.item and data.raw.item["aquilo-data-card"]
	if not card then
		return
	end

	hide(card, "aquilo-data-card")
	hide(data.raw.item["cargo-crate-aquilo-data-card"], "cargo-crate-aquilo-data-card")
	for _, name in pairs({"cargo-crate-aquilo-data-card", "unpack-cargo-crate-aquilo-data-card"}) do
		hide(data.raw.recipe and data.raw.recipe[name], name)
	end
end

return aquilo_data_card
