"""Static regression guard for the authored firefly VFX (not a Roblox render test)."""
from pathlib import Path
import re
import unittest

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")


class AmbientVfxBudgetTests(unittest.TestCase):
    def test_fireflies_have_low_particle_overdraw(self):
        match = re.search(r'emitter\.Rate\s*=\s*(\d+)', SOURCE)
        self.assertIsNotNone(match)
        self.assertLessEqual(int(match.group(1)), 10)
        self.assertIn("emitter.LightEmission=0.5", SOURCE)
        self.assertIn("emitter.Acceleration=Vector3.new(0,0.22,0)", SOURCE)

    def test_invisible_particle_anchor_has_no_shadow_or_query(self):
        block = SOURCE.split('local fireflies=part("Vagalumes na clareira"', 1)[1].split('local emitter=', 1)[0]
        self.assertIn("fireflies.CastShadow=false", block)
        self.assertIn("fireflies.CanQuery=false", block)
        self.assertIn("fireflies.CanCollide=false", block)

    def test_no_new_dynamic_light_per_particle(self):
        block = SOURCE.split('local emitter=Instance.new("ParticleEmitter")', 1)[1].split('emitter.Parent=fireflies', 1)[0]
        self.assertNotIn('Instance.new("PointLight")', block)


if __name__ == "__main__":
    unittest.main()
