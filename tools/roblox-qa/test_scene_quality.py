"""Regression tests: physical failures must not be hidden by successful mesh counts."""
import copy
import unittest

from scene_quality import evaluate


def flat_scene():
    routes = []
    for name, offsets in (("main", (-4, 0, 4)), ("bridge", (-3, 0, 3)),
                          ("lake", (-3, 0, 3)), ("river", (-3, 0, 3))):
        for offset in offsets:
            routes.append({"name": f"{name}:{offset}", "samples": [
                {"x": offset, "z": 24-index*2, "y": 0, "normalY": 1,
                 "supported": True, "blockers": []} for index in range(140)]})
    return {"parts": [], "meta": {"partsTotal": 0, "partsExported": 0, "forestModels": 80,
            "forestUndergrowthModels": 60}, "navigation": {
        "routes": routes, "spawn": {"present": True, "anchored": True,
        "collidable": True, "footing": {"supported": True, "blockers": [], "y": 0}},
        "proxyCount": 70, "invalidProxies": [], "activeScripts": []}}


class NavigationRegressionTests(unittest.TestCase):
    def setUp(self):
        self.scene = flat_scene()

    def test_corrupt_geometry_fails_even_with_valid_navigation(self):
        valid = {"n": "Tronco", "p": [0, 1, 2], "s": [2, 3, 4],
                 "c": [0.2, 0.4, 0.6], "rot": [1, 0, 0, 0, 1, 0, 0, 0, 1]}
        cases = (("p", None), ("p", [0, float("nan"), 2]),
                 ("s", [1, 0, 1]), ("s", [1, float("inf"), 1]),
                 ("c", [2, 0, 0]), ("rot", [1, 0, 0]),
                 ("rot", [1, 0, 0, 0, 1, 0, 0, 0, True]))
        for key, bad in cases:
            with self.subTest(key=key, bad=bad):
                scene = flat_scene()
                scene["parts"] = [dict(valid, **{key: bad})]
                scene["meta"].update(partsTotal=1, partsExported=1)
                report = evaluate(scene)
                self.assertFalse(report["pass"])
                self.assertTrue(any("part[0]" in e for e in report["navigationFailures"]))

    def test_rotation_matrix_must_be_proper_cframe(self):
        valid = {"n": "Tronco", "p": [0, 1, 2], "s": [2, 3, 4],
                 "c": [0.2, 0.4, 0.6], "rot": [1, 0, 0, 0, 1, 0, 0, 0, 1]}
        cases = (
            [0] * 9,  # Finite but collapsed matrix
            [2, 0, 0, 0, 1, 0, 0, 0, 1],  # Scale hidden in rotation
            [1, 0, 0, 1, 0, 0, 0, 0, 1],  # Parallel axes
            [-1, 0, 0, 0, 1, 0, 0, 0, 1],  # Reflection
            [1, 0, 0, 0, 1, 0, 0, 0, -1],  # Reflection
        )
        for rot in cases:
            with self.subTest(rot=rot):
                scene = flat_scene()
                scene["parts"] = [dict(valid, rot=rot)]
                scene["meta"].update(partsTotal=1, partsExported=1)
                report = evaluate(scene)
                self.assertFalse(report["pass"])
                self.assertTrue(any("rotation" in e for e in report["navigationFailures"]))
        scene = flat_scene()
        scene["parts"] = [dict(valid, rot=[0, -1, 0, 1, 0, 0, 0, 0, 1])]
        scene["meta"].update(partsTotal=1, partsExported=1)
        self.assertTrue(evaluate(scene)["pass"])

    def test_world_version_malformed_does_not_crash_or_pass(self):
        for version in ("34", True, float("nan"), float("inf"), -1, 33.5, []):
            with self.subTest(version=version):
                scene = flat_scene()
                scene["meta"]["worldVersion"] = version
                report = evaluate(scene)
                self.assertFalse(report["pass"])
                self.assertTrue(any("worldVersion" in e for e in report["navigationFailures"]))

    def test_flat_supported_routes_pass(self):
        self.assertTrue(evaluate(self.scene)["pass"])

    def test_export_metadata_matches_fixture(self):
        self.assertEqual(self.scene["meta"]["partsExported"], len(self.scene["parts"]))
        self.assertTrue(evaluate(self.scene)["pass"])

    def test_hole_fails_even_with_many_premium_meshes(self):
        self.scene["navigation"]["routes"][0]["samples"][20]["supported"] = False
        self.assertFalse(evaluate(self.scene)["pass"])

    def test_obstacle_on_bridge_fails(self):
        self.scene["navigation"]["routes"][3]["samples"][12]["blockers"] = ["Trunk proxy"]
        self.assertFalse(evaluate(self.scene)["pass"])

    def test_discontinuous_approach_fails(self):
        self.scene["navigation"]["routes"][6]["samples"][10]["y"] = 1.5
        self.assertFalse(evaluate(self.scene)["pass"])

    def test_cliff_normal_fails(self):
        self.scene["navigation"]["routes"][0]["samples"][3]["normalY"] = 0.5
        self.assertFalse(evaluate(self.scene)["pass"])

    def test_missing_or_disabled_spawn_fails(self):
        self.scene["navigation"]["spawn"]["collidable"] = False
        self.assertFalse(evaluate(self.scene)["pass"])

    def test_no_navigation_evidence_is_not_success(self):
        self.scene.pop("navigation")
        self.assertFalse(evaluate(self.scene)["pass"])

    def test_invalid_proxy_and_third_party_script_fail(self):
        for field, value in (("invalidProxies", ["tree"]), ("activeScripts", ["script"])):
            with self.subTest(field=field):
                scene = copy.deepcopy(self.scene)
                scene["navigation"][field] = value
                self.assertFalse(evaluate(scene)["pass"])

    def test_asset_fallback_keeps_navigation_separate_from_visual_acceptance(self):
        self.scene["meta"]["forestModels"] = 0
        report = evaluate(self.scene)
        self.assertTrue(report["pass"])
        self.assertTrue(report["assetWarnings"])

    def test_sampling_gap_and_missing_route_fail(self):
        self.scene["navigation"]["routes"].pop()
        self.assertFalse(evaluate(self.scene)["pass"])
        self.scene = flat_scene()
        self.scene["navigation"]["routes"][0]["samples"][20]["z"] -= 8
        self.assertFalse(evaluate(self.scene)["pass"])

    def test_duplicate_route_is_rejected_even_when_all_expected_names_exist(self):
        duplicate = copy.deepcopy(self.scene["navigation"]["routes"][0])
        self.scene["navigation"]["routes"].append(duplicate)
        report = evaluate(self.scene)
        self.assertFalse(report["pass"])
        self.assertTrue(any("Duplicate navigation routes" in e for e in report["navigationFailures"]))

    def test_nan_measurement_is_rejected(self):
        self.scene["navigation"]["routes"][0]["samples"][1]["y"] = float("nan")
        self.assertFalse(evaluate(self.scene)["pass"])


    def test_malformed_snapshot_fails_closed(self):
        cases = [
            None, [], {}, {"parts": None, "meta": {}},
            {"parts": [None], "meta": {"partsTotal": 1, "partsExported": 1}},
            {"parts": [], "meta": {"partsTotal": float("nan"), "partsExported": 0}},
            {"parts": [], "meta": {"partsTotal": 0, "partsExported": True}},
        ]
        for scene in cases:
            with self.subTest(scene=scene):
                report = evaluate(scene)
                self.assertFalse(report["pass"])
                self.assertTrue(report["navigationFailures"])

    def test_malformed_collision_telemetry_fails_closed(self):
        changes = [
            lambda scene: scene["navigation"]["routes"][0]["samples"][0].update(supported=1),
            lambda scene: scene["navigation"]["routes"][0]["samples"][0].update(blockers=""),
            lambda scene: scene["navigation"]["spawn"].update(collidable=1),
            lambda scene: scene["navigation"]["spawn"]["footing"].update(blockers=""),
            lambda scene: scene["navigation"].update(invalidProxies=None),
            lambda scene: scene["navigation"].update(activeScripts=None),
            lambda scene: scene["navigation"].update(proxyCount=float("nan")),
        ]
        for change in changes:
            with self.subTest(change=changes.index(change)):
                scene = flat_scene()
                change(scene)
                self.assertFalse(evaluate(scene)["pass"])

    def test_invalid_asset_diagnostics_fails_closed(self):
        self.scene["assets"] = []
        self.assertFalse(evaluate(self.scene)["pass"])


if __name__ == "__main__":
    unittest.main()
