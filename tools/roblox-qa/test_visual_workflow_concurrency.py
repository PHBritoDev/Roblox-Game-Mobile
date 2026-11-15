"""Prevent a main merge from cancelling PR visual diagnostics."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class VisualWorkflowConcurrencyTests(unittest.TestCase):
    def test_runs_are_scoped_by_ref_and_not_cancelled(self):
        workflow = (ROOT / ".github/workflows/visual-proxy-roblox.yml").read_text(encoding="utf-8")
        self.assertIn('group: preview-proxy-world1-${{ github.ref }}', workflow)
        self.assertIn('cancel-in-progress: false', workflow)
        self.assertIn('pull_request:', workflow)


if __name__ == "__main__":
    unittest.main()
