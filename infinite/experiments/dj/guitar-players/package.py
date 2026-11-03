"""Index the current Rock-player renders and their performance timelines."""
import csv
import json
import wave
from pathlib import Path

FOLDER = Path(__file__).resolve().parent
REPO = FOLDER.parents[3]
tracks = []
for name, bars, tour in [('rock-player-set', 64, False), ('rock-player-comparison', 24, True)]:
    timeline = FOLDER / (name+'-timeline.tsv')
    with timeline.open() as f:
        rows = list(csv.DictReader(f, delimiter='\t'))
    assert len(rows) == bars+1
    with wave.open(str(REPO / 'audio' / (name+'.wav')), 'rb') as f:
        seconds = f.getnframes()/f.getframerate()
    tracks.append({'file': name+'.wav', 'preview': name+'.m4a', 'seconds': seconds, 'bars': bars,
                   'timeline': timeline.relative_to(REPO).as_posix(), 'tour': tour,
                   'tail_seconds': 0 if tour else 4,
                   'segments': [{'player': rows[i]['guitarist_a'], 'start_seconds': float(rows[i]['seconds'])}
                                for i in range(0, bars, 8)] if tour else []})
(FOLDER / 'manifest.json').write_text(json.dumps({'human_listening_review': 'pending',
    'player_policy': 1, 'players': ['Rook', 'June', 'Flint'], 'tracks': tracks}, indent=2)+'\n')
print('Indexed Rock set and three-player comparison')
