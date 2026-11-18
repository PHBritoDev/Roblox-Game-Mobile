#!/usr/bin/env python3
"""Review 3 *synthetic Blender proxy* frames. Never calls them Roblox screenshots.

Deterministic reviewer; checks render health and produces actionable warnings.
It does NOT claim AI aesthetic judgement, mobile FPS, or Studio coverage.
"""
from __future__ import annotations
import json
import math
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageStat, ImageChops

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(os.environ.get("PREVIEW_FOLDER", ROOT / "artifacts/visual-preview"))
NAMES = ("spawn", "approach", "canopy")
FRAMES = [OUT / f"preview_{name}.png" for name in NAMES]
MIN_VARIANCE = 16
MIN_BRIGHTNESS, MAX_BRIGHTNESS = 27, 228
LIMIT_DISTINCT_RGB = 90

report = {"kind": "blender_proxy_visual_review", "robloxScreenshot": False,
          "automatedTechnicalReview": True, "artisticApproval": False,
          "images": [], "errors": [], "warnings": [], "pass": False}
screens = []
for name, path in zip(NAMES, FRAMES):
    if not path.exists():
        report["errors"].append(f"Imagem {name} ausente")
        continue
    try:
        im = Image.open(path).convert("RGB")
    except Exception as exc:
        report["errors"].append(f"Imagem {name} ilegivel: {type(exc).__name__}")
        continue
    small = im.resize((192, 108))
    stat = ImageStat.Stat(small)
    avg = sum(stat.mean) / 3
    spread = sum(stat.stddev) / 3
    colors = len(small.getcolors(192 * 108) or [])
    if avg < MIN_BRIGHTNESS:
        report["errors"].append(f"{name}: render quase escuro; rever camera/exposicao")
    if avg > MAX_BRIGHTNESS:
        report["errors"].append(f"{name}: render estourado; rever iluminacao")
    if spread < MIN_VARIANCE or colors < LIMIT_DISTINCT_RGB:
        report["errors"].append(f"{name}: imagem pouco variada; camera talvez vazia ou cena incompleta")
    gray = small.convert("L")
    edge = gray.filter(ImageFilter.FIND_EDGES)
    edge_score = sum(ImageStat.Stat(edge).mean) / 1
    report["images"].append({"name": name, "resolution": im.size,
                             "brightness": round(avg, 2), "colorVariation": round(spread, 2),
                             "distinctColors": colors, "edgeEnergy": round(edge_score, 2)})
    screens.append((name, im))
if len(screens) == 3:
    # Distinct camera angles should not be identical images.
    for a, b in ((0, 1), (1, 2)):
        im_a = screens[a][1].resize((128, 72))
        im_b = screens[b][1].resize((128, 72))
        delta = ImageStat.Stat(ImageChops.difference(im_a, im_b))
        if sum(delta.mean) / 3 < 4:
            report["errors"].append("Cameras produziram frames quase identicos; revisar viewpoints")

    # Contact sheet + labels for inspection. These are approximate views, not Roblox.
    width, height = screens[0][1].size
    sheet = Image.new("RGB", (width * 3, height + 50), (25, 28, 37))
    draw = ImageDraw.Draw(sheet)
    for index, (name, im) in enumerate(screens):
        sheet.paste(im, (width * index, 50))
        draw.text((width * index + 12, 13), f"BLENDER PROXY / {name.upper()} / NOT ROBLOX", fill="white")
    sheet.save(OUT / "contato_3_angulos.png")

scene_path = OUT / "scene.json"
if not scene_path.is_file():
    report["errors"].append("Snapshot scene.json ausente: proxy sem geometria verificavel")
