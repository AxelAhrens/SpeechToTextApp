"""Narrow source guard for audio cleanup ownership (not a runtime test)."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1] / "Sources"


class AudioCleanupWiringTests(unittest.TestCase):
    def test_recorder_discards_file_on_automatic_stop(self):
        recorder = (ROOT / "Audio/AudioRecorder.swift").read_text()
        timer = recorder.split("private func startTimer()", 1)[1].split(
            "private func requestMicrophonePermission", 1
        )[0]
        self.assertIn("AudioProcessor.cleanupAudioFile", timer)

    def test_whisper_does_not_race_workflow_cleanup(self):
        whisper = (ROOT / "API/WhisperAPI.swift").read_text()
        self.assertNotIn("cleanupAudioFile", whisper)

    def test_failed_recorder_callbacks_discard_only_own_file(self):
        recorder = (ROOT / "Audio/AudioRecorder.swift").read_text()
        callbacks = recorder.split("extension AudioRecorder: AVAudioRecorderDelegate", 1)[1].split(
            "extension AudioRecorder {", 1
        )[0]
        self.assertEqual(callbacks.count("guard audioRecorder === recorder else { return }"), 2)
        self.assertEqual(callbacks.count("AudioProcessor.cleanupAudioFile(recorder.url)"), 2)

    def test_pending_microphone_permission_cannot_replace_recorder(self):
        recorder = (ROOT / "Audio/AudioRecorder.swift").read_text()
        start = recorder.split("func startRecording()", 1)[1].split("func stopRecording()", 1)[0]
        self.assertIn("guard !isRecording, pendingStartID == nil", start)
        self.assertIn("guard let self, self.pendingStartID == requestID else { return }", start)


if __name__ == "__main__":
    unittest.main()
