"""Exercise the local bundle assembler without requiring macOS tools on Linux."""
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "Scripts" / "package-local-app.sh"


class LocalBundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        tools = self.work / "tools"
        tools.mkdir()
        self.bin_dir = self.work / "binary"
        self.bin_dir.mkdir()
        executable = self.bin_dir / "SpeechToTextApp"
        executable.write_text("#!/bin/sh\nexit 0\n")
        executable.chmod(0o755)
        self.output_dir = self.work / "output"
        self.sign_log = self.work / "sign.log"
        for name, code in {
            "swift": """#!/usr/bin/env python3
import os, sys
from pathlib import Path
assert sys.argv[1:3] == ['build', '-c']
if '--show-bin-path' in sys.argv:
    print(os.environ['FAKE_SWIFT_BIN_DIR'])
else:
    assert '--product' in sys.argv and 'SpeechToTextApp' in sys.argv
""",
            "plutil": """#!/usr/bin/env python3
import plistlib, sys
with open(sys.argv[-1], 'rb') as f:
    plist = plistlib.load(f)
if '-extract' in sys.argv:
    print(plist[sys.argv[sys.argv.index('-extract') + 1]])
else:
    assert '-lint' in sys.argv
""",
            "codesign": """#!/usr/bin/env python3
import os, sys
from pathlib import Path
args = sys.argv[1:]
assert Path(args[-1], 'Contents', 'Info.plist').is_file()
if '--sign' in args:
    assert args[args.index('--sign') + 1] == '-'
    assert Path(args[args.index('--entitlements') + 1]).is_file()
    Path(os.environ['SIGN_LOG']).write_text(' '.join(args))
    if os.environ.get('MOCK_SIGN_FAIL'):
        sys.exit(1)
else:
    assert '--verify' in args and '--strict' in args
""",
            "mv": """#!/usr/bin/env python3
import os, subprocess, sys
from pathlib import Path
args = sys.argv[1:]
if (os.environ.get('MOCK_PUBLISH_FAIL')
        and Path(args[-2]).parent.name.startswith('.bundle.')
        and Path(args[-2]).name == 'SpeechToTextApp.app'
        and Path(args[-1]).name == 'SpeechToTextApp.app'):
    sys.exit(1)
sys.exit(subprocess.run(['/bin/mv', *args]).returncode)
""",
        }.items():
            tool = tools / name
            tool.write_text(code)
            tool.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{tools}:{os.environ['PATH']}",
                        FAKE_SWIFT_BIN_DIR=str(self.bin_dir),
                        APP_OUTPUT_DIR=str(self.output_dir), SIGN_LOG=str(self.sign_log))

    def package(self, **env):
        return subprocess.run(["bash", str(SCRIPT)], cwd=ROOT,
                              env={**self.env, **env}, capture_output=True, text=True)

    def test_creates_signed_bundle_with_microphone_usage_description(self):
        result = self.package()
        self.assertEqual(result.returncode, 0, result.stderr)
        app = self.output_dir / "SpeechToTextApp.app"
        executable = app / "Contents/MacOS/SpeechToTextApp"
        self.assertTrue(executable.is_file() and os.access(executable, os.X_OK))
        with (app / "Contents/Info.plist").open("rb") as file:
            plist = plistlib.load(file)
        self.assertEqual(plist["CFBundleIdentifier"], "com.axelahrens.speechtotext")
        self.assertTrue(plist["NSMicrophoneUsageDescription"])
        self.assertIn("--entitlements", self.sign_log.read_text())

    def test_failed_signing_keeps_existing_bundle(self):
        app = self.output_dir / "SpeechToTextApp.app"
        app.mkdir(parents=True)
        (app / "existing").write_text("untouched")
        result = self.package(MOCK_SIGN_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--sign", self.sign_log.read_text())
        self.assertEqual((app / "existing").read_text(), "untouched")

    def test_failed_publication_restores_existing_bundle(self):
        app = self.output_dir / "SpeechToTextApp.app"
        app.mkdir(parents=True)
        (app / "existing").write_text("untouched")
        result = self.package(MOCK_PUBLISH_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((app / "existing").read_text(), "untouched")

    def test_failed_publication_restores_dangling_bundle_symlink(self):
        app = self.output_dir / "SpeechToTextApp.app"
        self.output_dir.mkdir(parents=True)
        app.symlink_to("previous-version.app")
        result = self.package(MOCK_PUBLISH_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(app.is_symlink())
        self.assertEqual(os.readlink(app), "previous-version.app")


if __name__ == "__main__":
    unittest.main()
