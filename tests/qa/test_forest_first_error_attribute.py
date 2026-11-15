from pathlib import Path

SOURCE = Path("src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")
ATTRIBUTE = 'world:SetAttribute("ForestTreeFirstPlacementError"'


def test_forest_first_error_is_initialized_and_reported():
    assert 'world:SetAttribute("ForestTreeFirstPlacementError","")' in SOURCE
    assert SOURCE.count(ATTRIBUTE) >= 6
    assert 'string.sub(firstPlacementError or "",1,400)' in SOURCE
    assert 'string.sub(firstPlacementError or tostring(heroError),1,400)' in SOURCE
    assert 'string.sub(tostring(forestError),1,400)' in SOURCE
    assert 'world:SetAttribute("ForestTreeFirstPlacementError","Forest Pack indisponivel")' in SOURCE
