"""Regression guard: local fauna follows terrain without stale streaming caches.

This is a static contract; GitHub headless geometry cannot simulate Android clients.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
BUTTERFLIES = (ROOT / "src/client/MeadowButterflies.client.luau").read_text(encoding="utf-8")
WILDLIFE = (ROOT / "src/client/Wildlife.client.luau").read_text(encoding="utf-8")


class ClientFaunaStreamingTests(unittest.TestCase):
    def test_butterflies_invalidate_height_when_forest_unavailable(self):
        self.assertIn('GetAttribute("ForestState")~="Ready"', BUTTERFLIES)
        self.assertIn("b.ground=nil; b.groundX=nil; b.groundZ=nil", BUTTERFLIES)
        self.assertIn("center=nil", BUTTERFLIES)
        self.assertIn("wasActive=false", BUTTERFLIES)

    def test_butterflies_follow_movement_without_unbounded_raycast(self):
        self.assertIn("GROUND_REFRESH=0.55", BUTTERFLIES)
        self.assertIn("(x-b.groundX)^2+(z-b.groundZ)^2>9", BUTTERFLIES)
        self.assertIn("if refresh or moved or b.ground==nil then", BUTTERFLIES)
        self.assertIn("clock*0.065", BUTTERFLIES)
        self.assertIn("local UPDATE_INTERVAL=0.09", BUTTERFLIES)
        self.assertIn("b.groundX=x; b.groundZ=z", BUTTERFLIES)

    def test_rabbits_reanchor_on_streaming_and_respawn(self):
        self.assertIn("habitatCenter=nil", WILDLIFE)
        self.assertIn("r.groundY=nil; r.groundX=nil; r.groundZ=nil", WILDLIFE)
        self.assertIn("(x-r.groundX)^2+(z-r.groundZ)^2>9", WILDLIFE)
        self.assertIn("if updateGround or moved or r.groundY==nil then", WILDLIFE)
        self.assertIn("r.groundX=x; r.groundZ=z", WILDLIFE)

    def test_fauna_remains_local_and_non_colliding(self):
        for source in (BUTTERFLIES, WILDLIFE):
            self.assertIn("p.CanCollide=false", source)
            self.assertIn("p.CastShadow=false", source)
            self.assertIn("RunService.Heartbeat:Connect", source)
            self.assertIn("script.Destroying:Connect", source)
        self.assertIn("local COUNT=4", BUTTERFLIES)
        self.assertIn("local MAX_RABBITS=3", WILDLIFE)


if __name__ == "__main__":
    unittest.main()
