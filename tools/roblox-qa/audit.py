#!/usr/bin/env python3
"""Roblox map source audit: honest static evidence, never a rendered screenshot."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORLD = ROOT / 'src/server/DreamcoreWorld.server.luau'
PROJECT = ROOT / 'default.project.json'
REPORT = ROOT / 'artifacts/qa/relatorio.json'


def main():
    issues = []
    checks = {}
    if not WORLD.is_file() or not PROJECT.is_file():
        raise SystemExit('Arquivos do protótipo ausentes')
    src = WORLD.read_text(encoding='utf-8')
    project = json.loads(PROJECT.read_text(encoding='utf-8'))
    checks['project_data_model'] = project.get('tree', {}).get('$className') == 'DataModel'
    checks['server_script_present'] = WORLD.exists()
    checks['spawn_location'] = bool(re.search(r'Instance\.new\(["\']SpawnLocation["\']\)', src))
    checks['atmosphere'] = bool(re.search(r'Instance\.new\(["\']Atmosphere["\']\)', src))
    checks['bloom'] = 'BloomEffect' in src
    checks['color_correction'] = 'ColorCorrectionEffect' in src
    checks['terrain'] = 'Workspace.Terrain' in src
    # Imported assets must not retain executable scripts or legacy mobile VFX.
    sanitizer = re.search(r'local function stripImportedEffects\(root\)(.*?)\nend', src, re.S)
    sanitizer_body = sanitizer.group(1) if sanitizer else ''
    required_classes = ('LuaSourceContainer', 'ParticleEmitter', 'Trail', 'Beam',
                        'Fire', 'Smoke', 'Sparkles', 'Light')
    checks['imported_asset_sanitizer'] = (
        bool(sanitizer) and all(f'IsA("{name}")' in sanitizer_body for name in required_classes)
        and 'descendant:Destroy()' in sanitizer_body
    )
    if not checks['imported_asset_sanitizer']:
        issues.append('Sanitizacao de scripts/VFX de assets importados ausente ou incompleta.')
    checks['camera_capture_available'] = False
    checks['actual_roblox_screenshot'] = False
    checks['actual_roblox_video'] = False
    observations = {
        'uses_terrain_clear': 'terrain:Clear()' in src,
        'sunrays_effect': 'SunRaysEffect' in src,
        'dynamic_time_of_day': bool(re.search(r'(TweenService|RunService|while\s+world\.Parent)', src)),
    }
    if observations['uses_terrain_clear']:
        issues.append('Terrain:Clear() apaga o terreno preexistente quando o script roda.')
    if not observations['sunrays_effect']:
        issues.append('SunRaysEffect ainda não foi implementado.')
    if not observations['dynamic_time_of_day']:
        issues.append('Ainda não existe ciclo dia/noite automático verificado no código.')
    issues.append('Nenhuma screenshot ou vídeo real: falta sessão Studio MCP.')
    report = {
        'kind': 'static_source_audit',
        'visual_test_performed': False,
        'roblox_runtime_test_performed': False,
        'file': str(WORLD.relative_to(ROOT)),
        'checks': checks,
        'observations': observations,
        'limitations': issues,
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if not all(checks[k] for k in ('project_data_model', 'server_script_present', 'spawn_location', 'atmosphere', 'terrain', 'imported_asset_sanitizer')):
        raise SystemExit('Falhou requisito estrutural básico')

if __name__ == '__main__':
    main()
