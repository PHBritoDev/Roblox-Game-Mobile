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


    def test_invalid_numeric_fields(self):
        for value in ("bad", None, [], float("nan"), float("inf"), True):
            with self.subTest(field="footing.y", value=value):
                result = module.navigation_failures({"routes": [], "spawn": {"present": True, "anchored": True, "collidable": True, "footing": {"supported": True, "y": value}}, "proxyCount": 1})
                self.assertTrue(any("Spawn missing" in error for error in result))
            with self.subTest(field="proxyCount", value=value):
                result = module.navigation_failures({"routes": [], "spawn": {}, "proxyCount": value})
                self.assertIn("No physical tree/rock proxies measured", result)

    def test_valid_numeric_fields_do_not_trigger_numeric_errors(self):
        result = module.navigation_failures({"routes": [], "spawn": {"present": True, "anchored": True, "collidable": True, "footing": {"supported": True, "y": 0.0}}, "proxyCount": 3})
        self.assertNotIn("No physical tree/rock proxies measured", result)
        self.assertFalse(any("Spawn missing" in error for error in result))

if __name__ == "__main__":
    unittest.main()
