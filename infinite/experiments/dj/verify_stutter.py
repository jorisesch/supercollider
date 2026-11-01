"""Check audible gate rates from stutter-check.scd, not just control values."""
import math
from pathlib import Path
import sys
import tempfile
import wave

path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(tempfile.gettempdir()) / "dj-stutter-check.wav"
with wave.open(str(path), "rb") as wav:
    rate, channels, width = wav.getframerate(), wav.getnchannels(), wav.getsampwidth()
    raw = wav.readframes(wav.getnframes())
assert (rate, channels, width) == (48000, 2, 3)
samples = [int.from_bytes(raw[i:i+3], "little", signed=True) / 8388608
           for i in range(0, len(raw), channels * width)]
block = int(rate * 0.005)
expected_pulses = (4, 8, 8, 16, 16, 16, 16, 1)
for index, expected in enumerate(expected_pulses):
    start = round((0.1 + index * 2) * rate)
    segment = samples[start:start + 2 * rate]
    levels = [math.sqrt(sum(x*x for x in segment[i:i+block]) / len(segment[i:i+block]))
              for i in range(0, len(segment), block)]
    threshold = max(levels) * 0.55
    active = [level > threshold for level in levels]
    rises = sum(on and (i == 0 or not active[i-1]) for i, on in enumerate(active))
    assert rises == expected, (index, rises, expected)
    if index < 7:
        assert min(levels) < max(levels) * 0.25, "Stutter gaps are inaudible"
        print(f"PASS: bar {index+1} has {rises} pulses at 120 BPM")
    else:
        # Ignore the first 40ms while the multi-bar action releases.
        assert min(levels[8:]) > max(levels) * 0.9, "Stutter did not return to bypass"
        print("PASS: following bar returns to steady, ungated output")


def levels_between(start, duration):
    segment = samples[round(start*rate):round((start+duration)*rate)]
    return [math.sqrt(sum(x*x for x in segment[i:i+block]) / len(segment[i:i+block]))
            for i in range(0, len(segment), block)]


before = levels_between(16.14, 0.9)
assert min(before) > max(before)*0.9, "Half-bar hit began before beat three"
half = levels_between(17.1, 1)
active = [level > max(half)*0.55 for level in half]
rises = sum(on and (i == 0 or not active[i-1]) for i, on in enumerate(active))
assert rises == 8, ("Half-bar sixteenth hit", rises, 8)
assert min(half) < max(half)*0.25, "Half-bar stutter has no audible gaps"
after = levels_between(18.15, 1.8)
assert min(after) > max(after)*0.9, "Half-bar hit failed to release at the next bar"
print("PASS: steady first half, exactly eight sixteenth pulses in the second half, then steady bypass")
