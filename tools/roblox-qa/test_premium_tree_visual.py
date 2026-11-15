"""Prevent the rectangular-crown forest from returning to the playable scene."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
SOURCE = (ROOT / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")


class PremiumTreeVisualTests(unittest.TestCase):
    def test_no_procedural_lowpoly_tree_in_normal_population(self):
        population = SOURCE.split("local function plantOrReserve", 1)[1].split("-- Estrato autoral permanente:", 1)[0]
        self.assertNotIn("branchTree(", population)
        self.assertIn("table.insert(forestTreeSites", population)
        self.assertIn("table.clear(meshTreeSites)", SOURCE)

    def test_no_synty_lowpoly_tree_selection_or_alternating_crowns(self):
        synty = SOURCE.split("local selection={", 1)[1].split("local lookup={}", 1)[0]
        self.assertNotIn("Pine_Tree", synty)
        self.assertNotIn("PolygonNature_Tree", synty)
        self.assertNotIn("local treeTypes=", SOURCE)
        self.assertIn("table.insert(forestTreeSites,site)", SOURCE)

    def test_fallback_has_organic_crowns_instead_of_rectangular_leaf_sprays(self):
        fallback = SOURCE.split("local function branchTree", 1)[1].split("-- Reservar toda arvore", 1)[0]
        self.assertNotIn("leafSpray(", fallback)
        self.assertIn('orb("Copa organica reserva"', fallback)
        self.assertIn('orb("Cume organico reserva"', fallback)
        self.assertIn('orb("Copa dourada ancestral reserva"', SOURCE)

    def test_emergency_crowns_only_allowed_during_forced_asset_failure(self):
        from scene_quality import evaluate
        from test_scene_quality import flat_scene
        source = flat_scene()
        source["meta"].update(worldVersion=33, generationComplete=True)
        source["assets"] = {"reserved": 1, "fulfilled": 1, "foliageBalls": 3}
        self.assertFalse(evaluate(source)["pass"])
        source["meta"]["forcedAssetFailure"] = True
        result = evaluate(source)
        self.assertTrue(result["pass"])
        self.assertTrue(any("emergency" in message.lower() for message in result["assetWarnings"]))

    def test_premium_library_keeps_its_loading_paths_and_world_states(self):
        self.assertIn("return InsertService:LoadAsset(6933438443)", SOURCE)
        self.assertIn("return InsertService:LoadAsset(6432306802)", SOURCE)
        self.assertIn('SetAttribute("ForestState","Ready")', SOURCE)
        self.assertIn('SetAttribute("PremiumTreeSites"', SOURCE)
        self.assertIn("for i=1,84 do", SOURCE)
        self.assertNotIn("ForestLibrary.rbxmx", (ROOT / "default.project.json").read_text())


if __name__ == "__main__":
    unittest.main()
