"""Publication must preserve assets, verify the lightweight build, and remain explicit."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[2]
WORKFLOW=(ROOT/".github/workflows/publicar-recuperacao-v34.yml").read_text(encoding="utf-8")


class RecoveryPublishSafetyTests(unittest.TestCase):
    def test_publish_is_requested_only_for_specific_recovery_file(self):
        self.assertIn("deploy-requests/recuperar-bootstrap-v34.txt",WORKFLOW)
        self.assertIn("branches: [main]",WORKFLOW)
        self.assertIn("BASE_CORRIGIDA=8a129363c1bef16d592ecd36ac82014a482d86f1",WORKFLOW)

    def test_both_builds_and_tests_are_required(self):
        self.assertIn("unittest discover", WORKFLOW)
        self.assertIn("audit_bundled_assets.py", WORKFLOW)
        self.assertIn("rojo build default.project.json", WORKFLOW)
        self.assertIn("rojo build bundled.project.json", WORKFLOW)
        self.assertIn("verify_bootstrap.py",WORKFLOW)

    def test_publishing_uses_only_light_place_and_logs_receipt(self):
        self.assertIn("--data-binary @DreamcoreRecuperacaoV34.rbxlx",WORKFLOW)
        self.assertNotIn("--data-binary @DreamcoreV34IntegralPreservada.rbxlx",WORKFLOW)
        self.assertIn("versionNumber", WORKFLOW)
        self.assertIn("resultado-recuperacao-v34.json",WORKFLOW)


if __name__=="__main__":
    unittest.main()
