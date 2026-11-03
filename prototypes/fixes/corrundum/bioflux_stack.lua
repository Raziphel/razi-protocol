local bioflux_stack = {}

-- The ice box of Corrundum counts the stacks of what it keeps cold with stack sizes written into its script, 100 for
-- bioflux (control.lua:276-279 and 503-506 of 1.0.51). Krastorio2-spaced-out raises bioflux to 200
-- (prototypes/updates/adjust-stack-sizes.lua:23), so with 101 to 200 bioflux in an ice box the script looks for a stack
-- that is not there and the game stops every second, and a save with such a box no longer loads. Open pull request #88
-- of Corrundum reads the stack size from the item prototype; until it is released bioflux stacks to 100 again.
function bioflux_stack.data_final_fixes()
	local bioflux = data.raw.capsule and data.raw.capsule.bioflux
	if mods["corrundum"] and bioflux and bioflux.stack_size > 100 then
		bioflux.stack_size = 100
		log("razi-protocol: bioflux stack_size = 100 (corrundum ice box, until corrundum #88)")
	end
end

return bioflux_stack
