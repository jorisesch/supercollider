"""Measure Rock gate pulse counts/spacing and following bypass in rendered PCM."""
import array
import csv
import json
import math
import sys
import wave
from pathlib import Path

path = Path(sys.argv[1])
with wave.open(str(path), 'rb') as f:
    assert (f.getframerate(), f.getnchannels(), f.getsampwidth()) == (48000, 2, 3)
    raw = f.readframes(f.getnframes())
samples = array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True)/8388608
                            for i in range(0, len(raw), 6)))
assert 0.001 < max(map(abs, samples)) < 0.95
assert max(map(abs, samples[-4800:])) < 0.0001
with Path(str(path)+'.tsv').open() as f:
    rows = list(csv.DictReader(f, delimiter='\t'))
results = []
bypass_count = 0
for row in rows:
    begin, duration = float(row['start']), float(row['duration'])
    data = samples[round(begin*48000):round((begin+duration)*48000)]
    size = 96
    levels = [math.sqrt(sum(x*x for x in data[i:i+size])/len(data[i:i+size]))
              for i in range(0, len(data), size)]
    if row['bypass'] == '0':
        threshold = max(levels)*0.55
        on = [level > threshold for level in levels]
        # Control-rate changes may enter up to a control block before the
        # nominal boundary. Do not count the following bypass as an extra hit.
        rises = [i*size/48000 for i, active in enumerate(on)
                 if active and (i == 0 or not on[i-1]) and i*size/48000 < duration-0.02]
        expected = int(row['division'])
        assert len(rises) == expected, (row, rises)
        interval = duration/expected
        error = max(abs((b-a)-interval) for a, b in zip(rises, rises[1:]))
        assert error < 0.004, (row, error)
        assert min(levels) < max(levels)*0.25, ('Weak gaps', row)
        results.append({'bpm': int(row['bpm']), 'division': expected, 'pulses': len(rises),
                        'period_seconds': round(interval, 6), 'maximum_spacing_error_ms': round(error*1000, 3)})
    else:
        assert min(levels[30:-10]) > max(levels)*0.9, ('Stutter persisted into bypass', row)
        bypass_count += 1
assert len(results) == bypass_count == 9
print(json.dumps({'status': 'passed', 'cases': results, 'following_bypass_bars': bypass_count,
                  'human_listening_review': 'not assessed by this test'}, indent=2))
