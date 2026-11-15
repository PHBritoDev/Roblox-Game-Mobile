"""Forest Pack failures must remain observable even when loading or the hero fails."""
from pathlib import Path
import unittest

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")

class ForestFailureCoverage(unittest.TestCase):
    def test_counter_initialized_before_integration(self):
        self.assertLess(SOURCE.index('world:SetAttribute("ForestTreePlacementFailures",0)'), SOURCE.index('local forestIntegrated,forestError='))
    def test_missing_pack_reports_all_fallback_sites(self):
        self.assertEqual(SOURCE.count('world:SetAttribute("ForestTreePlacementFailures",#forestTreeSites+1)'), 2)
    def test_missing_hero_variant_is_counted(self):
        self.assertIn('warn("[Dreamcore] Arvore principal Forest Pack ausente; fallback ativado.")', SOURCE)
        self.assertIn('local okHero,heroError=pcall(plantForest', SOURCE)
        self.assertIn('tostring(heroError)', SOURCE)

    def test_hero_failure_is_counted(self):
        self.assertIn('if okHero then', SOURCE)
        self.assertIn('warn("[Dreamcore] Falha ao posicionar arvore principal Forest Pack; fallback ativado:",tostring(heroError))', SOURCE)

if __name__ == "__main__":
    unittest.main()
