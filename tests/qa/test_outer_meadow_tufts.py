"""Expanded meadow shrubs must stay licensed, grounded and mobile-friendly."""
from pathlib import Path
import unittest

SRC=(Path(__file__).resolve().parents[2]/"src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")

class MeadowExpansionTests(unittest.TestCase):
    def test_extra_plants_use_inspected_forest_pack(self):
        self.assertIn('local meadowTufts=0',SRC)
        self.assertIn('for i=1,42 do',SRC)
        self.assertIn('undergrowthTemplates[((i*5-1)%#undergrowthTemplates)+1]',SRC)
        self.assertIn('foliage=template:Clone()',SRC)
        self.assertIn('world:SetAttribute("ForestMeadowPremiumTufts",meadowTufts)',SRC)

    def test_mobile_and_collision_guardrails(self):
        section=SRC.split('local meadowTufts=0',1)[1].split('world:SetAttribute("ForestMeadowPremiumTufts",meadowTufts)',1)[0]
        for fragment in ('not reservedSite(x,z,12)', 'math.abs(x-riverX(z))>35',
                         'optimizeDecorativeMesh(item,false)', 'terrainHeightAt(x,z)',
                         'foliage.Parent=naturalForest', 'if i%6==0 then task.wait() end',
                         'foliage:Destroy()', 'undergrowthFailures+=1'):
            self.assertIn(fragment,section)

    def test_no_unlicensed_external_require(self):
        self.assertNotIn('require(',SRC)

if __name__=="__main__":
    unittest.main()
