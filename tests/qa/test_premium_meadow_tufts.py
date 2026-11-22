"""Outer-meadow premium plants are licensed, bounded, grounded and optional."""
from pathlib import Path
import unittest
SRC=(Path(__file__).resolve().parents[2]/"src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
MEADOW=SRC.split("local meadowPremiumTufts=0",1)[1].split('world:SetAttribute("ForestMeadowPremiumTufts",meadowPremiumTufts)',1)[0]

class PremiumMeadowTests(unittest.TestCase):
    def test_bounded_cost_and_existing_pack_only(self):
        self.assertIn("for i=1,24 do",MEADOW)
        self.assertIn("if i%6==0 then task.wait() end",MEADOW)
        self.assertIn("#undergrowthTemplates>0",MEADOW)
        self.assertIn("foliage=template:Clone()",MEADOW)
        self.assertNotIn("LoadAsset(",MEADOW)
        self.assertNotIn("require(",MEADOW)

    def test_safe_positions_and_no_physics(self):
        for marker in ("not reservedSite(x,z,11)","math.abs(x-riverX(z))>36",
                       "hit.Material~=Enum.Material.Water","hit.Normal.Y>0.8",
                       "hit.Position.Y>=-0.45","optimizeDecorativeMesh(item,false)",
                       "foliage.Parent=naturalForest"):
            self.assertIn(marker,MEADOW)
        self.assertIn("if foliage then foliage:Destroy() end",MEADOW)

    def test_fallback_remains_optional_and_clean(self):
        self.assertIn('world:SetAttribute("ForestMeadowPremiumTufts",0)',SRC)
        self.assertIn('world:SetAttribute("ForestMeadowPremiumTufts",meadowPremiumTufts)',SRC)
        self.assertIn("undergrowthPlaced+=1",MEADOW)
        self.assertIn("undergrowthFailures+=1",MEADOW)

if __name__=="__main__":unittest.main()