else:
    try:
        scene = json.loads(scene_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        report["errors"].append(f"Snapshot scene.json ilegivel: {type(exc).__name__}")
        scene = {}
    # Fail closed on malformed snapshot schemas instead of crashing mid-review.
    if not isinstance(scene, dict):
        report["errors"].append("Snapshot scene.json deve ser um objeto JSON")
        scene = {}
    parts = scene.get("parts", [])
    meta = scene.get("meta", {})
    if not isinstance(parts, list) or not all(isinstance(p, dict) for p in parts):
        report["errors"].append("Snapshot parts invalido: esperado lista de objetos")
        parts = []
    if not isinstance(meta, dict):
        report["errors"].append("Snapshot meta invalido: esperado objeto")
        meta = {}
    # Fail closed on malformed transforms rather than crashing at hero-mesh checks.
    def valid_vector(value, length, positive=False):
        return (isinstance(value, list) and len(value) == length
                and all(type(n) in (int, float) and math.isfinite(n)
                        and (not positive or n > 0) for n in value))

    if type(meta.get("partsTotal")) is not int or meta["partsTotal"] < 0:
        report["errors"].append("Snapshot partsTotal invalido")
    for index, item in enumerate(parts):
        if not isinstance(item.get("n"), str) or not all(
            valid_vector(item.get(key), length, positive=(key == "s"))
            for key, length in (("p", 3), ("s", 3), ("c", 3), ("rot", 9))
        ):
            report["errors"].append(f"Parte {index}: transformacao/geometria invalida")
            if index >= 19:
                report["errors"].append("Mais erros de geometria omitidos")
                break
    if not parts or meta.get("partsTotal") != len(parts):
        report["errors"].append("Geometria exportada parcialmente; render nao confiavel")
    by_name = {}
    for item in parts:
        by_name[item.get("n", "")] = by_name.get(item.get("n", ""), 0) + 1
    if by_name.get("Copa em camadas", 0) > 250:
        report["warnings"].append("Copas repetidas: possivel silhueta circular generica. Exige revisao artistica.")
    # The landmark is either an authored fallback core or the licensed Forest Pack
    # hero mesh. Model names are not exported as BaseParts; validate mesh position
    # and scale instead of demanding the old cylinder after the V15 art upgrade.
    hero_z = -281.0
    hero_x = math.sin((-245 + 5) * 0.027) * 10 + math.sin(-245 * 0.059) * 2.5
    hero_mesh = [
        item for item in parts
        if valid_vector(item.get("p"), 3) and valid_vector(item.get("s"), 3)
        and item.get("origin") == "ForestPack"
        and item.get("shape") == "MeshPart"
        and item.get("n") == "Trunk"
        and abs(item.get("p", [0, 0, 0])[0] - hero_x) < 16
        and abs(item.get("p", [0, 0, 0])[2] - hero_z) < 17
        and item.get("s", [0, 0, 0])[1] >= 48
    ]
    has_fallback_core = by_name.get("Cerne antigo", 0) >= 1 or by_name.get("Braco ancestral", 0) >= 5
    report["landmark"] = {
        "forestPackHeroMesh": len(hero_mesh) > 0,
        "authoredFallbackCore": has_fallback_core,
        "verifiedInProxy": len(hero_mesh) > 0 or has_fallback_core,
    }
    if not report["landmark"]["verifiedInProxy"]:
        report["errors"].append("Landmark principal ausente: sem tronco hero mesh ou fallback.")
    if by_name.get("Nenufar de memoria", 0) < 3:
        report["warnings"].append("Lago do Reflexo possivelmente incompleto no snapshot.")
    if by_name.get("Synty — Meshes/Pine_Tree_Pine_Large_01", 0) < 1:
        report["warnings"].append("Mesh Synty nao presente no snapshot; revisar acesso a InsertService.")

report["warnings"].append("Blender reconstrói caixas para MeshParts e usa Terrain proxy; qualidade final requer gameplay real.")
report["warnings"].append("Sem agente Studio MCP conectado: nao avaliar sombra, material, agua, FPS ou audio como Roblox real.")
report["pass"] = len(report["errors"]) == 0
(OUT / "visual_review.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"pass": report["pass"], "errors": report["errors"], "warnings": report["warnings"],
                  "images": report["images"]}, ensure_ascii=False))
if not report["pass"]:
    raise SystemExit("QA visual proxy reprovou render; relatorio e contato no artifact")
