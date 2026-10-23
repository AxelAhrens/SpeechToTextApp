"""Contract tests for launching a packaged app without microphones or API keys."""
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SMOKE = ROOT / "Scripts" / "smoke-test-local-app.py"


class AppLaunchSmokeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.app = Path(self.temp.name) / "SpeechToTextApp.app"
        macos = self.app / "Contents/MacOS"
        macos.mkdir(parents=True)
        with (self.app / "Contents/Info.plist").open("wb") as out:
            plistlib.dump({
                "CFBundleIdentifier": "com.axelahrens.speechtotext",
                "NSMicrophoneUsageDescription": "Microphone access for transcription",
                "LSUIElement": True,
            }, out)
        self.binary = macos / "SpeechToTextApp"

    def run_smoke(self):
        return subprocess.run([sys.executable, str(SMOKE), "--app", str(self.app),
                               "--seconds", "0.3"], capture_output=True, text=True,
                              timeout=10, env={**os.environ, "TEST_MARKER": self.temp.name})

    def test_reports_launch_when_app_stays_alive(self):
        self.binary.write_text("#!/bin/sh\nsleep 10\n")
        self.binary.chmod(0o755)
        result = self.run_smoke()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("launch survived", result.stdout)

    def test_rejects_app_exiting_immediately(self):
        self.binary.write_text("#!/bin/sh\nexit 7\n")
        self.binary.chmod(0o755)
        result = self.run_smoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("exited early", result.stderr)

    def test_kills_descendant_that_ignores_termination(self):
        self.binary.write_text(
            "#!/bin/sh\n"
            "sh -c 'trap \"\" TERM; exec sleep 30' &\n"
            "echo $! > \"$TEST_MARKER/child.pid\"\n"
            "sleep 10\n"
        )
        self.binary.chmod(0o755)
        result = self.run_smoke()
        child_pid = int((Path(self.temp.name) / "child.pid").read_text())
        try:
            state = subprocess.run(["ps", "-p", str(child_pid), "-o", "stat="],
                                   capture_output=True, text=True).stdout.strip()
            self.assertTrue(not state or state.startswith("Z"),
                            f"descendant still alive in state {state}: {result.stderr}")
        finally:
            try:
                os.kill(child_pid, 9)
            except ProcessLookupError:
                pass


if __name__ == "__main__":
    unittest.main()
