"""Verify preserved listening references and controlled revision openings. No writes."""
import hashlib
import json
import wave
from pathlib import Path

studies = Path(__file__).resolve().parent
repo = studies.parents[1]
reference = json.loads((studies / 'revisions/v1/reproduction.json').read_text())
for filename, expected in reference['source_sha256'].items():
    path = studies / 'revisions/v1' / filename
    assert hashlib.sha256(path.read_bytes()).hexdigest() == expected, f'v1 source changed: {filename}'
for item in reference['tracks']:
    for field, digest in [('file', 'wav_sha256'), ('preview', 'preview_sha256')]:
        path = repo / 'audio' / item[field]
        assert hashlib.sha256(path.read_bytes()).hexdigest() == item[digest], f'Original recording changed: {path.name}'
    if item['file'].startswith('study-05-'):
        continue
    original = repo / 'audio' / item['file']
    revised = original.with_name(original.stem + '-v2.wav')
    with wave.open(str(original), 'rb') as first, wave.open(str(revised), 'rb') as second:
        assert first.getparams() == second.getparams(), f'Format/length changed: {revised.name}'
        assert first.readframes(7*48000) == second.readframes(7*48000), f'Opening changed: {revised.name}'
    assert hashlib.sha256(revised.read_bytes()).hexdigest() != item['wav_sha256'], 'Revision is identical to original'
    print(f'PASS {revised.name}: original opening retained; revised audio is distinct')
print('PASS: all five original WAVs/previews and the v1 source snapshot are intact.')
