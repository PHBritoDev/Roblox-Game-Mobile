"""Guards for Dawn/Evening/Night atmosphere updates on the existing light cycle."""
from pathlib import Path
import re
import unittest

SRC=(Path(__file__).resolve().parents[2]/"src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
class MoodAtmosphereTests(unittest.TestCase):
    def test_each_mood_has_bounded_haze_density_bloom(self):
        profiles=SRC.split("local moods={",1)[1].split("local atmosphere=",1)[0]
        for key,low,high in (("density",0.05,0.25),("haze",0.2,0.85),("bloom",0.08,0.22)):
            vals=[float(v) for v in re.findall(r"\\b"+key+r"=(0\\.\\d+)",profiles)]
            self.assertEqual(len(vals),4,key)
            self.assertTrue(all(low<=v<=high for v in vals),key)
    def test_mood_apply_and_cycle_interpolate_without_extra_instances(self):
        apply=SRC.split("local function applyMood(mood)",1)[1].split("applyMood(moods[1])",1)[0]
        cycle=SRC.split("local clockDelta=(target.clock-start.clock+12)%24-12",1)[1]
        for item in ("atmosphere.Density=mood.density","atmosphere.Haze=mood.haze","bloom.Intensity=mood.bloom"):
            self.assertIn(item,apply)
        for key in ("Density","Haze"):
            self.assertIn("atmosphere."+key+"=start."+key.lower()+"+(target."+key.lower()+"-start."+key.lower()+")*smooth",cycle)
        self.assertIn("bloom.Intensity=start.bloom+(target.bloom-start.bloom)*smooth",cycle)
        self.assertIn("task.wait(0.5)",cycle)
    def test_no_new_climate_vfx_or_external_asset(self):
        self.assertEqual(SRC.count('local bloom=Lighting:FindFirstChild("DreamcoreBloom")'),1)
        self.assertEqual(SRC.count('local atmosphere=Lighting:FindFirstChildOfClass("Atmosphere")'),1)

if __name__=="__main__": unittest.main()
