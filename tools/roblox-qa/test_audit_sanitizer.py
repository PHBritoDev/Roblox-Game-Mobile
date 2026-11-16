#!/usr/bin/env python3
"""Regression tests for the imported asset sanitizer QA gate."""
import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path

AUDIT_PATH = Path(__file__).with_name("audit.py")
SPEC = importlib.util.spec_from_file_location("roblox_audit", AUDIT_PATH)
audit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audit)

CLASSES = ("LuaSourceContainer", "ParticleEmitter", "Trail", "Beam",
           "Fire", "Smoke", "Sparkles", "Light")


def world_source(classes=CLASSES, destroy=True):
    body = "\n".join('    if descendant:IsA("%s") then' % cls for cls in classes)
    body += "\n    descendant:Destroy()" if destroy else "\n    return"
    return ('Instance.new("SpawnLocation")\nInstance.new("Atmosphere")\n'
            'Workspace.Terrain\nlocal function stripImportedEffects(root)\n'
            + body + '\nend\n')


class SanitizerAuditTests(unittest.TestCase):
    def check(self, source, expected):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            world = root / "world.luau"
            project = root / "default.project.json"
            report = root / "report.json"
            world.write_text(source, encoding="utf-8")
            project.write_text(json.dumps({"tree": {"$className": "DataModel"}}))
            old = (audit.WORLD, audit.PROJECT, audit.REPORT, audit.ROOT)
            try:
                audit.WORLD, audit.PROJECT, audit.REPORT, audit.ROOT = (
                    world, project, report, root)
                with contextlib.redirect_stdout(io.StringIO()):
                    if expected:
                        audit.main()
                    else:
                        with self.assertRaises(SystemExit):
                            audit.main()
                self.assertEqual(
                    json.loads(report.read_text())["checks"]["imported_asset_sanitizer"],
                    expected)
            finally:
                audit.WORLD, audit.PROJECT, audit.REPORT, audit.ROOT = old

    def test_complete_sanitizer_passes(self):
        self.check(world_source(), True)

    def test_missing_class_fails(self):
        self.check(world_source(CLASSES[:-1]), False)

    def test_missing_destroy_fails(self):
        self.check(world_source(destroy=False), False)


if __name__ == "__main__":
    unittest.main()
