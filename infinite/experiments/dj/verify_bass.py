"""Check that both bass controls change the actual signal, after level matching."""
import json
import math
import sys
import wave
from pathlib import Path

path = Path(sys.argv[1])
with wave.open(str(path), "rb") as wav:
    rate, channels, width = wav.getframerate(), wav.getnchannels(), wav.getsampwidth()
    raw = wav.readframes(wav.getnframes())
assert (rate, channels, width) == (48000, 2, 3)


def segment(start):
    first, last = int((start + 0.10) * rate), int((start + 0.28) * rate)
    return [int.from_bytes(raw[i * 6:i * 6 + 3], "little", signed=True) / 8388608
            for i in range(first, last)]


def rms(values):
    return math.sqrt(sum(value * value for value in values) / len(values))


def difference(left, right):
    a, b = rms(left), rms(right)
    return rms([x / a - y / b for x, y in zip(left, right)])


results = {}
for index, name in enumerate(("Classic sub", "Reese bass", "FM bass", "Acid bass")):
    signals = [segment(0.1 + index * 4 + variant) for variant in range(4)]
    for signal in signals:
        assert all(math.isfinite(value) for value in signal)
        assert 0.001 < rms(signal) < 0.3 and max(map(abs, signal)) < 0.8
    tone = difference(signals[0], signals[1])
    drive = difference(signals[2], signals[3])
    assert tone > 0.02, f"{name}: filter control has no material signal effect"
    assert drive > 0.02, f"{name}: drive control has no material signal effect"
    results[name] = dict(filter_difference=round(tone, 4), drive_difference=round(drive, 4))
print(json.dumps(results, indent=2))
