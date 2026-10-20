-- A curated, additive Nauvis New Game setup for Razi Protocol.
-- Do not replace Freeplay or change unrelated source planets' terrain.
-- Default MapGenPreset cannot contain settings alongside default=true,
-- so ship a named, user-selectable Razi Protocol preset.
local M={}
function M.data_final_fixes()
 local group=(data.raw["map-gen-presets"] or {}).default
 if not group or group["razi-protocol"] then return false end
 group["razi-protocol"]={
   order="a1[razi-protocol]",
   basic_settings={
     -- A comfortable industrial beachhead, but enough nearby hostiles to
     -- encourage defensive research before the first offworld journeys.
     starting_area=1.65,
     peaceful_mode=false,
     autoplace_controls={
       ["iron-ore"]={frequency=1.05,size=1.10,richness=1.20},
       ["copper-ore"]={frequency=1.05,size=1.05,richness=1.18},
       ["coal"]={frequency=1.0,size=1.0,richness=1.15},
       ["stone"]={frequency=1.10,size=1.0,richness=1.10},
       ["uranium-ore"]={frequency=.80,size=1.12,richness=1.10},
       ["crude-oil"]={frequency=1,size=1.15,richness=1.20},
       ["water"]={frequency=1.0,size=1.0},
       ["trees"]={frequency=1.1,size=1.05},
       ["enemy-base"]={frequency=.85,size=1.0,richness=1.0}
     }
   },
   advanced_settings={
     enemy_evolution={
       enabled=true,time_factor=.000004,
       destroy_factor=.002,pollution_factor=.0000009
     },
     enemy_expansion={
       enabled=true,
       min_expansion_distance=2,
       max_expansion_distance=7,
       settler_group_min_size=5,
       settler_group_max_size=12,
       min_expansion_cooldown=14400,
       max_expansion_cooldown=216000
     },
     difficulty_settings={technology_price_multiplier=1}
   }
 }
 return true
end
return M
