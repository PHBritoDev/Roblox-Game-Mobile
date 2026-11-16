#!/usr/bin/env python3
"""Regression tests for malformed Blender proxy snapshots (not Roblox renders)."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image

REVIEWER = Path(__file__).with_name("review_visual.py")


class SnapshotSchemaTests(unittest.TestCase):
    def test_malformed_snapshot_fails_closed(self):
        for label, snapshot, expected in (
            ("root_list", [], "deve ser um objeto JSON"),
            ("parts_object", {"parts": {}, "meta": {}}, "Snapshot parts invalido"),
            ("parts_scalars", {"parts": [None, 2], "meta": {}}, "Snapshot parts invalido"),
            ("meta_list", {"parts": [{"n": "Cerne antigo"}], "meta": []}, "Snapshot meta invalido"),
        ):
            with self.subTest(label=label), tempfile.TemporaryDirectory() as folder:
                out = Path(folder)
                # Distinct non-empty proxy frames avoid unrelated image-health failures.
                for index, name in enumerate(("spawn", "approach", "canopy")):
                    image = Image.new("RGB", (192, 108))
                    pixels = image.load()
                    for y in range(108):
                        for x in range(192):
                            pixels[x, y] = ((x * (index + 3) + y) % 256,
                                            (y * (index + 5) + x) % 256,
                                            (x + y * (index + 7)) % 256)
                    image.save(out / f"preview_{name}.png")
                (out / "scene.json").write_text(json.dumps(snapshot), encoding="utf-8")
                env = dict(os.environ, PREVIEW_FOLDER=str(out))
                proc = subprocess.run([sys.executable, str(REVIEWER)], env=env,
                                      capture_output=True, text=True)
                self.assertNotEqual(proc.returncode, 0)
                report = json.loads((out / "visual_review.json").read_text(encoding="utf-8"))
                self.assertFalse(report["pass"])
                self.assertTrue(any(expected in error for error in report["errors"]), report["errors"])


if __name__ == "__main__":
    unittest.main()
