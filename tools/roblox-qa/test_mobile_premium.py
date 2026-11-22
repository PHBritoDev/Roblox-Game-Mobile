"""Regression tests: publish the compact audited library, not the fallback-only Place."""
from pathlib import Path
import unittest

from verify_mobile_premium import ROOT, ASSET, EXPECTED, validate

class MobilePremiumDeploymentTests(unittest.TestCase):
    def test_curated_offline_library_is_complete_and_safe(self):
        validate()

    def test_publishing_uses_verified_premium_project(self):
        deploy=(ROOT / ".github/workflows/publicar-teste-roblox.yml").read_text(encoding="utf-8")
        self.assertIn("rojo build mobile-premium.project.json -o DreamcorePrototype.rbxlx",deploy)
        self.assertIn("python3 tools/roblox-qa/verify_mobile_premium.py DreamcorePrototype.rbxlx",deploy)
        self.assertIn('default: Saved',deploy)
        self.assertIn('          - Published',deploy)
        self.assertIn('environment: roblox-teste',deploy)
        self.assertIn('--data-binary @DreamcorePrototype.rbxlx',deploy)

    def test_mobile_models_are_smaller_than_full_archive(self):
        self.assertTrue(ASSET.exists())
        self.assertLess(ASSET.stat().st_size, 1_200_000)
        self.assertLess(ASSET.stat().st_size, (ROOT / "assets/ForestLibrary.rbxmx").stat().st_size * 0.70)

if __name__ == "__main__":
    unittest.main()
