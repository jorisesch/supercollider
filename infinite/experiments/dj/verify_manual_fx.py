"""Check the rendered held stutter and the return to continuous signal."""
import array
import math
import sys
import wave

with wave.open(sys.argv[1], 'rb') as wav:
    assert (wav.getframerate(), wav.getnchannels(), wav.getsampwidth()) == (48000, 2, 3)
    raw = wav.readframes(wav.getnframes())
samples = array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True) / 8388608
                            for i in range(0, len(raw), 6)))
assert all(math.isfinite(v) for v in samples)
assert 0.01 < max(map(abs, samples)) < 0.9
assert max(map(abs, samples[-4800:])) < 0.0001


def rms(start, duration=0.012):
    values = samples[round(start*48000):round((start+duration)*48000)]
    return math.sqrt(sum(v*v for v in values) / len(values))


bar = 4*60/128
pulse = bar/16
# The last held bar still contains all 16 gates, beyond the old four-bar limit.
ratios = []
for i in range(16):
    start = 0.1+7*bar+i*pulse
    high, low = rms(start+0.030), rms(start+0.088)
    assert high > 0.01
    ratios.append(low/high)
assert max(ratios) < 0.45, ('Held stutter gates missing', ratios)
after = [rms(0.1+8*bar+0.35+i*0.03) for i in range(30)]
assert min(after)/max(after) > 0.8, 'Stutter continued after Stop FX'
print(f'PASS: 16 pulses in the sixth held bar; worst low/high ratio {max(ratios):.3f}; '
      'continuous output after release; finite stereo signal, headroom and quiet tail.')
