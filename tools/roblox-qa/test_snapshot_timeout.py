"""Ensure the CI polling limit accounts for Roblox's five-minute Luau task cap."""
import unittest
from pathlib import Path

import snapshot_scene

ROOT = Path(__file__).resolve().parents[2]


class SnapshotTimeoutRegressionTests(unittest.TestCase):
    def test_wait_limit_includes_five_minute_execution(self):
        self.assertGreater(snapshot_scene.TASK_POLL_TIMEOUT_SECONDS, 300)
        self.assertLessEqual(snapshot_scene.TASK_POLL_TIMEOUT_SECONDS, 360)

    def test_failure_diagnostic_is_preserved(self):
        source = (ROOT / "tools/roblox-qa/snapshot_scene.py").read_text(encoding="utf-8")
        self.assertIn('"headless_failure.json"', source)
        self.assertIn('task.get("state") != "COMPLETE"', source)

    def test_workflow_budget_can_cover_three_tasks(self):
        workflow = (ROOT / ".github/workflows/visual-proxy-roblox.yml").read_text(encoding="utf-8")
        self.assertIn("timeout-minutes: 35", workflow)
        self.assertIn("python3 tools/roblox-qa/snapshot_scene.py --integration-failure", workflow)


if __name__ == "__main__":
    unittest.main()
