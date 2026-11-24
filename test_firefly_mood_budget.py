"""Static VFX contract: no visual claim without Roblox screenshot."""
from pathlib import Path
import re
import unittest

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")


class FireflyMoodBudgetTests(unittest.TestCase):
    def test_moods_within_mobile_budget(self):
        rates = [int(x) for x in re.findall(r"fireflyRate=(\d+)", SOURCE)]
        self.assertEqual(rates, [2, 6, 8, 1])
        self.assertLessEqual(max(rates), 8)

    def test_mood_is_applied_and_interpolated(self):
        self.assertIn("emitter.Rate=mood.fireflyRate", SOURCE)
        self.assertIn(
            "emitter.Rate=start.fireflyRate+(target.fireflyRate-start.fireflyRate)*smooth",
            SOURCE,
        )

    def test_only_one_authored_particle_emitter(self):
        self.assertEqual(SOURCE.count('Instance.new("ParticleEmitter")'), 1)


if __name__ == "__main__":
    unittest.main()
