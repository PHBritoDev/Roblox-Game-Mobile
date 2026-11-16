"""Guards for the dawn/afternoon/dusk/night loop and midnight wrap."""
from pathlib import Path
import re
import unittest

SRC = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")

def clock_at(start, target, t):
    delta = (target - start + 12) % 24 - 12
    return (start + delta * t) % 24

class LightingCycleTests(unittest.TestCase):
    def test_dawn_is_present_without_replacing_previous_moods(self):
        for label in ("Golden Nostalgia", "Cold Twilight", "Starry Dream Night", "First Light Meadow"):
            self.assertIn('name="' + label + '"', SRC)
        self.assertIn("local sequence={1,2,3,4}", SRC)

    def test_midnight_interpolation_never_jumps_to_midday(self):
        self.assertIn("local clockDelta=(target.clock-start.clock+12)%24-12", SRC)
        self.assertIn("Lighting.ClockTime=(start.clock+clockDelta*smooth)%24", SRC)
        self.assertGreater(clock_at(23.6, 6.35, 0.5), 0)
        self.assertLess(clock_at(23.6, 6.35, 0.5), 6.35)
        self.assertAlmostEqual(clock_at(23.6, 6.35, 1), 6.35)

    def test_mobile_update_interval_preserved(self):
        self.assertIn("task.wait(0.5)", SRC)
        self.assertIn("if t>=1 then break end", SRC)

if __name__ == "__main__":
    unittest.main()
