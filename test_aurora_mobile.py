"""Guard the optional local aurora against high mobile costs and daylight artifacts."""
from pathlib import Path
import unittest

SRC=(Path(__file__).resolve().parents[2]/"src/client/Aurora.client.luau").read_text(encoding="utf-8")

class AuroraMobileTests(unittest.TestCase):
    def test_bounded_client_only_beams(self):
        for phrase in [
            'local MAX_BANDS=4', 'local UPDATE_INTERVAL=0.15',
            'RunService.Heartbeat:Connect', 'Instance.new("Beam")',
            'beam.FaceCamera=true', 'beam.Segments=28',
            'beam.LightInfluence=0', 'p.CanCollide=false',
            'p.CanTouch=false', 'p.CanQuery=false',
            'p.CastShadow=false', 'connection:Disconnect()',
            'folder:Destroy()']:
            self.assertIn(phrase,SRC)
        for disallowed in ['SoundId','RemoteEvent','InsertService','require(']:
            self.assertNotIn(disallowed,SRC)

    def test_daylight_and_unready_world_are_hidden(self):
        self.assertIn('hour>=20.5',SRC)
        self.assertIn('hour<5.4',SRC)
        self.assertIn('return 0',SRC)
        self.assertIn('ForestState")~="Ready"',SRC)
        self.assertIn('band.beam.Enabled=false',SRC)

    def test_subtle_motion_and_gradient(self):
        self.assertIn('math.sin(clock*0.10+band.phase)',SRC)
        self.assertIn('math.sin(clock*0.14+band.phase)',SRC)
        self.assertIn('NumberSequenceKeypoint.new(0,1)',SRC)
        self.assertIn('NumberSequenceKeypoint.new(1,1)',SRC)
        self.assertIn('local strength=(0.14+',SRC)
        self.assertIn('band.beam.Enabled=true',SRC)

if __name__=="__main__":
    unittest.main()
