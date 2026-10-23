#!/usr/bin/env python3
"""Launch a signed local macOS app briefly; no microphone or API requests."""
import argparse
import os
from pathlib import Path
import plistlib
import signal
import subprocess
import sys
import time


def smoke(app: Path, seconds: float) -> None:
    if seconds <= 0:
        raise ValueError("seconds must be positive")
    plist_path = app / "Contents/Info.plist"
    with plist_path.open("rb") as source:
        info = plistlib.load(source)
    if (info.get("CFBundleIdentifier") != "com.axelahrens.speechtotext"
            or not info.get("NSMicrophoneUsageDescription")
            or info.get("LSUIElement") is not True):
        raise ValueError("invalid app metadata")
    binary = app / "Contents/MacOS/SpeechToTextApp"
    if not binary.is_file() or not os.access(binary, os.X_OK):
        raise ValueError("app executable missing")

    # Do not pass CI credentials into the child app.
    environment = {key: value for key, value in os.environ.items()
                   if not any(word in key.upper() for word in
                              ("TOKEN", "SECRET", "PASSWORD", "KEY"))}
    process = subprocess.Popen([str(binary)], stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, env=environment,
                               start_new_session=True)
    try:
        try:
            exit_code = process.wait(timeout=seconds)
        except subprocess.TimeoutExpired:
            print(f"launch survived {seconds:g}s (PID {process.pid}); no UI or microphone tested")
        else:
            raise RuntimeError(f"app exited early with code {exit_code}")
    finally:
        # A child can outlive an exited app; terminate the entire isolated group.
        for sig in (signal.SIGTERM, signal.SIGKILL):
            try:
                os.killpg(process.pid, sig)
            except ProcessLookupError:
                pass
            if sig == signal.SIGTERM:
                try:
                    process.wait(timeout=0.3)
                except subprocess.TimeoutExpired:
                    pass
                time.sleep(0.2)
        process.wait(timeout=3)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path,
                        default=Path(__file__).resolve().parents[1]
                        / ".build/local/SpeechToTextApp.app")
    parser.add_argument("--seconds", type=float, default=5)
    args = parser.parse_args()
    try:
        smoke(args.app, args.seconds)
    except (OSError, ValueError, RuntimeError, plistlib.InvalidFileException) as error:
        print(f"launch smoke failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
