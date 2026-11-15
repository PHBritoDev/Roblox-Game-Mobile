"""Guard against silent failures when licensed Forest Pack trees are planted."""
from pathlib import Path
import unittest

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")

class ForestPlacementDiagnostics(unittest.TestCase):
    def test_tree_failures_have_observable_telemetry(self):
        self.assertIn('world:SetAttribute("ForestTreePlacementFailures",placementFailures)', SOURCE)
        self.assertIn('local ok,err=pcall(plantForest,template,site,i)', SOURCE)
        self.assertIn('if not firstPlacementError then firstPlacementError=tostring(err) end', SOURCE)
        self.assertIn('warn("[Dreamcore] Falhas no plantio Forest Pack:"', SOURCE)
    def test_failed_sites_keep_original_fallback(self):
        self.assertIn('site.completed=false\n    placementFailures+=1', SOURCE)
        self.assertIn('if not site.completed then branchTree(site.x,site.z,site.s,props) end', SOURCE)

if __name__ == "__main__":
    unittest.main()
