"""Regression guard: only static messages in speech/clipboard logging paths.

This is deliberately scoped to these four files, not a whole-app taint analysis.
Any new dynamic log in these paths needs an explicit privacy review.
"""

from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
SENSITIVE_FILES = (
    "API/WhisperAPI.swift",
    "API/APIClient.swift",
    "Services/TranscriptionService.swift",
    "Services/ClipboardService.swift",
)
STATIC_LOG = re.compile(
    r'^Logger\.(?:debug|info|warning|error)\("[^"\\]*", category: Logger\.\w+\)$'
)


def risky_log_lines(source: str):
    risky = []
    for number, line in enumerate(source.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("//"):
            continue
        if "Logger." not in stripped:
            continue
        if not STATIC_LOG.fullmatch(stripped):
            risky.append(number)
    return risky


class PrivacyLogTests(unittest.TestCase):
    def test_dynamic_and_multiline_logs_are_rejected(self):
        examples = (
            'Logger.info("value: \\(text)", category: Logger.api)',
            'Logger.info(text, category: Logger.api)',
            'Logger.error(error, category: Logger.api)',
            'Logger.info(\n "value", category: Logger.api)',
            'Logger.info("escaped \\\\(text)", category: Logger.api)',
        )
        for example in examples:
            with self.subTest(example=example):
                self.assertIn(1, risky_log_lines(example))

    def test_static_logs_and_comments_are_allowed(self):
        source = '// Logger.info(text, category: Logger.api)\nLogger.info("Done", category: Logger.api)'
        self.assertEqual(risky_log_lines(source), [])

    def test_sensitive_paths_have_only_static_log_messages(self):
        offenders = []
        for relative in SENSITIVE_FILES:
            source = ROOT / "Sources" / relative
            for number in risky_log_lines(source.read_text()):
                offenders.append(f"{relative}:{number}")
        self.assertEqual(offenders, [], f"Review dynamic log messages: {offenders}")


if __name__ == "__main__":
    unittest.main()
