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
        self.assertNotIn('local nx,ny=near and native_point(near)',source)
        self.assertIn('nx,ny=native_point(near)',source)
        self.assertIn('and type(nx)=="number" and type(ny)=="number"',source)
        self.assertNotIn('(math.atan(dx,-dy)/(2*math.pi))%1',source)
        self.assertIn('(atan2(dx,-dy)/(2*math.pi))%1',source)
        self.assertIn('local function position_expedition(pre_render)',source)
        self.assertIn('if pre_render then',source)
        self.assertNotIn('PlanetsLib:update(updates)',source)
        self.assertIn('body.origin={x=0,y=0}',source)
        self.assertIn('body.distance=math.sqrt(x*x+y*y)',source)
        self.assertIn('local function find_wardens()',source)
        self.assertIn('local function reconcile_baked_art()',source)
        self.assertIn('if target.name==near and virtual_pulsar then',source)
        self.assertIn('origin=virtual_pulsar',source)
        self.assertIn('delta[1]+origin.x*32',source)
        self.assertIn('delta[2]+origin.y*32',source)
        self.assertIn('for _,kind in ipairs({"space-location","planet"}) do',source)
        # Post-render must NOT call the graphics library's recursive updater.
        final=source.split('function bellicos.data_final_fixes()',1)[1]
        self.assertNotIn('PlanetsLib:update(',final)
        self.assertIn('bellicos.reconcile_final_positions()',final)

    def test_aegis_waypoints_have_distinct_route_bearings(self):
        """The inner crossing must not look like overlapping red tracks."""
        import math
        import re
        source=(ROOT/"prototypes/system/bellicos.lua").read_text()
        def placement(name):
            match=re.search(
                rf'append\({re.escape(name)},near,virtual_near,([\d.]+),([\d.]+)',
                source)
            self.assertIsNotNone(match,name)
            radius,turn=(float(v) for v in match.groups())
            return (radius*math.sin(2*math.pi*turn),
                    -radius*math.cos(2*math.pi*turn))
        inner=placement('"aegis-inner-edge"')
        warden=placement('name')
        outer=placement('"aegis-outer-edge"')
        self.assertNotIn('append(bellicos_gate',source)
        departure1=(warden[0]-inner[0],warden[1]-inner[1])
        departure2=(outer[0]-inner[0],outer[1]-inner[1])
        cross=abs(departure1[0]*departure2[1]-departure1[1]*departure2[0])
        spread=cross/(math.hypot(*departure1)*math.hypot(*departure2))
        self.assertLess(spread,.25,"The deliberately contiguous Aegis spine is zig-zagging")
        self.assertGreater(warden[0],inner[0],"Point Warden should be the terminus")
        self.assertGreater(warden[1],inner[1],"Warden must follow the inner rim")
        self.assertLess(outer[0],inner[0],"Outer Edge must face the entry gate")
        self.assertLess(outer[1],inner[1],"Outer Edge must precede Inner Edge")
        self.assertNotIn('deleteRoutesBetween("aegis-inner-edge"',source)

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
        self.assertIn('local ok, near_mod_or_error, near_locations=pcall(run,{near=true})',fixture)
        self.assertIn('Aegis location outside its pulsar system',fixture)
        self.assertIn('alias_warden=true',fixture)
        self.assertIn('Alternate Warden still renders outside Bellicos',fixture)

if __name__=="__main__":
    unittest.main()
