"""Offline API rate-limit tests; no network calls, no credentials."""
import io
import unittest
import urllib.error
from unittest.mock import patch

from snapshot_scene import request

def error(status, retry_after=None, body=b'{"message":"test"}'):
    headers={} if retry_after is None else {"Retry-After":retry_after}
    return urllib.error.HTTPError("https://apis.roblox.com/",status,"test",headers,io.BytesIO(body))

def success():
    return io.BytesIO(b'{"path":"example/task"}')

class OpenCloudRetryTests(unittest.TestCase):
    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_post_429_respects_retry_after(self,open_url,sleep):
        open_url.side_effect=[error(429,"7"), success()]
        result=request("tasks","FAKE_API_KEY",{"script":"print('hi')"})
        self.assertEqual(result["path"],"example/task")
        self.assertEqual(open_url.call_count,2)
        sleep.assert_called_once_with(7.0)

    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_post_429_without_header_is_bounded_exponential(self,open_url,sleep):
        open_url.side_effect=[error(429),error(429),error(429),success()]
        self.assertEqual(request("tasks","FAKE_API_KEY",{"script":"test"})["path"],"example/task")
        self.assertEqual([call.args[0] for call in sleep.call_args_list],[10,20,40])

    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_post_other_http_error_never_retries(self,open_url,sleep):
        for status in (400,401,403,502,503,504):
            with self.subTest(status=status):
                open_url.reset_mock()
                open_url.side_effect=error(status)
                with self.assertRaises(SystemExit):
                    request("tasks","FAKE_API_KEY",{"script":"test"})
                self.assertEqual(open_url.call_count,1)
        sleep.assert_not_called()

    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_get_retries_transient_errors(self,open_url,sleep):
        open_url.side_effect=[error(502),success()]
        self.assertEqual(request("some/task","FAKE_API_KEY")["path"],"example/task")
        self.assertEqual(open_url.call_count,2)
        sleep.assert_called_once_with(2.0)

    @patch("snapshot_scene.time.sleep")
    @patch("snapshot_scene.urllib.request.urlopen")
    def test_invalid_retry_header_falls_back_and_key_is_redacted(self,open_url,sleep):
        open_url.side_effect=[error(429,"nan"),success()]
        self.assertEqual(request("tasks","FAKE_API_KEY",{"script":"test"})["path"],"example/task")
        sleep.assert_called_once_with(10)
        open_url.reset_mock()
        open_url.side_effect=error(400,body=b'{"error":"FAKE_API_KEY"}')
        with self.assertRaises(SystemExit) as caught:
            request("tasks","FAKE_API_KEY",{"script":"test"})
        self.assertNotIn("FAKE_API_KEY",str(caught.exception))
        self.assertIn("[REDACTED]",str(caught.exception))

if __name__=="__main__":unittest.main()
