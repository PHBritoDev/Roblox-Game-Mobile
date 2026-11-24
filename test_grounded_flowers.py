"""Terrain-grounding and reserved-corridor guards for authored flowers/fungi."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[2]
SRC=(ROOT/"src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
FLOWERS=SRC.split("-- Somente alguns detalhes de brilho autorais:",1)[1].split("-- Capitulo visual:",1)[0]

class GroundedFlowerTests(unittest.TestCase):
    def test_independent_randomization_and_bounded_plant_count(self):
        self.assertIn("local flowerRng=Random.new(340217)",FLOWERS)
        self.assertIn("for i=1,36 do",FLOWERS)
        self.assertNotIn("rng:",FLOWERS.replace("flowerRng:",""))
    def test_ground_and_access_checks_before_parts(self):
        cast=FLOWERS.index("local hit=Workspace:Raycast")
        first_part=FLOWERS.index('local stem=part("Haste de flor"')
        self.assertLess(cast,first_part)
        for requirement in ("reservedSite(x,z,3)","hit.Material==Enum.Material.Water",
                            "hit.Normal.Y<0.80","hit.Position.Y < -0.45",
                            'world:SetAttribute("GroundedDecorativePlants"',
                            'world:SetAttribute("SkippedDecorativePlantSites"'):
            self.assertIn(requirement,FLOWERS)
        for y in ("soil+0.85","soil+1.72","soil+1.78","soil+0.38",
                  "soil+0.82","soil+0.77","soil+0.22"):
            self.assertIn(y,FLOWERS)
    def test_decorative_parts_have_no_physics(self):
        self.assertIn("optimizeDecorativeMesh(stem,false)",FLOWERS)
        self.assertIn("optimizeDecorativeMesh(petal,false)",FLOWERS)
        self.assertIn("optimizeDecorativeMesh(cap,false)",FLOWERS)

if __name__=="__main__": unittest.main()
