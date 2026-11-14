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
    return {"parts": [], "meta": {"partsTotal": 0, "forestModels": 80,
            "forestUndergrowthModels": 60}, "navigation": {
        "routes": routes, "spawn": {"present": True, "anchored": True,
        "collidable": True, "footing": {"supported": True, "blockers": [], "y": 0}},
        "proxyCount": 70, "invalidProxies": [], "activeScripts": []}}


class NavigationRegressionTests(unittest.TestCase):
    def setUp(self):
        self.scene = flat_scene()

    def test_flat_supported_routes_pass(self):
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

    def test_nan_measurement_is_rejected(self):
        self.scene["navigation"]["routes"][0]["samples"][1]["y"] = float("nan")
        self.assertFalse(evaluate(self.scene)["pass"])


if __name__ == "__main__":
    unittest.main()
