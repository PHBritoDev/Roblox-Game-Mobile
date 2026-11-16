"""Validate the performance and safety contract of client-only Dreamcore wildlife."""
from pathlib import Path
import unittest

SOURCE=(Path(__file__).resolve().parents[2]/"src/client/Wildlife.client.luau").read_text(encoding="utf-8")

class WildlifeMobileTests(unittest.TestCase):
    def test_is_local_only_and_bounded(self):
        self.assertIn('RunService.Heartbeat:Connect',SOURCE)
        self.assertIn('local MAX_RABBITS=3',SOURCE)
        self.assertIn('local MAX_BIRDS=3',SOURCE)
        self.assertIn('local UPDATE_INTERVAL=0.05',SOURCE)
        self.assertIn('local MAX_VIEW_DISTANCE=185',SOURCE)
        self.assertNotIn('RemoteEvent',SOURCE)
        self.assertNotIn('InsertService',SOURCE)
        self.assertNotIn('SoundId',SOURCE)

    def test_safe_lifecycle_and_grounding(self):
        for item in ['local habitatCenter=nil',
                     '(focus-habitatCenter).Magnitude>140',
                     'groundAt(x,z)', 'params.IgnoreWater=true',
                     'p.Anchored=true', 'p.CanCollide=false',
                     'p.CanTouch=false', 'p.CanQuery=false',
                     'p.CastShadow=false',
                     'ReplicatedStorage:GetAttribute("ForestState")=="Ready"',
                     'connection:Disconnect()', 'folder:Destroy()']:
            self.assertIn(item,SOURCE)

    def test_animals_are_original_and_moderately_detailed(self):
        for item in ['Coelho do bosque', 'Passaro distante',
                     'Orelha esquerda', 'Orelha direita',
                     'Olho esquerdo', 'Asa esquerda', 'Asa direita']:
            self.assertIn(item,SOURCE)
        self.assertNotIn('require(',SOURCE)
        self.assertNotIn('game:GetObjects(',SOURCE)

if __name__=="__main__":
    unittest.main()
