"""Exercise the native HTTP contract in a disposable directory, without provider calls."""
import tempfile
import threading
import unittest
import urllib.error
import urllib.parse
import urllib.request
import json
import io
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch
import server

class NativeAPI(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        settings = patch.multiple(server, DATA_DIR=str(root), DB_PATH=str(root/'test.db'), MIMO_API_KEY='test-only')
        settings.start()
        self.addCleanup(settings.stop)
        server.init_db()
        self.http = server.ThreadingHTTPServer(('127.0.0.1', 0), server.Handler)
        self.addCleanup(self.http.server_close)
        thread = threading.Thread(target=self.http.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(self.http.shutdown)
        self.root = 'http://127.0.0.1:' + str(self.http.server_port)

    def test_location_query_stays_out_of_logs(self):
        with patch.object(server.Handler, "client_ip", return_value="local"):
            handler = object.__new__(server.Handler)
            handler.path = "/api/geo?lat=12.345&lng=67.890"
            captured = io.StringIO()
            with redirect_stdout(captured):
                handler.log_message("%s", "GET "+handler.path+" HTTP/1.1")
            self.assertNotIn("12.345", captured.getvalue())
            self.assertNotIn("67.890", handler._safe_path())

    def test_health(self):
        with urllib.request.urlopen(self.root+'/api/health') as response:
            self.assertTrue(json.load(response)['ok'])

    def test_voice_success_and_failure(self):
        url = self.root+'/api/tts?'+urllib.parse.urlencode({'text':'测试','voice':'冰糖'})
        with patch.object(server, 'synth', return_value=b'RIFF-mock-wave') as synth:
            with urllib.request.urlopen(url) as response:
                self.assertEqual(response.headers.get_content_type(), 'audio/wav')
                self.assertEqual(response.read(), b'RIFF-mock-wave')
            synth.assert_called_once_with('测试','冰糖')
        with patch.object(server, 'synth', side_effect=RuntimeError), self.assertRaises(urllib.error.HTTPError) as error:
            urllib.request.urlopen(self.root+'/api/tts?'+urllib.parse.urlencode({'text':'另一句','voice':'苏打'}))
        self.assertEqual(error.exception.code,502)
