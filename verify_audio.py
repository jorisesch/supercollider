import array
import json
import math
import wave
from pathlib import Path

expected = {'quindar-in.wav', 'quindar-out.wav', 'quindar-in-out.wav',
            'quindar-in-noisy.wav', 'quindar-out-noisy.wav', 'desert-pod-racer.wav'}
assert expected <= {p.name for p in Path('audio').glob('*.wav')}, 'Missing audio renders'
results = {}
for path in sorted(Path('audio').glob('*.wav')):
    with wave.open(str(path), 'rb') as w:
        rate, channels, width, frames = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(frames)
    assert width == 3 and rate == 48000 and channels == 2
    values = array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True) / 8388608 for i in range(0, len(raw), 3)))
    peak = max(map(abs, values))
    rms = math.sqrt(sum(v*v for v in values) / len(values))
    assert 0.01 < peak < 0.95 and rms > 0.001
    edge = max(map(abs, values[-4800:]))
    assert edge < 0.0001
    result = dict(seconds=round(frames/rate, 4), sample_rate=rate, channels=channels, peak_dbfs=round(20*math.log10(peak), 2), rms_dbfs=round(20*math.log10(rms), 2), end_peak=edge)
    if path.stem in ('quindar-in', 'quindar-out'):
        mono = values[::2]
        segment = mono[int(0.06*rate):int(0.29*rate)]
        crossings = [i + (-segment[i]) / (segment[i+1]-segment[i]) for i in range(len(segment)-1) if segment[i] <= 0 < segment[i+1]]
        hz = (len(crossings)-1)*rate/(crossings[-1]-crossings[0])
        target = 2525 if path.stem == 'quindar-in' else 2475
        assert abs(hz-target) < 0.1
        active = [i for i,v in enumerate(mono) if abs(v) > 0.00001]
        duration = (active[-1]-active[0]+1)/rate
        assert abs(duration-0.25) < 0.001
        result.update(measured_hz=round(hz, 3), tone_seconds=round(duration, 5))
    if path.stem.endswith('-noisy'):
        mono = values[::2]
        target = 2525 if path.stem == 'quindar-in-noisy' else 2475
        # Correlation on the steady tone tolerates static that disrupts zero crossings.
        segment = mono[int(0.15*rate):int(0.36*rate)]
        def power(hz):
            step = 2*math.pi*hz/rate
            real = sum(v*math.cos(step*i) for i,v in enumerate(segment))
            imag = sum(v*math.sin(step*i) for i,v in enumerate(segment))
            return real*real + imag*imag
        hz = max(range(target-60, target+61), key=power)
        assert abs(hz-target) <= 1
        noise_segment = mono[int(0.07*rate):int(0.12*rate)]
        noise_rms = math.sqrt(sum(v*v for v in noise_segment)/len(noise_segment))
        assert noise_rms > 0.002, 'Radio texture must be audible before the tone'
        assert abs(frames/rate - 0.65) < 0.003
        result.update(measured_hz=hz, pre_tone_noise_dbfs=round(20*math.log10(noise_rms), 2))
    results[path.name] = result
Path('audio/verification.json').write_text(json.dumps(results, indent=2)+'\n')
print(json.dumps(results, indent=2))
