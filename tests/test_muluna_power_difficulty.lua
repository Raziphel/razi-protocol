-- Run: texlua tests/test_muluna_power_difficulty.lua
package.path="./?.lua;./?/init.lua;"..package.path
local M=require("prototypes.compat.muluna_power_difficulty")
local startup={
 ["razi-difficulty-preset"]={value="normal"},
 ["platform-power-consumption"]={value=130}
}
local enabled={["planet-muluna"]="2.7.25"}
local raw={
 accumulator={
  ["muluna-satellite-radar"]={
   energy_usage="130MW",
   energy_source={buffer_capacity="390MJ",input_flow_limit="390MW",
     output_flow_limit="0MW"},
   custom_tooltip_fields={
    {value={"tooltip-value.muluna-satellite-radar-scan-energy","130"},
     quality_values={normal={"tooltip-value.muluna-satellite-radar-scan-energy","130"},
                     rare={"tooltip-value.muluna-satellite-radar-scan-energy","81"}}},
    {value={"tooltip-value.muluna-satellite-radar-scan-size","100"},
     quality_values={normal={"tooltip-value.muluna-satellite-radar-scan-size","100"}}}
   }
  }
 },
 ["mod-data"]={
  ["muluna-satellite-radar"]={data={entities={
   ["muluna-satellite-radar"]={name="muluna-satellite-radar",
       energy_per_scan=130,scan_area=100}
  }}}
 }
}
local beacon=raw.accumulator["muluna-satellite-radar"]
local entity=raw["mod-data"]["muluna-satellite-radar"].data.entities["muluna-satellite-radar"]
assert(M.apply(raw,startup,enabled)==0,"Normal must be untouched")
assert(beacon.energy_usage=="130MW" and entity.energy_per_scan==130)
startup["razi-difficulty-preset"].value="hard"
assert(M.apply(raw,startup,enabled)>0)
assert(beacon.energy_usage=="125MW")
assert(beacon.energy_source.buffer_capacity=="375MJ")
assert(beacon.energy_source.input_flow_limit=="375MW")
assert(beacon.energy_source.output_flow_limit=="0MW")
assert(entity.energy_per_scan==125 and entity.scan_area==100)
assert(beacon.custom_tooltip_fields[1].value[2]=="125")
assert(beacon.custom_tooltip_fields[2].value[2]=="100")
assert(M.apply(raw,startup,enabled)==0,"Repeated passes are idempotent")
startup["razi-difficulty-preset"].value="nightmare"
assert(M.apply(raw,startup,enabled)>0)
assert(beacon.energy_usage=="170MW")
assert(beacon.energy_source.buffer_capacity=="510MJ")
assert(entity.energy_per_scan==170)
startup["razi-difficulty-preset"].value="normal"
assert(M.apply(raw,startup,enabled)==0,"Normal must NEVER normalize")
assert(beacon.energy_usage=="170MW")
startup["razi-difficulty-preset"].value="custom"
assert(M.apply(raw,startup,enabled)==0)
startup["razi-difficulty-preset"].value="easy"
assert(M.apply(raw,startup,enabled)>0)
assert(beacon.energy_usage=="75MW")
assert(entity.energy_per_scan==75)
assert(M.apply(raw,startup,{})==0,"Disabled dependency untouched")
assert(M.apply({accumulator={}},startup,enabled)==0,"Missing prototype skipped")
print("Muluna satellite power native numerical settings: PASS")
