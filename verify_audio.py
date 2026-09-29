import array
import json
import math
import wave
from pathlib import Path

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
    results[path.name] = result
Path('audio/verification.json').write_text(json.dumps(results, indent=2)+'\n')
print(json.dumps(results, indent=2))
