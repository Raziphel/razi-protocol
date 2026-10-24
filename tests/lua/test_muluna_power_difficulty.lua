-- Muluna's platform power on Easy, Hard and Nightmare: the satellite radar
-- is scaled as a whole (power, buffer, input limit, scan energy, tooltip),
-- Normal and Custom write nothing.
package.path="./?.lua;./?/init.lua;"..package.path
local function check(ok,msg) if not ok then error(msg,2) end end
rawset(_G,"log",function() end)
local M=require("prototypes.compat.muluna_power_difficulty")
local TIP="tooltip-value.muluna-satellite-radar-scan-energy"
local SIZE="tooltip-value.muluna-satellite-radar-scan-size"
---@return table<string,any>
local function world()
 return {
  quality={normal={level=0},uncommon={level=2},rare={level=5}},
  accumulator={
   ["muluna-satellite-radar"]={
    energy_usage="130MW",
    energy_source={buffer_capacity="390MJ",input_flow_limit="390MW",output_flow_limit="0MW",
     emissions_per_minute={electromagnetic_waves=78}},
    emissions_per_second={electromagnetic_waves=1.3},
    custom_tooltip_fields={
     {value={TIP,"130"},quality_values={
       normal={TIP,"130"},uncommon={TIP,"81"},rare={TIP,"52"}}},
     {value={SIZE,"100"},quality_values={normal={SIZE,"100"}}}
    }
   }
  },
  ["mod-data"]={
   ["muluna-satellite-radar"]={data={
    energy_per_scan_expression="base / (1 + 0.3 * quality_level)",
    entities={["muluna-satellite-radar"]={
     name="muluna-satellite-radar",energy_per_scan=130,scan_area=100}}}}
  }
 }
end
---@return table,table
local function parts(raw)
 local beacon=raw.accumulator["muluna-satellite-radar"]
 return beacon,raw["mod-data"]["muluna-satellite-radar"].data.entities["muluna-satellite-radar"]
end
---@type table<string,any>
local startup={
 ["razi-difficulty-preset"]={value="normal"},
 ["platform-power-consumption"]={value=130}
}
local enabled={["planet-muluna"]="2.7.44"}

local raw=world()
local beacon,entity=parts(raw)
check(M.apply(raw,startup,enabled)==0,"Normal must not write")
check(beacon.energy_usage=="130MW" and entity.energy_per_scan==130,"Normal changed the radar")

startup["razi-difficulty-preset"].value="hard"
check(M.apply(raw,startup,enabled)>0,"Hard writes")
check(beacon.energy_usage=="125MW","Hard: power")
check(beacon.energy_source.buffer_capacity=="375MJ","Hard: buffer is three scans")
check(beacon.energy_source.input_flow_limit=="375MW","Hard: input limit")
check(beacon.energy_source.output_flow_limit=="0MW","Hard: output limit stays")
check(entity.energy_per_scan==125 and entity.scan_area==100,"Hard: scan energy, scan area stays")
check(beacon.energy_source.emissions_per_minute.electromagnetic_waves==75,"Hard: waves follow the buffer")
check(math.abs(beacon.emissions_per_second.electromagnetic_waves-1.25)<1e-9,"Hard: waves per second")
check(beacon.custom_tooltip_fields[1].value[2]=="125","Hard: tooltip scan energy")
check(beacon.custom_tooltip_fields[2].value[2]=="100","the scan size line changed")
check(M.apply(raw,startup,enabled)==0,"a second call must write nothing")

-- Without the game's formula evaluator the shown value follows the ratio.
local quality=beacon.custom_tooltip_fields[1].quality_values
check(quality.normal[2]=="125","Hard: normal quality 125")
check(quality.uncommon[2]==string.format("%.0f",81*125/130),"Hard: uncommon from the ratio")
check(beacon.custom_tooltip_fields[2].quality_values.normal[2]=="100","the scan size per quality changed")

-- With it (the data stage has helpers.evaluate_expression) the numbers are
-- the formula of the mod applied to the new scan energy, as Muluna builds them.
rawset(_G,"helpers",{evaluate_expression=function(expression,values)
 check(expression=="base / (1 + 0.3 * quality_level)","unexpected expression "..tostring(expression))
 return values.base/(1+0.3*values.quality_level)
end})
raw=world()
beacon,entity=parts(raw)
startup["razi-difficulty-preset"].value="nightmare"
M.apply(raw,startup,enabled)
quality=beacon.custom_tooltip_fields[1].quality_values
check(beacon.energy_usage=="170MW" and beacon.energy_source.buffer_capacity=="510MJ","Nightmare: 170 MW, 510 MJ")
check(entity.energy_per_scan==170,"Nightmare: scan energy")
check(quality.normal[2]=="170","Nightmare: normal quality")
check(quality.uncommon[2]==string.format("%.0f",170/1.6),"Nightmare: uncommon is 170 / 1.6")
check(quality.rare[2]==string.format("%.0f",170/2.5),"Nightmare: rare is 170 / 2.5")
rawset(_G,"helpers",nil)

-- Another level from the first value, never compounding.
startup["razi-difficulty-preset"].value="easy"
M.apply(raw,startup,enabled)
check(beacon.energy_usage=="75MW" and entity.energy_per_scan==75,"Easy: 75 from the first value")

-- Normal and Custom write nothing, even after a level did.
for _,level in ipairs({"normal","custom"}) do
 startup["razi-difficulty-preset"].value=level
 check(M.apply(raw,startup,enabled)==0,level.." must write nothing")
 check(beacon.energy_usage=="75MW",level.." changed the radar")
end
startup["razi-difficulty-preset"].value="hard"
check(M.apply(world(),startup,{})==0,"Muluna is not installed")
check(M.apply({accumulator={}},startup,enabled)==0,"no radar: nothing")
local broken=world()
broken["mod-data"]=nil
check(M.apply(broken,startup,enabled)==0,"no mod-data: nothing, no crash")
startup["platform-power-consumption"].value="x"
check(M.apply(world(),startup,enabled)==0,"a wrong type is not coerced")
print("PASS test_muluna_power_difficulty")
