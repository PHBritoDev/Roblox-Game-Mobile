"""Regression checks: visible Synty trunks and their invisible colliders share terrain elevation."""
from pathlib import Path
import re
import unittest

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")


class GroundedTrunkCollisionTests(unittest.TestCase):
    def test_proxy_uses_ground_height(self):
        self.assertRegex(SOURCE, r"local function trunkProxy\(x,z,height,diameter,parent,groundY\)")
        self.assertIn("CFrame.new(x,(groundY or 0)+height*0.5,z)", SOURCE)

    def test_synty_tree_proxy_uses_terrain_raycast(self):
        self.assertIn("syntyGroundY(entry[2],entry[3])", SOURCE)
        self.assertIn("FilterDescendantsInstances={terrain}", SOURCE)
        self.assertIn("IgnoreWater=true", SOURCE)

    def test_raycast_defined_before_tree_placement(self):
        self.assertLess(SOURCE.index("local function syntyGroundY"), SOURCE.index("trunkProxy(entry[2]"))

    def test_no_unadjusted_synty_trunk_proxies(self):
        calls = re.findall(r"^\s*trunkProxy\([^\n]+", SOURCE, re.MULTILINE)
        self.assertTrue(calls)
        self.assertTrue(all("syntyGroundY(" in call or "groundY" in call for call in calls))


if __name__ == "__main__":
    unittest.main()
