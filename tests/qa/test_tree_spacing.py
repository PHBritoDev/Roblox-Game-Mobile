"""Regression guards for deterministic tree-site relocation on mobile world generation."""
from pathlib import Path
import unittest

SRC=(Path(__file__).resolve().parents[2]/"src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
SITES=SRC.split("local meshTreeSites={}",1)[1].split("-- Paisagem ribeirinha",1)[0]

class TreeSpacingTests(unittest.TestCase):
    def test_rejects_corridor_after_relocation(self):
        self.assertIn("or reservedSite(x,z,5)",SITES)
        self.assertIn("if isTreeSiteClear(nx,nz,s) then",SITES)
        self.assertIn("recordTreeSite(meshTreeSites,x,z,s)",SITES)
        self.assertIn("recordTreeSite(forestTreeSites,x,z,s)",SITES)

    def test_conservative_bounded_search_and_no_new_heartbeat(self):
        self.assertIn("for ring=1,2 do",SITES)
        self.assertIn("for sample=1,8 do",SITES)
        self.assertIn("local radius=ring*11",SITES)
        self.assertIn("local clearance=math.max(10,6*(s+other.s))",SITES)
        self.assertNotIn("task.spawn(",SITES)
        self.assertNotIn("Heartbeat",SITES.replace("-- Custos ficam na geracao, nunca no Heartbeat do celular.",""))

    def test_tracks_rejected_and_relocated_sites(self):
        self.assertIn('world:SetAttribute("RelocatedProceduralTreeSites"',SITES)
        self.assertIn('world:SetAttribute("RejectedProceduralTreeSites"',SITES)
        self.assertIn("treeSitesRejected+=1",SITES)
        self.assertIn("treeSitesRelocated+=1",SITES)

if __name__=="__main__":unittest.main()
