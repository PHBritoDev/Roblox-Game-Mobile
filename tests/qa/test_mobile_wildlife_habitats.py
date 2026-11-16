"""Regression guards for mobile wildlife, water-safe habitats and bounded butterflies."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[2]
WILDLIFE=(ROOT/"src/client/Wildlife.client.luau").read_text(encoding="utf-8")
BUTTERFLIES=(ROOT/"src/client/MeadowButterflies.client.luau").read_text(encoding="utf-8")

def path_x(z):
    import math
    return math.sin((z+5)*.027)*10+math.sin(z*.059)*2.5

def rabbit_safe(x,y,z):
    import math
    if x<-345 or x>345 or z<-485 or z>307 or y<-.35 or y>3: return False
    if -261<=z<=39 and abs(x-path_x(z))<18:return False
    if path_x(-89)-7<=x<=184 and abs(z+89)<18:return False
    if -74<=x<=path_x(-151)+8 and abs(z+151)<16:return False
    if abs(x-(125+math.sin((115-z)/23*.32)*24))<34:return False
    if (x+84)**2+(z+151)**2<31*31:return False
    return True

class WildlifeHabitatTests(unittest.TestCase):
    def test_rabbits_never_walk_underwater_or_on_spawn_path(self):
        for case in [(0,-10,-120),(path_x(-50),0,-50),(130,0,-89),(-84,0,-151),(350,0,0),(0,0,400)]:
            with self.subTest(case=case):self.assertFalse(rabbit_safe(*case))
        self.assertTrue(rabbit_safe(-125,0,-110))
    def test_rabbits_are_checked_before_display(self):
        self.assertIn('not safeRabbitHabitat(x,r.groundY,z)',WILDLIFE)
        self.assertIn('hit.Normal.Y>0.83',WILDLIFE)
        self.assertIn('if not birdsActive(Lighting.ClockTime)',WILDLIFE)
        self.assertIn('bird.Parent=nil',WILDLIFE)
        self.assertIn('rabbit.Parent=nil',WILDLIFE)
    def test_local_butterfly_budget_day_cycle_and_streaming(self):
        for fragment in ('local COUNT=4','local UPDATE_INTERVAL=0.09',
                         'local MAX_DISTANCE=105','local function daylight(hour)',
                         'ReplicatedStorage:GetAttribute("ForestState")~="Ready"',
                         'model.Parent=nil','model.Parent=folder','ray.IgnoreWater=true','wing.Shape=Enum.PartType.Ball',
                         'math.abs(z+89)<18','math.abs(z+151)<16',
                         'local function validGround(x,y,z)','if refresh or b.ground==nil then',
                         'conn:Disconnect()'):
            with self.subTest(fragment=fragment):
                self.assertIn(fragment,BUTTERFLIES)
        self.assertNotIn('InsertService',BUTTERFLIES)
        self.assertNotIn('require(',BUTTERFLIES)
        self.assertNotIn('SoundId',BUTTERFLIES)
    def test_20_part_total(self):
        self.assertEqual(BUTTERFLIES.count('createPart('),6)  # 1 declaration + 5 parts
        self.assertIn('local COUNT=4',BUTTERFLIES)
if __name__=="__main__": unittest.main()
