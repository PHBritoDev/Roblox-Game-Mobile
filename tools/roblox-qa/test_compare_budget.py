#!/usr/bin/env python3
"""Regression tests for the headless budget comparator (not client FPS)."""
import unittest

from compare_budget import compare, metrics


def scene(parts=3, collision=2, seconds=1.25, fallback=True, source="fallback"):
    return {
        "meta": {
            "partsTotal": parts,
            "generationComplete": True,
            "generationSeconds": seconds,
            "forcedAssetFailure": fallback,
            "forcedIntegrationFailure": False,
            "testedLiveInsertService": False,
        },
        "parts": [
            {"collide": i < collision, "shape": "MeshPart" if i == 0 else "Part"}
            for i in range(parts)
        ],
        "assets": {"source": source},
        "navigation": {"proxyCount": 2, "routes": [{"samples": [{}, {}, {}]}]},
    }


class BudgetComparisonTests(unittest.TestCase):
    def test_equivalent_scenes_report_deltas(self):
        result = compare(scene(3, 2, 1.25), scene(2, 1, 1.0))
        self.assertEqual(result["delta"]["parts"], -1)
        self.assertEqual(result["delta"]["collidable_parts"], -1)
        self.assertEqual(result["delta"]["generation_seconds"], -0.25)
        self.assertIn("not Android FPS", result["limitations"])

    def test_rejects_incomplete_snapshot(self):
        sample = scene()
        sample["meta"]["partsTotal"] += 1
        with self.assertRaisesRegex(ValueError, "Incomplete"):
            metrics(sample)

    def test_rejects_invalid_timing(self):
        for value in (None, float("nan"), -1, True):
            with self.subTest(value=value):
                sample = scene()
                sample["meta"]["generationSeconds"] = value
                with self.assertRaisesRegex(ValueError, "generationSeconds"):
                    metrics(sample)

    def test_rejects_mismatched_modes_and_sources(self):
        with self.assertRaisesRegex(ValueError, "modes"):
            compare(scene(), scene(fallback=False))
        with self.assertRaisesRegex(ValueError, "asset sources"):
            compare(scene(), scene(source="InsertService"))

    def test_rejects_same_total_but_different_route_distribution(self):
        candidate = scene()
        candidate["navigation"]["routes"] = [
            {"samples": [{}]}, {"samples": [{}, {}]}
        ]
        with self.assertRaisesRegex(ValueError, "coverage"):
            compare(scene(), candidate)

    def test_rejects_different_collision_proxy_coverage(self):
        candidate = scene()
        candidate["navigation"]["proxyCount"] = 1
        with self.assertRaisesRegex(ValueError, "coverage"):
            compare(scene(), candidate)

    def test_rejects_malformed_navigation_and_geometry(self):
        cases = [
            ("empty routes", lambda s: s["navigation"].update(routes=[]), "routes"),
            ("negative proxies", lambda s: s["navigation"].update(proxyCount=-1), "proxyCount"),
            ("boolean proxies", lambda s: s["navigation"].update(proxyCount=True), "proxyCount"),
            ("empty samples", lambda s: s["navigation"]["routes"][0].update(samples=[]), "samples"),
            ("bad parts total", lambda s: s["meta"].update(partsTotal=True), "partsTotal"),
            ("bad geometry", lambda s: s["parts"].__setitem__(0, None), "geometry part"),
        ]
        for label, mutate, message in cases:
            with self.subTest(label=label):
                candidate = scene()
                mutate(candidate)
                with self.assertRaisesRegex(ValueError, message):
                    metrics(candidate)

    def test_rejects_navigation_coverage_mismatch(self):
        candidate = scene()
        candidate["navigation"]["routes"][0]["samples"].pop()
        with self.assertRaisesRegex(ValueError, "coverage"):
            compare(scene(), candidate)


if __name__ == "__main__":
    unittest.main()
