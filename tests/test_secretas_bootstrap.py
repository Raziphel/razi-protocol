"""Regression guard for Secretas Golden Science / Steam Recycler startup."""
from pathlib import Path
import json
import unittest

ROOT=Path(__file__).resolve().parents[1]
def source(path):
    return (ROOT/path).read_text(encoding="utf-8")

class SecretasBootstrapTests(unittest.TestCase):
    def test_repair_respects_original_source_triggers(self):
        code=source("prototypes/compat/prototype_sanity.lua")
        self.assertIn('effect.recipe=="gold-plate"',code)
        self.assertIn('recycler.research_trigger.type=="mine-entity"',code)
        self.assertIn('golden.research_trigger.item=="gold-plate"',code)
        self.assertIn('recycler.prerequisites[i]=="golden-science-pack"',code)
        self.assertIn('table.remove(recycler.prerequisites,i)',code)
        self.assertIn('depends_on_technology("steam-recycler","golden-science-pack")',code)
        self.assertIn('and technology_has_prerequisite("golden-science-pack","steam-recycler")',code)
        self.assertIn('if not exact_cycle then',code)
        self.assertIn('add_technology_prerequisite_if_present("golden-science-pack","steam-recycler")',code)
        self.assertNotIn('add_technology_prerequisite_if_present("golden-science-pack", "steam-recycler")',code)
        self.assertIn('restore_secretas_science_bootstrap()',code)

    def test_rechecked_after_late_progression(self):
        fixes=source("data-final-fixes.lua")
        self.assertIn('require("prototypes.compat.prototype_sanity").restore_secretas_science_bootstrap()',fixes)
        self.assertGreater(
            fixes.index('require("prototypes.compat.prototype_sanity").restore_secretas_science_bootstrap()'),
            fixes.index('require("prototypes.compat.frontier_recovery").data_final_fixes()'))
        self.assertGreater(
            fixes.index('repair("after-all-razi-technology")'),
            fixes.index('require("prototypes.compat.prototype_sanity").restore_secretas_science_bootstrap()'))

    def test_required_worlds_unchanged(self):
        manifest=json.loads(source("info.json"))
        self.assertGreaterEqual(tuple(map(int,manifest["version"].split("."))),(2,1,86))
        self.assertIn("PlanetAthos >= 1.1.3",manifest["dependencies"])
        self.assertIn("nulla >= 1.0.2",manifest["dependencies"])
        self.assertIn("secretas >= 1.0.37",manifest["dependencies"])

if __name__=="__main__":
    unittest.main()
