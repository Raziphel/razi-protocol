"""The exported Aegis state must be finalized without PlanetsLib reparenting."""
import re
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

class BellicosCoherence(unittest.TestCase):
    def test_native_and_source_layers_share_parent_geometry(self):
        source=(ROOT/"prototypes/system/bellicos.lua").read_text()
        self.assertIn('local function plan_expedition()',source)
        self.assertIn('local atan2=math.atan2 or math.atan',source)
        self.assertNotIn('(math.atan(dx,-dy)/(2*math.pi))%1',source)
        self.assertIn('(atan2(dx,-dy)/(2*math.pi))%1',source)
        self.assertIn('local function position_expedition(pre_render)',source)
        self.assertIn('if pre_render and #updates>0',source)
        self.assertIn('local function reconcile_baked_art()',source)
        self.assertIn('and virtual_pulsar then origin=virtual_pulsar end',source)
        self.assertIn('delta[1]+origin.x*32',source)
        self.assertIn('delta[2]+origin.y*32',source)
        self.assertIn('for _,kind in ipairs({"space-location","planet"}) do',source)
        # Post-render must NOT call the graphics library's recursive updater.
        final=source.split('function bellicos.data_final_fixes()',1)[1]
        self.assertNotIn('PlanetsLib:update(',final)
        self.assertIn('bellicos.reconcile_final_positions()',final)

    def test_native_repair_runs_after_general_galaxy_layout(self):
        final=(ROOT/"data-final-fixes.lua").read_text()
        first=final.index('require("prototypes.system.galaxy_layout").data_final_fixes()')
        bel=final.index('require("prototypes.system.bellicos").data_final_fixes()')
        critical=final.index('require("prototypes.system.galaxy_layout").confirm_critical_positions()')
        last=final.index('require("prototypes.system.bellicos").reconcile_final_positions()')
        self.assertLess(first,bel)
        self.assertLess(bel,critical)
        self.assertLess(critical,last)

    def test_bellicos_probe_fixture_covers_secretas_orphan(self):
        fixture=(ROOT/"tests/lua/test_bellicos_layout.lua").read_text()
        self.assertIn('body.origin={x=83,y=-160}',fixture)
        self.assertIn('dual_planets["point-warden"]',fixture)
        self.assertIn('dual_places.pulsar=nil',fixture)
        self.assertIn('Late PlanetsLib:update would displace',fixture)
        self.assertIn('math.atan=function(value) return lua_atan(value) end',fixture)
        self.assertIn('Missing pulsar sent Near Bellicos Orbit sideways',fixture)
        self.assertIn('Aegis location outside its pulsar system',fixture)

if __name__=="__main__":
    unittest.main()
