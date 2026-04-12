local adjust_maraxsis = data.raw["bool-setting"] and data.raw["bool-setting"]["adjust-maraxsis"]

if adjust_maraxsis then
	adjust_maraxsis.default_value = false
	adjust_maraxsis.forced_value = false
	adjust_maraxsis.hidden = true
end
