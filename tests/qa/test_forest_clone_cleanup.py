"""Regressão: clones incompletos não permanecem na floresta."""
from pathlib import Path

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")

def test_tree_placement_failure_destroys_partial_clone():
    section = SOURCE.split("local function plantForest(template,site,index)", 1)[1].split("for i,site in forestTreeSites do", 1)[0]
    assert "local tree=template:Clone()" in section
    assert "local okPlacement,placementError=pcall(function()" in section
    assert "tree.Parent=naturalForest" in section
    assert "if not okPlacement then" in section
    assert "tree:Destroy()" in section
    assert "error(placementError,0)" in section
    assert section.index("tree:Destroy()") > section.index("tree.Parent=naturalForest")
