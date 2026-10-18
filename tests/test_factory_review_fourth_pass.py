"""Cross-check the combined Pass 4 factory review entrypoint."""
import unittest

from tools.factory_review import build_report


class FactoryReviewFourthPassTests(unittest.TestCase):
    def test_scenario_is_included_without_fake_prices(self):
        raw={"raw":{"recipe":{},"technology":{}}}
        report=build_report(raw)
        self.assertIn("freight_break_even",report)
        self.assertIn("route_distance_advisories",report)
        self.assertEqual(report["freight_break_even"]["route_context"],[])
        self.assertTrue(all(r["status"]=="not-registered" for r in
                            report["freight_break_even"]["recipes"].values()))

    def test_route_context_does_not_become_transport_cost(self):
        raw={"raw":{"recipe":{},"technology":{},"space-connection":{
            "a-b":{"from":"a","to":"b","length":1234}}}}
        report=build_report(raw,lanes=[("a","b")])
        routes=report["freight_break_even"]["route_context"]
        self.assertEqual(routes[0]["kilometres"],1234)
        self.assertIsNone(
            report["freight_break_even"]["recipes"]["razi-bio-rare-metal-casting"]
            .get("maximum_freight_credits_per_craft"))
        self.assertIsInstance(report["route_distance_advisories"],list)


if __name__=="__main__":
    unittest.main()
