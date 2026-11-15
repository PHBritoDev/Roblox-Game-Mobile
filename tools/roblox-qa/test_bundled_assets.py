import copy
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from audit_bundled_assets import ROOT, describe
from scene_quality import evaluate
from test_scene_quality import flat_scene
from snapshot_scene import source_with_integration_failure


class BundledAssetTests(unittest.TestCase):
    def test_committed_library_is_inert_and_complete(self):
        result=describe(ROOT/'assets/ForestLibrary.rbxmx')
        self.assertEqual(sum(len(p['templates']) for p in result['packages'].values()),24)

    def test_v33_preserves_all_assets_and_spawns_before_generation(self):
        """No feature loss: the full licensed library stays in the published Place."""
        import json
        project=json.loads((ROOT/'default.project.json').read_text())
        self.assertEqual(project['tree']['ServerStorage']['ForestLibrary']['$path'],
                         'assets/ForestLibrary.rbxmx')
        source=(ROOT/'src/server/DreamcoreWorld.server.luau').read_text()
        self.assertNotIn('allowRemoteAssetsAtStartup=false',source)
        self.assertIn('InsertService:LoadAsset(6933438443)',source)
        self.assertIn('InsertService:LoadAsset(6432306802)',source)
        self.assertIn('local initialSpawn',source)
        self.assertIn('local spawn=initialSpawn',source)
        self.assertLess(source.index('initialSpawn=Workspace:FindFirstChild'),
                        source.index('task.spawn(function()\nlocal generated, generationError'))
        self.assertIn('SetAttribute("ForestVersion",33)',source)

    def test_android_loading_reports_each_server_stage_without_removing_assets(self):
        server=(ROOT/'src/server/DreamcoreWorld.server.luau').read_text()
        client=(ROOT/'src/client/Welcome.client.luau').read_text()
        import re
        stages=set(re.findall(r'stage\("([^"]+)"\)',server))
        hints=set(re.findall(r'^ ([A-Za-z]+)="',client,re.M))
        self.assertFalse(stages-hints, f"Stages missing from Android UI: {stages-hints}")
        self.assertIn('hint.Text=if state=="Generating" then progressHint()',client)
        self.assertIn('local spawn=initialSpawn',server)
        self.assertIn('LoadingForestPack',stages)

    def test_script_or_empty_mesh_is_rejected(self):
        for mutation in ['script','empty_mesh']:
            root=ET.parse(ROOT/'assets/ForestLibrary.rbxmx').getroot()
            if mutation=='script':
                ET.SubElement(root.find('Item'),'Item',{'class':'Script'})
            else:
                mesh=next(x for x in root.iter('Item') if x.get('class')=='MeshPart')
                mesh.find("Properties/Content[@name='MeshId']/url").text=''
            with tempfile.TemporaryDirectory() as d:
                p=Path(d)/'asset.rbxmx';ET.ElementTree(root).write(p)
                with self.assertRaises(AssertionError):describe(p)

    def test_missing_reserved_trees_and_fake_rollback_are_rejected(self):
        scene=flat_scene();scene['meta'].update(worldVersion=33,generationComplete=True)
        scene['assets']={'reserved':10,'fulfilled':10,'foliageBalls':0,'emptyMeshIds':0}
        self.assertTrue(evaluate(scene)['pass'])
        for key,value in [('fulfilled',9),('foliageBalls',1),('emptyMeshIds',1)]:
            broken=copy.deepcopy(scene);broken['assets'][key]=value
            self.assertFalse(evaluate(broken)['pass'])
        scene['meta']['forcedIntegrationFailure']=True
        self.assertFalse(evaluate(scene)['pass'])
        scene['assets'].update(syntyIntegration=False,forestIntegration=False)
        self.assertTrue(evaluate(scene)['pass'])

    def test_fault_injection_after_clone_requires_exact_markers(self):
        src=(ROOT/'src/server/DreamcoreWorld.server.luau').read_text()
        changed=source_with_integration_failure(src)
        self.assertEqual(changed.count('error("QA forced integration failure")'),2)
        with self.assertRaises(ValueError):source_with_integration_failure('')


if __name__=='__main__':unittest.main()
