-- Diagnostic only: record unknown legacy prototypes, never guess.
local M={}
function M.scan()
  local count,reported=0,0
  local function warn(label)
    count=count+1
    if reported<20 and type(log)=="function" then
      log("[Razi Protocol/2.1.22 needs upstream fix] "..label)
      reported=reported+1
    end
  end
  for name,effect in pairs(data.raw["tile-effect"] or {}) do
    if type(effect.water)=="table" and effect.water.textures~=nil then
      warn("tile-effect/"..name..".water.textures")
    end
  end
  for kind,prototypes in pairs(data.raw) do
    if type(prototypes)=="table" then
      for name,proto in pairs(prototypes) do
        if type(proto)=="table" then
          for _,field in ipairs({"fluid_box","input_fluid_box","output_fluid_box",
              "fuel_fluid_box","oxidizer_fluid_box"}) do
            local box=proto[field]
            if type(box)=="table" and (box.minimum_temperature~=nil or
                box.maximum_temperature~=nil) then
              warn(kind.."/"..name.."."..field)
            end
          end
          if type(proto.fluid_boxes)=="table" then
            for i,box in pairs(proto.fluid_boxes) do
              if type(box)=="table" and (box.minimum_temperature~=nil or
                  box.maximum_temperature~=nil) then
                warn(kind.."/"..name..".fluid_boxes["..tostring(i).."]")
              end
            end
          end
        end
      end
    end
  end
  if count>reported and type(log)=="function" then
    log("[Razi Protocol/2.1.22] "..(count-reported).." more unresolved entries")
  end
  return count
end
return M
