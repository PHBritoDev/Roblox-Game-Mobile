"""Audit the shipped, inert library without executing anything from Creator Store."""
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
ALLOWED = {'Folder', 'Model', 'MeshPart', 'SurfaceAppearance'}


def content(properties, name):
    value = properties.find(f"Content[@name='{name}']/url")
    return (value.text or '') if value is not None else ''


def describe(path):
    root = ET.parse(path).getroot()
    items = list(root.iter('Item'))
    assert all(item.get('class') in ALLOWED for item in items), 'Unexpected class/scripts in library'
    library = root.find('Item')
    packages = {}
    for folder in library.findall('Item'):
        name = folder.find("Properties/string[@name='Name']").text
        templates = []
        for template in folder.findall('Item'):
            meshes = []
            for mesh in template.iter('Item'):
                if mesh.get('class') != 'MeshPart':
                    continue
                props = mesh.find('Properties')
                mesh_id = content(props, 'MeshId')
                assert mesh_id.startswith('rbxassetid://'), 'MeshId missing'
                size = props.find("Vector3[@name='size']")
                initial = props.find("Vector3[@name='InitialSize']")
                assert size is not None and initial is not None
                assert all(float(v.text)>0 for v in list(size)+list(initial)), 'Invalid mesh size'
                meshes.append({'id':mesh_id, 'size':[float(size.find(k).text) for k in 'XYZ']})
            assert meshes, 'Empty template'
            templates.append({'name':template.find("Properties/string[@name='Name']").text,
                              'meshes':sorted(meshes,key=lambda m:m['id'])})
        packages[name] = {'assetId':6432306802 if name=='ForestPack' else 6933438443,
                          'templates':templates}
    assert set(packages)=={'ForestPack','Synty'}
    assert all(len(p['templates'])>=12 for p in packages.values())
    return {'packages':packages, 'fileSha256':hashlib.sha256(path.read_bytes()).hexdigest()}


def main():
    actual=describe(ROOT/'assets/ForestLibrary.rbxmx')
    expected=json.loads((ROOT/'assets/forest-manifest.json').read_text())
    assert actual==expected, 'Library differs from pinned manifest'
    print('Bundled library: 24 templates; no third-party code; mesh IDs/sizes/hash verified.')


if __name__=='__main__':
    main()
