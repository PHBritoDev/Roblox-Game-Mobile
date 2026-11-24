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
        self.assertEqual(result["delta"]["collidable_mesh_parts"], 0)  # first mesh remains collidable in both fixtures
        self.assertEqual(result["percent_change"]["parts"], -33.33)
        self.assertEqual(result["percent_change"]["collidable_parts"], -50.0)
        self.assertIn("not Android FPS", result["limitations"])

    def test_detects_collidable_mesh_removed(self):
        baseline, candidate = scene(), scene()
        candidate["parts"][0]["collide"] = False
        result = compare(baseline, candidate)
        self.assertEqual(result["delta"]["collidable_mesh_parts"], -1)
        self.assertEqual(result["delta"]["collidable_parts"], -1)

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

    def test_rejects_mismatched_fixture_modes(self):
        baseline, candidate = scene(), scene()
        baseline["meta"]["bakedEquivalentFixture"] = True
        candidate["meta"]["bakedEquivalentFixture"] = False
        with self.assertRaisesRegex(ValueError, "bakedEquivalentFixture"):
            compare(baseline, candidate)

    def test_zero_baseline_reports_undefined_percent(self):
        baseline, candidate = scene(collision=0), scene(collision=1)
        self.assertIsNone(compare(baseline, candidate)["percent_change"]["collidable_parts"])

    def test_rejects_same_total_but_different_route_distribution(self):
        candidate = scene()
        candidate["navigation"]["routes"] = [
            {"samples": [{}]}, {"samples": [{}, {}]}
        ]
        with self.assertRaisesRegex(ValueError, "coverage"):
            compare(scene(), candidate)

    def test_reports_collision_proxy_delta_with_same_routes(self):
        candidate = scene()
        candidate["navigation"]["proxyCount"] = 1
        result = compare(scene(), candidate)
        self.assertEqual(result["delta"]["collision_proxies"], -1)
        self.assertEqual(result["percent_change"]["collision_proxies"], -50.0)

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

    def test_rejects_corrupt_geometry_and_navigation(self):
        baseline = scene()
        cases = [
            (lambda s: s["parts"][0].update(collide="false"), "collision flag"),
            (lambda s: s["parts"][0].update(shape=None), "shape"),
            (lambda s: s["navigation"]["routes"][0]["samples"][0].update(x=1), "Incomplete navigation"),
            (lambda s: s["navigation"]["routes"][0]["samples"][0].update(x=float("nan"), z=2), "Invalid navigation"),
            (lambda s: s.update(assets=None), "asset metadata"),
        ]
        for mutate, message in cases:
            candidate = scene()
            mutate(candidate)
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                compare(baseline, candidate)

    def test_rejects_shifted_route_with_same_sample_count(self):
        baseline, candidate = scene(), scene()
        for item in (baseline, candidate):
            item["navigation"]["routes"][0]["name"] = "main:0"
            for index, sample in enumerate(item["navigation"]["routes"][0]["samples"]):
                sample.update(x=10.0, z=float(index))
        candidate["navigation"]["routes"][0]["samples"][1]["x"] = 11.0
        with self.assertRaisesRegex(ValueError, "coordinates"):
            compare(baseline, candidate)

    def test_rejects_renamed_route_with_same_samples(self):
        baseline, candidate = scene(), scene()
        baseline["navigation"]["routes"][0]["name"] = "bridge:0"
        candidate["navigation"]["routes"][0]["name"] = "main:0"
        with self.assertRaisesRegex(ValueError, "names"):
            compare(baseline, candidate)

    def test_rejects_blocked_or_unsupported_route_and_spawn(self):
        cases = [
            (lambda s: s["navigation"]["routes"][0]["samples"][0].update(supported=False), "footing"),
            (lambda s: s["navigation"]["routes"][0]["samples"][0].update(blockers=["Tree"]), "clearance"),
            (lambda s: s["navigation"].update(spawn={"present": False}), "spawn"),
            (lambda s: s["navigation"].update(invalidProxies=["Trunk"]), "proxies"),
        ]
        for mutate, message in cases:
            candidate = scene()
            mutate(candidate)
            with self.subTest(message=message), self.assertRaisesRegex(ValueError, message):
                compare(scene(), candidate)

    def test_rejects_removed_safety_evidence(self):
        baseline, candidate = scene(), scene()
        for item in (baseline, candidate):
            item["navigation"]["routes"][0]["samples"][0].update(supported=True, blockers=[])
            item["navigation"]["spawn"] = {
                "present": True, "anchored": True, "collidable": True,
                "footing": {"supported": True, "blockers": []},
            }
            item["navigation"]["invalidProxies"] = []
        cases = [
            lambda s: s["navigation"]["routes"][0]["samples"][0].pop("supported"),
            lambda s: s["navigation"]["routes"][0]["samples"][0].pop("blockers"),
            lambda s: s["navigation"].pop("spawn"),
            lambda s: s["navigation"]["spawn"].pop("footing"),
            lambda s: s["navigation"]["spawn"]["footing"].pop("supported"),
            lambda s: s["navigation"].pop("invalidProxies"),
        ]
        import copy
        for mutate in cases:
            altered = copy.deepcopy(candidate)
            mutate(altered)
            with self.subTest(mutate=repr(mutate)), self.assertRaisesRegex(ValueError, "missing|Spawn footing or clearance invalid"):
                compare(baseline, altered)

    def test_rejects_malformed_present_safety_evidence(self):
        for field, invalid_values, error in (
            ("spawn", ({}, [], None, {"present": True}), "spawn"),
            ("invalidProxies", (False, {}, "none", 0), "proxies"),
        ):
            for value in invalid_values:
                with self.subTest(field=field, value=value):
                    candidate = scene()
                    candidate["navigation"][field] = value
                    with self.assertRaisesRegex(ValueError, error):
                        compare(scene(), candidate)
        candidate = scene()
        candidate["navigation"]["spawn"] = {
            "present": True, "anchored": True, "collidable": True,
            "footing": {"supported": True, "blockers": None},
        }
        with self.assertRaisesRegex(ValueError, "footing"):
            compare(scene(), candidate)

    def test_rejects_navigation_coverage_mismatch(self):
        candidate = scene()
        candidate["navigation"]["routes"][0]["samples"].pop()
        with self.assertRaisesRegex(ValueError, "coverage"):
            compare(scene(), candidate)


if __name__ == "__main__":
    unittest.main()
