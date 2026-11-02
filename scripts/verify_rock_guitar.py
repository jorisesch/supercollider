"""Verify actual guitar pitch movement, settled endings and isolated guitar dynamics."""
import array
import math
import statistics
import tempfile
import wave
from pathlib import Path


def read(name, channels):
    candidates = [Path(tempfile.gettempdir()),
                  Path.home() / 'Library/Application Support/SuperCollider/tmp', Path('/tmp')]
    path = next((folder / name for folder in candidates if (folder / name).exists()), candidates[0] / name)
    with wave.open(str(path), 'rb') as f:
        assert (f.getframerate(), f.getnchannels(), f.getsampwidth()) == (48000, channels, 3)
        raw = f.readframes(f.getnframes())
    return array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True) / 8388608
                             for i in range(0, len(raw), 3)))


pitch = read('rock-guitar-pitch.wav', 6)
for i, name in enumerate(['plain', 'slide', 'bend/return', 'bend into note', 'vibrato', 'landing']):
    start = 0.1 + i*2.2

    def actual_pitch(at):
        center = int((start+at)*48000)
        samples = pitch[(center-1440)*6:(center+1440)*6:6]
        mean = sum(samples)/len(samples)
        samples = [v-mean for v in samples]
        assert math.sqrt(sum(v*v for v in samples)/len(samples)) > 0.0001, 'Silent guitar probe'
        # Normalized autocorrelation around the known test register, with
        # sub-sample interpolation; independent of the synth's control trace.
        correlations = {}
        for lag in range(90, 133):
            a, b = samples[:-lag], samples[lag:]
            cross = sum(x*y for x,y in zip(a,b))
            energy = math.sqrt(sum(x*x for x in a)*sum(y*y for y in b))
            correlations[lag] = cross/energy
        peak = max(range(91, 132), key=correlations.get)
        assert correlations[peak] > 0.8, 'Unreliable guitar periodicity'
        left, mid, right = [correlations[peak+d] for d in (-1, 0, 1)]
        correction = 0.5*(left-right)/(left-2*mid+right)
        return 48000/(peak+correction)

    def trace(channel, a, b):
        if channel == 3:
            return [actual_pitch(a+i*0.02) for i in range(max(1, int((b-a)/0.02)))]
        return [pitch[frame*6+channel]*2000
                for frame in range(int((start+a)*48000), int((start+b)*48000), 64)]

    model = trace(2, 1.48, 1.58)
    actual = trace(3, 1.48, 1.58)
    assert model and actual, f'No reliable final pitch for {name}'
    cents = 1200*math.log2(statistics.median(actual)/440)
    assert abs(statistics.median(model)-440) < 0.01, 'Pitch path did not settle on the target'
    assert abs(cents) < 30, f'Actual final pitch misses the chord tone: {name} {cents:.1f} cents'
    if i in (1, 3, 5):
        assert min(trace(3, 0.07, 0.35)) < 435, f'{name} has no audible lower approach'
    if i == 2:
        assert max(trace(3, 0.4, 1.0)) > 470, 'Actual string did not follow the bend'
    if i == 4:
        moving = trace(3, 0.60, 1.05)
        span = 1200*math.log2(max(moving)/min(moving))
        assert 5 < span < 100, f'Actual vibrato span invalid: {span:.1f} cents'
    print(f'PASS: {name}: actual final pitch {cents:+.1f} cents from target')

strip = read('rock-guitar-strip.wav', 4)
differences = [abs(strip[n*4+c]-strip[n*4+c+2])
               for n in range(int(0.1*48000), int(4.1*48000)) for c in (0, 1)]
assert max(differences) == 0, 'Guitar compressor/chorus changed bass or drums'


def rms(channel, a, b):
    samples = strip[int(a*48000)*4+channel:int(b*48000)*4:4]
    return math.sqrt(sum(v*v for v in samples)/len(samples))


old = [rms(0, 5.5+i, 5.8+i) for i in range(4)]
new = [rms(2, 5.5+i, 5.8+i) for i in range(4)]
assert new[-1]/new[0] < (old[-1]/old[0])*0.75, 'Guitar compressor is not reducing dynamic range'
print('PASS: full guitar chorus/compression leaves bass/drums PCM-identical; compressor reduces guitar dynamic range')
