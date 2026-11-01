"""Make AAC listening previews for a saved study revision (macOS afconvert)."""
import json
import shutil
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
revision = sys.argv[1] if len(sys.argv) > 1 else 'v2'
revision_dir = Path(__file__).parent / 'revisions'
available = {p.parent.name: p for p in revision_dir.glob('*/manifest.json')}
if revision not in available:
    raise SystemExit('Choose a revision: ' + ', '.join(sorted(available)))
manifest_path = available[revision]
manifest = json.loads(manifest_path.read_text())
converter = shutil.which('afconvert')
if converter is None:
    raise SystemExit('afconvert is required for AAC previews; the WAVs are directly playable.')
output_dir = root / 'audio' / 'recreated-v1' if revision == 'v1' else root / 'audio'
output_dir.mkdir(parents=True, exist_ok=True)
for track in manifest['tracks']:
    source = root / 'audio' / track['file']
    if revision == 'v1' and (output_dir / track['file']).exists():
        source = output_dir / track['file']
    destination = output_dir / track['preview']
    subprocess.run([converter, '-f', 'm4af', '-d', 'aac ', '-b', '192000', '-q', '127',
                    str(source), str(destination)], check=True)
    print(f"Preview: {track['preview']}")
