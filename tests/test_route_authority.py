"""Static contract for the final Razi-owned route pass."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class CuratedRoutesTests(unittest.TestCase):
    def test_final_authority_runs_after_other_mod_integrations(self):
        order=read("data-final-fixes.lua")
        dyson='require("prototypes.compat.calidus_dyson").connect_calidus()'
        manager='require("prototypes.system.route_authority").data_final_fixes()'
        icons='require("prototypes.system.route_icons").data_final_fixes()'
        overlay='require("prototypes.system.route_highlights").data_final_fixes()'
        self.assertLess(order.index(dyson),order.index(manager))
        self.assertLess(order.index(manager),order.index(icons))
        self.assertLess(order.index(manager),order.index(overlay))
        self.assertLess(order.index(
            'require("prototypes.system.community_expansions").data_final_fixes()'),
            order.index(manager))

    def test_one_catalog_is_exposed(self):
        original=read("prototypes/system/route_reconcile.lua")
        authoritative=read("prototypes/system/route_authority.lua")
        self.assertIn("route_reconcile.allowed_pairs=allowed",original)
        self.assertIn("route_reconcile.membership=membership",original)
        self.assertIn("local allowed=reconcile.allowed_pairs",authoritative)
        self.assertIn("local member=reconcile.membership",authoritative)
        self.assertNotIn('routes = {}',authoritative)
        self.assertIn('routes[name]=nil',authoritative)

    def test_preserves_safe_gateways_and_original_asteroid_belt(self):
        manager=read("prototypes/system/route_authority.lua")
        self.assertIn('{"nauvis","muluna"}',manager)
        self.assertIn('{"asteroid-belt-inner-edge","asteroid-belt-outer-edge"}',manager)
        self.assertIn('{"crucible-orbit","crucible"}',manager)
        self.assertIn('"planet-discovery-sunorbit"',manager)
        self.assertIn('"slp-solar-system-sun2"',manager)
        self.assertIn("profiles.preserve_custom(saved,discarded)",manager)
        self.assertIn("local lifelines={}",manager)
        self.assertIn("table.sort(names)",manager)

    def test_sensible_default_with_debug_escape_hatch(self):
        info=json.loads(read("info.json"))
        self.assertEqual(info["version"],"2.1.47")
        self.assertIn('startup_toggle("razi-curated-space-routes"',read("settings.lua"))
        self.assertIn('"razi-curated-space-routes"',read("prototypes/system/route_authority.lua"))
        self.assertIn('razi-curated-space-routes=',read("locale/en/settings.cfg"))
        self.assertIn("razi-curated-space-routes",read("prototypes/system/route_authority.lua"))

if __name__=="__main__":
    unittest.main()
