"""Imported foliage must not bring expensive or untrusted VFX into mobile scenes."""
from pathlib import Path

source = (Path(__file__).resolve().parents[2] / "src/server/DreamcoreWorld.server.luau").read_text(encoding="utf-8")


def test_tree_and_shrub_sanitize_imported_effects():
    expected = ('item:IsA("LuaSourceContainer") or item:IsA("ParticleEmitter") '
                'or item:IsA("Trail") or item:IsA("Beam") or item:IsA("Fire") '
                'or item:IsA("Smoke") or item:IsA("Sparkles") or item:IsA("Light")')
    assert source.count(expected) == 2
    assert source.count('optimizeDecorativeMesh(item,') >= 2
