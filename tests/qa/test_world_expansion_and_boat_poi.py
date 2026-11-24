"""Guards for V35 world expansion POIs, sunset rowboat landmark, bootstrap safety floor and ambient wind."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORLD = (ROOT / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
WIND = (ROOT / "src/client/AmbientWindAndSound.client.luau").read_text(encoding="utf-8")


class WorldExpansionV35Tests(unittest.TestCase):
    def test_bootstrap_safety_floor_exists_before_async_generation(self):
        self.assertIn('bootstrapSafetyFloor.Name="PisoSegurancaBootstrap"', WORLD)
        self.assertLess(
            WORLD.index('bootstrapSafetyFloor.Name="PisoSegurancaBootstrap"'),
            WORLD.index('task.spawn(function()\nlocal generated, generationError'),
        )

    def test_sunset_rowboat_landmark_and_expanded_pois_are_non_colliding(self):
        self.assertIn('boatModel.Name="Barco de Madeira nas Margens"', WORLD)
        self.assertIn('world:SetAttribute("RowboatLandmarkPresent",true)', WORLD)
        self.assertIn('Mirante das Estrelas — Santuario Noroeste', WORLD)
        self.assertIn('Clareira do Orvalho Dourado — Bosque Leste', WORLD)
        self.assertIn('world:SetAttribute("ExpandedPOICount",3)', WORLD)
        self.assertIn('world:SetAttribute("TrailSteppingStones",steppingStones)', WORLD)

    def test_ambient_wind_is_bounded_and_client_only(self):
        self.assertIn('local UPDATE_INTERVAL=0.125', WIND)
        self.assertIn('local MAX_SWAY_PARTS=28', WIND)
        self.assertIn('AmbientSoundProfile', WIND)
        self.assertIn('NightCricketsActive', WIND)
        self.assertNotIn('InsertService', WIND)
        self.assertNotIn('RemoteEvent', WIND)


if __name__ == "__main__":
    unittest.main()
