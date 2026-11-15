"""Guard the lightweight direct InsertService diagnostic (not client graphics)."""
import unittest
from pathlib import Path
from run_runtime_trees_probe import interpret, success

ROOT=Path(__file__).resolve().parents[2]


class RuntimeTreeProbeTests(unittest.TestCase):
    def test_requires_both_packages_and_selected_tree_names(self):
        good={"taskState":"COMPLETE","result":{"results":[
            {"name":"Synty","loadSucceeded":True,"meshParts":200,"missingNames":[]},
            {"name":"ForestPack","loadSucceeded":True,"meshParts":37,"missingNames":[]}]}}
        self.assertTrue(success(good))
        for bad in (
            {"taskState":"PROCESSING","result":good["result"]},
            {"taskState":"COMPLETE","result":{"results":[good["result"]["results"][0]]}},
            {"taskState":"COMPLETE","result":{"results":[good["result"]["results"][0],
                {"name":"ForestPack","loadSucceeded":False,"meshParts":0,"missingNames":[]}]}},
            {"taskState":"COMPLETE","result":{"results":[good["result"]["results"][0],
                {"name":"ForestPack","loadSucceeded":True,"meshParts":37,"missingNames":["missing"]}]}}
        ):
            self.assertFalse(success(bad))

    def test_parses_only_our_kind(self):
        task={"state":"COMPLETE","output":{"results":[
            {"kind":"random","results":[]},
            {"kind":"dreamcore_runtime_tree_asset_probe","results":[]}]}}
        self.assertEqual(interpret(task)["result"]["kind"],"dreamcore_runtime_tree_asset_probe")

    def test_no_runtime_workspace_mutation(self):
        source=(ROOT/"tools/roblox-qa/probe_runtime_trees.luau").read_text(encoding="utf-8")
        self.assertEqual(source.count("InsertService:LoadAsset("),1)
        self.assertIn("asset:Destroy()",source)
        self.assertNotIn("game:GetService(\"Workspace\")",source)
        self.assertIn("6933438443",source)
        self.assertIn("6432306802",source)


if __name__=="__main__":
    unittest.main()
