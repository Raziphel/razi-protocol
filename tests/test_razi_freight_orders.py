"""Source-backed Orbital Catapult freight planning UI regression guards."""
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

class FreightDeskTests(unittest.TestCase):
    def test_manual_staging_never_changes_real_freight(self):
        data=read("scripts/razi_freight_orders.lua")
        self.assertIn('require("scripts.razi_catapult_network")',data)
        self.assertIn("function M.route(force,id)",data)
        self.assertIn("function M.stacks(name,count)",data)
        self.assertIn("math.ceil(count/size)",data)
        self.assertIn("positive_count",data)
        self.assertIn("MAX_ITEMS=1000000",data)
        self.assertIn("LIMIT=20",data)
        self.assertIn("function M.cleanup(index)",data)
        self.assertIn("function M.clear(player)",data)
        self.assertIn("function M.saved_count(player)",data)
        self.assertIn("tech.researched==true",data)
        for forbidden in ("player.teleport(", "inventory.insert(",
                          "inventory.remove(", "surface.create_entity(",
                          "game.print(", "script.on_nth_tick", "on_tick("):
            self.assertNotIn(forbidden,data)
        self.assertIn("packed=not order.packed",data)
        self.assertNotIn('action=="launch"',data)

    def test_cargo_ui_is_live_and_interactive(self):
        view=read("scripts/razi_freight_dispatch_ui.lua")
        self.assertIn("type=\"choose-elem-button\"",view)
        self.assertIn('elem_type="item"',view)
        self.assertIn('razi_ops_action="freight-item"',view)
        self.assertIn('razi_ops_action="freight-count"',view)
        self.assertIn('razi_ops_action="freight-add"',view)
        self.assertIn('razi_ops_action="freight-select"',view)
        self.assertIn('razi_ops_action="freight-packed"',view)
        self.assertIn('razi_ops_action="freight-remove"',view)
        self.assertIn('razi_ops_action="freight-clear"',view)
        self.assertIn('player.get_item_count(entry.item)',view)
        self.assertIn('freight-board-manual',view)
        self.assertIn('freight_board.render(card,player,state,width)',
                      read("scripts/galactic_trade.lua"))

    def test_journal_control_wires_all_gui_events(self):
        journal=read("scripts/razi_journal.lua")
        control=read("control.lua")
        for action in ('freight-select','freight-add','freight-packed',
                       'freight-remove','freight-item','freight-count'):
            self.assertIn(action,journal)
        for snippet in ("freight_orders.select", "freight_orders.add",
                        "freight_orders.update", "freight_orders.item_changed",
                        "freight_orders.count_changed", "freight_orders.cleanup"):
            self.assertIn(snippet,journal)
        self.assertIn("function M.elem_changed(event)",journal)
        self.assertIn("defines.events.on_gui_elem_changed",control)
        self.assertIn("razi_journal.elem_changed(event)",control)

    def test_localizations_complete(self):
        ops=read("locale/en/galactic_operations.cfg")
        needed=("freight-board-heading","freight-board-explainer",
                "freight-board-undiscovered","freight-board-direction",
                "freight-board-selected","freight-board-add",
                "freight-board-select-item","freight-board-stacks",
                "freight-board-carried","freight-board-pick-route",
                "freight-board-list","freight-board-order",
                "freight-board-planned","freight-board-packed",
                "freight-board-pack","freight-board-undo",
                "freight-board-remove","freight-board-invalid",
                "freight-board-manual","freight-board-clear",
                "freight-board-unavailable")
        for name in needed:
            self.assertIn("\n"+name+"=",ops,name)

    def test_manual_workflow_is_inexpensive(self):
        workflow=read(".github/workflows/check.yml")
        self.assertIn("test_razi_freight_orders.lua",workflow)
        self.assertIn("workflow_dispatch:",workflow)
        self.assertNotIn("\n  push:",workflow)

if __name__=="__main__":
    unittest.main()
