"""V34 undergrowth telemetry: success, missing templates, load failure and rollback."""
import copy
import unittest
from pathlib import Path

from scene_quality import evaluate
from test_scene_quality import flat_scene

ROOT=Path(__file__).resolve().parents[2]
SRC=(ROOT/"src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
EXPORT=(ROOT/"tools/roblox-qa/export_scene.luau").read_text(encoding="utf-8")

def scene_for(status, failures, error, *, forced_asset=False, forced_integration=False):
    scene=flat_scene()
    scene["meta"].update(worldVersion=34,generationComplete=True,
                         forcedAssetFailure=forced_asset,
                         forcedIntegrationFailure=forced_integration)
    scene["assets"]={
        "reserved":10,"fulfilled":10,"foliageBalls":0,"emptyMeshIds":0,
        "syntyIntegration":not forced_integration,
        "forestIntegration":not forced_integration,
        "undergrowthStatus":status,"undergrowthFailures":failures,
        "undergrowthFirstError":error,
    }
    return scene

class UndergrowthTelemetryTests(unittest.TestCase):
    def test_headless_snapshot_exports_all_diagnostic_fields(self):
        for name in ("ForestUndergrowthLoadStatus",
                     "ForestUndergrowthPlacementFailures",
                     "ForestUndergrowthFirstPlacementError"):
            self.assertIn('world:GetAttribute("'+name+'")', EXPORT)

    def test_diagnostics_initialized_outside_asset_success(self):
        start=SRC.index('world:SetAttribute("ForestUndergrowthLoadStatus","Pending")')
        guard=SRC.index('local forestIntegrated,forestError=xpcall(function()')
        self.assertLess(start,guard)
        self.assertIn('world:SetAttribute("ForestUndergrowthPlacementFailures",84)',SRC)
        self.assertIn('world:SetAttribute("ForestUndergrowthLoadStatus","Unavailable")',SRC)
        self.assertIn('world:SetAttribute("ForestUndergrowthLoadStatus","IntegrationFailed")',SRC)
        self.assertIn('world:SetAttribute("ForestUndergrowthModels",0)',SRC)
        self.assertIn('if #undergrowthTemplates==0 then',SRC)

    def test_valid_success_and_explicit_degraded_states(self):
        cases=[
            ("Placed",0,"",False,False),
            ("Partial",2,"clone failed",False,False),
            ("NoTemplates",84,"missing species",False,False),
            ("Unavailable",84,"asset unavailable",True,False),
            ("IntegrationFailed",84,"rollback",False,True),
        ]
        for status,count,reason,asset,integration in cases:
            with self.subTest(status=status):
                scene=scene_for(status,count,reason,forced_asset=asset,forced_integration=integration)
                self.assertTrue(evaluate(scene)["pass"],evaluate(scene)["navigationFailures"])

    def test_missing_or_falsified_telemetry_fails_closed(self):
        good=scene_for("Placed",0,"")
        mutations=[
            ("undergrowthStatus",None),("undergrowthStatus","Pending"),
            ("undergrowthFailures",None),("undergrowthFailures",True),
            ("undergrowthFailures",-1),("undergrowthFirstError",None),
        ]
        for key,value in mutations:
            scene=copy.deepcopy(good)
            scene["assets"][key]=value
            with self.subTest(key=key,value=value):
                self.assertFalse(evaluate(scene)["pass"])
        for bad in [("Unavailable",0,"error"),("Partial",2,""),
                    ("Placed",1,"oops")]:
            with self.subTest(bad=bad):
                self.assertFalse(evaluate(scene_for(*bad))["pass"])

    def test_forced_fallback_cannot_report_success(self):
        self.assertFalse(evaluate(scene_for("Placed",0,"",forced_asset=True))["pass"])
        self.assertFalse(evaluate(scene_for("Partial",1,"error",forced_integration=True))["pass"])

if __name__=="__main__":
    unittest.main()
