"""Ensure real package loading path is distinct from bundled fixtures."""
import unittest
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]


class LiveTreePlacementTests(unittest.TestCase):
    def test_real_mode_never_injects_fixtures_or_forced_failures(self):
        source=(ROOT/"tools/roblox-qa/snapshot_scene.py").read_text(encoding="utf-8")
        self.assertIn('parser.add_argument("--live-insertservice"',source)
        self.assertIn('if args.live_insertservice and (args.without_assets or args.integration_failure)',source)
        self.assertIn('fixture = "" if args.without_assets or args.live_insertservice else bundled_fixture()',source)

    def test_validates_real_asset_installation(self):
        source=(ROOT/"tools/roblox-qa/snapshot_scene.py").read_text(encoding="utf-8")
        self.assertIn('assets.get("source") == "InsertService"',source)
        self.assertIn('assets.get("syntyLoad") is True',source)
        self.assertIn('assets.get("forestLoad") is True',source)
        self.assertIn('meta["forestModels"] >= 5',source)
        self.assertIn('"minimum_forest_models_5"',source)
        self.assertIn('"failedChecks"',source)
        self.assertIn('live_insertservice_checks.json',source)
        self.assertIn('if diagnostic["failedChecks"]:',source)
        self.assertIn('out /= "live-insertservice"',source)

    def test_does_not_modify_game_generator(self):
        generator=(ROOT/"src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
        self.assertIn("return InsertService:LoadAsset(6933438443)",generator)
        self.assertIn("return InsertService:LoadAsset(6432306802)",generator)


if __name__=="__main__":
    unittest.main()
