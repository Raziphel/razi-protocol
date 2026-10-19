"""Guard phase-3 compatibility and platform hot-path changes."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class Phase3Compatibility(unittest.TestCase):
    def test_version_gated_shim_is_still_removable_as_one_unit(self):
        final=read("data-final-fixes.lua")
        loader=read("temporary/factorio_2_1_22/loader.lua")
        self.assertEqual(final.count(
            'require("temporary.factorio_2_1_22.loader")'),1)
        self.assertIn("if not applies() then return 0 end",loader)
        self.assertIn(
            'require("temporary.factorio_2_1_22.audit").scan()',loader)
        audit=read("temporary/factorio_2_1_22/audit.lua")
        self.assertIn('proto.energy_source.type=="fluid"',audit)
        self.assertIn('{"fluid_box","output_fluid_box"}',audit)

    def test_registry_recognizes_all_patch_statuses(self):
        registry=json.loads(read("compat/registry.json"))
        allowed={"needs-review","reported-upstream-unknown-release",
                 "fixed-upstream-pending-verification","local-only"}
        self.assertTrue(all(entry["upstream_status"] in allowed
                            for entry in registry["patches"]))
        panglia=next(entry for entry in registry["patches"]
                     if entry["id"]=="panglia-biooptic-exchanges")
        self.assertIn("engine",panglia["validation_note"])

    def test_old_galactic_panel_not_loaded_on_runtime_hot_path(self):
        control=read("control.lua")
        self.assertNotIn('require("scripts.galactic_operations")',control)
        self.assertIn("retire_connected_operations()",control)
        self.assertIn("events:on_event(defines.events.on_space_platform_changed_state,record_platform)",control)

    def test_build_events_do_not_scan_every_connected_player(self):
        control=read("control.lua")
        construction=control.split(
            "local function record_platform_construction(event)",1)[1]
        construction=construction.split(
            "events:on_event(defines.events.on_space_platform_built_entity",1)[0]
        self.assertNotIn("deep_expedition.observe_connected",construction)
        self.assertIn("great_projects.observe(platform)",construction)
        self.assertIn("deep_expedition.observe_connected()",control)
        projects=read("scripts/razi_great_projects.lua")
        self.assertLess(
            projects.index("if previous and previous.from==from and previous.to==to then"),
            projects.index("ark=qualified_ark(platform)"))

if __name__=="__main__":
    unittest.main()
