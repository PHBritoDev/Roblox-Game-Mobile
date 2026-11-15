"""Headless QA should not leave the endless lighting task running."""
from pathlib import Path
import unittest

from snapshot_scene import disable_headless_mood_cycle

ROOT = Path(__file__).resolve().parents[2]


class HeadlessMoodCycleTests(unittest.TestCase):
    def test_only_perpetual_cycle_changes(self):
        source = (ROOT / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
        transformed = disable_headless_mood_cycle(source)
        self.assertEqual(transformed.count(" while false do"), 1)
        self.assertEqual(transformed.count("applyMood(moods[1])"), 1)
        self.assertEqual(transformed.count("task.spawn(function()"), source.count("task.spawn(function()"))
        self.assertIn('SetAttribute("ForestState","Ready")', transformed)
        self.assertNotEqual(source, transformed)

    def test_rejects_unexpected_source(self):
        with self.assertRaises(ValueError):
            disable_headless_mood_cycle("while true do end")


if __name__ == "__main__":
    unittest.main()
