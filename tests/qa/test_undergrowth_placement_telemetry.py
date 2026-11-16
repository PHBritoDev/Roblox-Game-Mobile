"""Regression guard for observable undergrowth placement failures."""
from pathlib import Path

SOURCE = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")


def test_undergrowth_failures_are_reported_and_cleaned():
    assert 'local okFoliage,foliageError=pcall(function()' in SOURCE
    assert 'undergrowthFailures+=1' in SOURCE
    assert 'firstUndergrowthError=tostring(foliageError)' in SOURCE
    assert 'if foliage then foliage:Destroy() end' in SOURCE
    assert 'world:SetAttribute("ForestUndergrowthPlacementFailures",undergrowthFailures)' in SOURCE
    assert 'world:SetAttribute("ForestUndergrowthFirstPlacementError",string.sub(firstUndergrowthError or "",1,400))' in SOURCE
    assert 'warn("[Dreamcore] Falhas no plantio do estrato baixo:"' in SOURCE
