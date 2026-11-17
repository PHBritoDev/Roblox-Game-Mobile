"""Regression coverage for malformed numeric values in engine navigation snapshots."""
import copy
import unittest

from scene_quality import navigation_failures


def valid_navigation():
    routes = []
    for name, offsets in (
        ("main", (-4, 0, 4)), ("bridge", (-3, 0, 3)),
        ("lake", (-3, 0, 3)), ("river", (-3, 0, 3))
    ):
        for offset in offsets:
            count = 140 if name == "main" else 10
            routes.append({
                "name": f"{name}:{offset}",
                "samples": [
                    {"supported": True, "x": float(i), "y": 0.0,
                     "z": float(offset), "normalY": 1.0, "blockers": []}
                    for i in range(count)
                ]
            })
    return {
        "routes": routes,
        "spawn": {
            "present": True, "anchored": True, "collidable": True,
            "footing": {"supported": True, "blockers": [], "y": 0.0}
        },
        "proxyCount": 1, "invalidProxies": [], "activeScripts": []
    }


class NavigationNumericTests(unittest.TestCase):
    def test_valid_route_passes(self):
        self.assertEqual(navigation_failures(valid_navigation()), [])

    def test_boolean_coordinates_fail_closed(self):
        for field in ("x", "y", "z", "normalY"):
            with self.subTest(field=field):
                scene = valid_navigation()
                scene["routes"][0]["samples"][0][field] = True
                self.assertTrue(any("invalid measurement" in e
                                    for e in navigation_failures(scene)))

    def test_nonfinite_coordinates_fail_closed(self):
        for value in (float("nan"), float("inf"), -float("inf")):
            with self.subTest(value=value):
                scene = valid_navigation()
                scene["routes"][0]["samples"][0]["x"] = value
                self.assertTrue(any("invalid measurement" in e
                                    for e in navigation_failures(scene)))

    def test_impossible_surface_normals_fail(self):
        for value in (-1.01, 1.01):
            with self.subTest(value=value):
                scene = valid_navigation()
                scene["routes"][0]["samples"][0]["normalY"] = value
                self.assertTrue(any("surface normal outside" in e
                                    for e in navigation_failures(scene)))

    def test_invalid_spawn_footing_fail(self):
        for value in (True, float("nan"), float("inf"), "0"):
            with self.subTest(value=value):
                scene = valid_navigation()
                scene["spawn"]["footing"]["y"] = value
                self.assertTrue(any("Spawn missing" in e
                                    for e in navigation_failures(scene)))


if __name__ == "__main__":
    unittest.main()
