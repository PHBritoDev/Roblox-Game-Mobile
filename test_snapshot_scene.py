"""Failure injection and retry safety tests; no external calls or credentials."""
import io
import urllib.error
import unittest
from unittest.mock import patch

from snapshot_scene import request, source_without_assets


def http_error(code):
    return urllib.error.HTTPError("https://example.invalid", code, "error", {}, io.BytesIO(b"temporary problem"))


class SnapshotSafetyTests(unittest.TestCase):
    def test_asset_injection_changes_only_two_audited_calls(self):
        source = ('local a=pcall(function()\nreturn InsertService:LoadAsset(6933438443)\nend)\n'
                  'local b=pcall(function()\nreturn InsertService:LoadAsset(6432306802)\nend)')
        changed = source_without_assets(source)
        self.assertEqual(changed.count('error("QA forced asset failure")'), 2)
        self.assertEqual(changed.count("pcall(function()"), 2)
        self.assertNotEqual(changed, source)
        self.assertIn("LoadAsset(6432306802)", source)

    def test_missing_or_duplicate_audited_call_is_rejected(self):
        for source in ("", "return InsertService:LoadAsset(6933438443)\n"*2):
            with self.assertRaises(ValueError):
                source_without_assets(source)

    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_get_retries_transient_http(self, urlopen, sleep):
        urlopen.side_effect = [http_error(503), io.BytesIO(b'{"state":"COMPLETE"}')]
        self.assertEqual(request("tasks/1", "test-key"), {"state": "COMPLETE"})
        self.assertEqual(urlopen.call_count, 2)
        sleep.assert_called_once()

    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_post_never_retries(self, urlopen, sleep):
        urlopen.side_effect = http_error(503)
        with self.assertRaises(SystemExit):
            request("tasks", "test-key", {"script": "return true"})
        self.assertEqual(urlopen.call_count, 1)
        sleep.assert_not_called()

    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_get_stops_after_three_attempts(self, urlopen, sleep):
        urlopen.side_effect = [http_error(429), http_error(502), http_error(504)]
        with self.assertRaises(SystemExit):
            request("tasks/1", "test-key")
        self.assertEqual(urlopen.call_count, 3)
        self.assertEqual(sleep.call_count, 2)

    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_get_does_not_retry_permission_or_missing_resource(self, urlopen, sleep):
        for status in (401, 403, 404, 500):
            with self.subTest(status=status):
                urlopen.reset_mock()
                urlopen.side_effect = http_error(status)
                with self.assertRaises(SystemExit):
                    request("tasks/1", "test-key")
                self.assertEqual(urlopen.call_count, 1)
        sleep.assert_not_called()


if __name__ == "__main__":
    unittest.main()
