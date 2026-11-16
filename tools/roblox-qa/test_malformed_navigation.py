"""Regression checks: corrupted navigation snapshots must fail closed, not raise."""
import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("scene_quality", Path(__file__).with_name("scene_quality.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class MalformedNavigationTests(unittest.TestCase):
    def test_bad_root(self):
        for value in (None, [], "invalid", 5):
            with self.subTest(value=value):
                self.assertTrue(module.navigation_failures(value))

    def test_bad_routes(self):
        for value in (None, {}, ["bad"], [{"name": None}]):
            with self.subTest(value=value):
                self.assertTrue(module.navigation_failures({"routes": value}))

    def test_bad_samples(self):
        for value in (None, {}, ["bad"]):
            with self.subTest(value=value):
                failures = module.navigation_failures({"routes": [{"name": "main:0", "samples": value}]})
                self.assertTrue(any("malformed samples" in error for error in failures))

    def test_bad_spawn(self):
        for value in (None, [], "invalid"):
            with self.subTest(value=value):
                failures = module.navigation_failures({"routes": [], "spawn": value})
                self.assertTrue(any("Malformed spawn" in error for error in failures))


if __name__ == "__main__":
    unittest.main()
