"""Measure the lead comparison at equal note controls; no external dependencies."""
import cmath
import json
import math
from pathlib import Path
import sys
import wave

path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('audio/digital-drive-lead-ab-v6d.wav')
with wave.open(str(path), 'rb') as wav:
    rate, channels, width = wav.getframerate(), wav.getnchannels(), wav.getsampwidth()
    raw = wav.readframes(wav.getnframes())
assert (rate, channels, width) == (48000, 2, 3)
samples = [int.from_bytes(raw[i:i+3], 'little', signed=True) / 8388608
           for i in range(0, len(raw), channels*width)]
assert 0.01 < max(map(abs, samples)) < 0.8
assert max(map(abs, samples[-2400:])) < 0.0001


def measure(start):
    n = 16384
    values = samples[round((start+0.06)*rate):round((start+0.06)*rate)+n]
    level = math.sqrt(sum(v*v for v in values)/n)
    assert level > 0.001 and math.isfinite(level)
    a = [complex(v*(0.5-0.5*math.cos(2*math.pi*i/(n-1)))) for i, v in enumerate(values)]
    j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            a[i], a[j] = a[j], a[i]
    size = 2
    while size <= n:
        step = cmath.exp(-2j*math.pi/size)
        for base in range(0, n, size):
            phase = 1
            for k in range(size//2):
                left, right = a[base+k], a[base+k+size//2]*phase
                a[base+k], a[base+k+size//2] = left+right, left-right
                phase *= step
        size *= 2
    power = [abs(v)**2 for v in a[1:n//2]]
    high = sum(power[math.ceil(2500*n/rate)-1:])/sum(power)
    return level, high


results = []
for index, midi in enumerate((60, 67, 74, 74)):
    before, after = measure(0.1+index), measure(4.1+index)
    reduction = 10*math.log10(after[1]/before[1])
    level_change = 20*math.log10(after[0]/before[0])
    assert reduction < -3, ('Upper harmonics were not reduced after level normalization', index, reduction)
    assert abs(level_change) < 4, ('Lead level changed too much', index, level_change)
    results.append(dict(midi=midi, treble_fraction_change_db=round(reduction, 2),
                        rms_change_db=round(level_change, 2)))
print(json.dumps(results, indent=2))
