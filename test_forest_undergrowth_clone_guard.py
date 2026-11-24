"""Regressao: falha de clonagem/saneamento do sub-bosque nao aborta integracao."""
from pathlib import Path

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")


def test_undergrowth_clone_is_inside_protected_call():
    start = SOURCE.index("local undergrowthPlaced=0")
    end = SOURCE.index('world:SetAttribute("ForestUndergrowthModels"', start)
    block = SOURCE[start:end]
    assert block.index("local okFoliage=pcall(function()") < block.index("foliage=template:Clone()")
    assert block.index("foliage=template:Clone()") < block.index("foliage:GetDescendants()")
    assert "if okFoliage then undergrowthPlaced+=1 elseif foliage then foliage:Destroy() end" in block
