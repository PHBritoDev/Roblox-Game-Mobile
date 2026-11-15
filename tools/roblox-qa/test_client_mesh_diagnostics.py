"""Static regression tests for the client-only mesh load diagnostic."""
from pathlib import Path
import re
import unittest

SOURCE = (Path(__file__).resolve().parents[2] / "src/client/Welcome.client.luau").read_text(encoding="utf-8")


class MobileMeshDiagnosticsTests(unittest.TestCase):
    def test_scan_cooperatively_yields(self):
        snippet = SOURCE.split("for index,item in generated:GetDescendants() do", 1)[1].split("end\n  end\n  player:SetAttribute", 1)[0]
        self.assertIn("if index%256==0 then task.wait() end", snippet)

    def test_limits_nearby_unique_meshes(self):
        self.assertIn("local maxSample=64", SOURCE)
        self.assertIn("#ids>=maxSample", SOURCE)
        self.assertIn("(item.Position-origin).Magnitude<=160", SOURCE)

    def test_sampling_remains_async(self):
        self.assertRegex(SOURCE, r"task\.spawn\(function\(\)\s*-- Streaming")


if __name__ == "__main__":
    unittest.main()
