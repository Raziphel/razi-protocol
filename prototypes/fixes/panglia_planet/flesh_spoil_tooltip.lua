-- Biter flesh (biter_dna_sample) of Panglia 0.8.2 rots away with nothing left: its spoil trigger only puffs the smoke
-- biter_dna_sample_decomposition (prototypes/item.lua:333-349). Panglia hides that one effect from the tooltip
-- (show_in_tooltip = false, item.lua:345), so the tooltip has no result to show and draws "Spoil result: ?". The effect
-- is shown; Panglia gives the smoke its own name "Residues" and icon (item.lua:287-288, locale/en/locale.cfg:102).
local flesh_spoil_tooltip = {}

local SMOKE = "biter_dna_sample_decomposition"

local function show_smoke(node)
	if type(node) ~= "table" then
		return 0
	end
	local shown = 0
	if node.type == "create-smoke" and node.entity_name == SMOKE and node.show_in_tooltip == false then
		node.show_in_tooltip = true
		shown = 1
	end
	for _, child in pairs(node) do
		shown = shown + show_smoke(child)
	end

	return shown
end

function flesh_spoil_tooltip.data_final_fixes()
	local raw = data.raw
	local flesh = raw.item and raw.item["biter_dna_sample"]
	local smoke = raw["smoke-with-trigger"] and raw["smoke-with-trigger"][SMOKE]
	if not (flesh and smoke and flesh.spoil_to_trigger_result) then
		return
	end

	local shown = show_smoke(flesh.spoil_to_trigger_result)
	if shown > 0 then
		log("razi-protocol: biter_dna_sample spoil tooltip shows " .. SMOKE .. " (" .. shown .. " effects)")
	end
end

return flesh_spoil_tooltip
