import importlib.util
from pathlib import Path
import unittest

module_path = Path(__file__).resolve().parents[1] / "ai_runner.py"
spec = importlib.util.spec_from_file_location("ai_runner", module_path)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RunnerTests(unittest.TestCase):
    def test_allowed_files(self):
        self.assertTrue(runner.validate_path("src/Combat/DamageService.luau"))
        self.assertTrue(runner.validate_path("docs/STUDIO_AUDIT.md"))
        self.assertTrue(runner.validate_path("README.md"))

    def test_forbidden_files(self):
        for path in (".env", ".github/workflows/release.yml", "tools/ai_runner.py", "src/.env", "../../secret", "src/api_key.txt", "tests/id_rsa", "/tmp/x"):
            self.assertFalse(runner.validate_path(path), path)

    def test_parse_review(self):
        response = runner.parse_review('{"decision":"CHANGES_REQUESTED","feedback":"Fix server validation"}')
        self.assertEqual(response["decision"], "CHANGES_REQUESTED")
        with self.assertRaises(RuntimeError):
            runner.parse_review("review passed")
        with self.assertRaises(RuntimeError):
            runner.parse_review('{"decision":"APPROVE","feedback":"none"}')


if __name__ == "__main__":
    unittest.main()
