import array
import csv
import json
import math
import wave
from pathlib import Path

expected = {'quindar-in.wav', 'quindar-out.wav', 'quindar-in-out.wav',
            'quindar-in-noisy.wav', 'quindar-out-noisy.wav', 'rocket-launch.wav',
            'pod-racer.wav', 'sonar-ping.wav', 'infinite-edm.wav', 'infinite-edm-d.wav',
            'infinite-soundscape.wav'}
study_manifest_path = Path('infinite/studies/manifest.json')
study_manifest = json.loads(study_manifest_path.read_text()) if study_manifest_path.exists() else {}
studies = {item['file']: dict(item, revision='v1') for item in study_manifest.get('tracks', [])}
for manifest_path in sorted(Path('infinite/studies/revisions').glob('*/manifest.json')):
    revision_manifest = json.loads(manifest_path.read_text())
    for item in revision_manifest.get('tracks', []):
        studies[item['file']] = dict(item, revision=revision_manifest.get('revision', manifest_path.parent.name))
expected.update(studies)
dj_manifest_path = Path('infinite/experiments/dj/preview.json')
dj_manifest = json.loads(dj_manifest_path.read_text()) if dj_manifest_path.exists() else None
if dj_manifest:
    expected.add(dj_manifest['file'])
assert expected <= {p.name for p in Path('audio').glob('*.wav')}, 'Missing audio renders'
noise_signatures = {}
results = {}
for path in sorted(Path('audio').glob('*.wav')):
    with wave.open(str(path), 'rb') as w:
        rate, channels, width, frames = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(frames)
    assert width == 3 and rate == 48000 and channels == 2
    values = array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True) / 8388608 for i in range(0, len(raw), 3)))
    peak = max(map(abs, values))
    rms = math.sqrt(sum(v*v for v in values) / len(values))
    assert math.isfinite(peak) and math.isfinite(rms)
    assert 0.01 < peak < 0.95 and rms > 0.001
    edge = max(map(abs, values[-4800:]))
    assert edge < 0.0001
    result = dict(seconds=round(frames/rate, 4), sample_rate=rate, channels=channels, peak_dbfs=round(20*math.log10(peak), 2), rms_dbfs=round(20*math.log10(rms), 2), end_peak=edge)
    if dj_manifest and path.name == dj_manifest['file']:
        with Path(dj_manifest['timeline']).open(newline='') as timeline_file:
            timeline = list(csv.DictReader(timeline_file, delimiter='\t'))
        assert len(timeline) == dj_manifest['bars'] + 1, 'DJ timeline is incomplete'
        times = [float(row['seconds']) for row in timeline]
        assert abs(times[0] - dj_manifest['lead_in_seconds']) < 1e-6
        assert abs(float(timeline[0]['bpm']) - dj_manifest['initial_bpm']) < 1e-6
        assert abs(frames/rate - times[-1] - dj_manifest['tail_seconds']) < 0.003, 'DJ render/timeline length mismatch'
        assert max(map(abs, values[:int(0.08*rate)*2])) < 0.0001, 'DJ preview must begin quietly'
        records = set()
        block_rms = []
        for bar, row in enumerate(timeline[:-1]):
            assert int(row['bar']) == bar and times[bar+1] > times[bar]
            assert 118 <= float(row['bpm']) <= 140
            start, end = int(times[bar]*rate)*2, int(times[bar+1]*rate)*2
            assert max(map(abs, values[start:end])) > 0.002, 'Unexpected silent DJ bar'
            records.update(int(row[key]) for key in ('record_a', 'record_b') if int(row[key]) >= 0)
        assert len(records) >= 2, 'DJ preview must include an automatic record handover'
        for bar in range(0, dj_manifest['bars'], 4):
            segment = values[int(times[bar]*rate)*2:int(times[min(bar+4,dj_manifest['bars'])]*rate)*2]
            level = math.sqrt(sum(v*v for v in segment)/len(segment))
            block_rms.append(round(20*math.log10(level), 2))
        active = values[int(times[0]*rate)*2:int(times[-1]*rate)*2]
        level = math.sqrt(sum(v*v for v in active)/len(active))
        result.update(title=dj_manifest['title'], seed=dj_manifest['seed'], bars=dj_manifest['bars'],
                      settings=dj_manifest['settings'], records=sorted(records),
                      music_seconds=round(times[-1]-times[0], 4),
                      music_rms_dbfs=round(20*math.log10(level), 2), four_bar_rms_dbfs=block_rms)
    if path.name in studies:
        spec = studies[path.name]
        beat_seconds = 60 / spec['bpm']
        music_seconds = study_manifest['bars'] * study_manifest['beats_per_bar'] * beat_seconds
        expected_seconds = study_manifest['lead_in_seconds'] + music_seconds + study_manifest['tail_seconds']
        assert abs(frames/rate - expected_seconds) < 0.003, 'Wrong 32-bar study length'
        assert max(map(abs, values[:int(0.08*rate)*2])) < 0.0001, 'Study must begin quietly'
        block_rms = []
        for bar in range(32):
            start = int((0.1 + bar*4*beat_seconds)*rate)*2
            end = int((0.1 + (bar+1)*4*beat_seconds)*rate)*2
            assert max(map(abs, values[start:end])) > 0.002, 'Unexpected silent bar'
        for block in range(8):
            start = int((0.1 + block*16*beat_seconds)*rate)*2
            end = int((0.1 + (block+1)*16*beat_seconds)*rate)*2
            segment = values[start:end]
            level = math.sqrt(sum(v*v for v in segment)/len(segment))
            block_rms.append(round(20*math.log10(level), 2))
        start, end = int(0.1*rate)*2, int((0.1+music_seconds)*rate)*2
        active = values[start:end]
        music_rms = math.sqrt(sum(v*v for v in active)/len(active))
        result.update(bars=32, bpm=spec['bpm'], key=spec['key'], title=spec['title'], revision=spec.get('revision', 'v1'),
                      music_seconds=round(music_seconds,4),
                      music_rms_dbfs=round(20*math.log10(music_rms),2),
                      four_bar_rms_dbfs=block_rms)
    if path.stem.startswith('infinite-'):
        target = {'infinite-edm': 68.1, 'infinite-edm-d': round(0.1 + (32 * 4 * 60 / 126) + 4, 4),
                  'infinite-soundscape': 36.1}[path.stem]
        assert abs(frames/rate - target) < 0.003
        assert max(map(abs, values[:4800])) < 0.0001
        for second in range(2, int(target)-4, 4):
            segment = values[second*rate*2:(second+2)*rate*2]
            assert max(map(abs, segment)) > 0.001, 'Unexpected silent section'
        result.update(seed=2600, preview_bars=32 if path.stem != 'infinite-soundscape' else 8)
    if path.stem == 'rocket-launch':
        mono = values[::2]
        assert abs(frames/rate - 43) < 0.003
        for second in range(5):
            beep = mono[int((second+0.11)*rate):int((second+0.2)*rate)]
            gap = mono[int((second+0.3)*rate):int((second+0.9)*rate)]
            assert max(map(abs, beep)) > 0.1, 'Missing countdown beep'
            assert max(map(abs, gap)) < 0.0001, 'Countdown gap must be silent'
        result['countdown_beeps'] = 5
        result['ignition_seconds'] = 5.1
    if path.stem == 'sonar-ping':
        mono = values[::2]
        assert abs(frames/rate - 9) < 0.003
        onset = mono[int(0.1*rate):int(0.4*rate)]
        tail = mono[int(1.0*rate):int(5.5*rate)]
        assert max(map(abs, onset)) > 0.1, 'Sonar ping onset is missing'
        assert max(map(abs, tail)) > 0.002, 'Sonar resonance tail is missing'
        assert max(map(abs, mono[:int(0.08*rate)])) == 0, 'Sonar render should begin after the scheduled onset'
        result.update(ping_onset_seconds=0.1, tail_seconds=5.5)
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
        segment = mono[int(0.25*rate):int(0.46*rate)]
        def power(hz):
            step = 2*math.pi*hz/rate
            real = sum(v*math.cos(step*i) for i,v in enumerate(segment))
            imag = sum(v*math.sin(step*i) for i,v in enumerate(segment))
            return real*real + imag*imag
        hz = max(range(target-60, target+61), key=power)
        assert abs(hz-target) <= 1
        noise_segment = mono[int(0.065*rate):int(0.22*rate)]
        noise_rms = math.sqrt(sum(v*v for v in noise_segment)/len(noise_segment))
        assert noise_rms > 0.002, 'Vinyl texture must be audible before the tone'
        assert abs(frames/rate - 0.9) < 0.003
        crest = max(map(abs, noise_segment)) / noise_rms
        assert crest > 5, 'Vinyl texture needs isolated transients, not just a noise bed'
        noise_signatures[path.stem] = noise_segment
        result['noise_crest_factor'] = round(crest, 2)
        result.update(measured_hz=hz, pre_tone_noise_dbfs=round(20*math.log10(noise_rms), 2))
    results[path.name] = result
a, b = noise_signatures['quindar-in-noisy'], noise_signatures['quindar-out-noisy']
correlation = sum(x*y for x,y in zip(a,b)) / math.sqrt(sum(x*x for x in a)*sum(y*y for y in b))
assert abs(correlation) < 0.25, 'IN and OUT vinyl textures should be distinct'
for name in ('quindar-in-noisy.wav', 'quindar-out-noisy.wav'):
    results[name]['noise_pair_correlation'] = round(correlation, 4)
Path('audio/verification.json').write_text(json.dumps(results, indent=2)+'\n')
print(json.dumps(results, indent=2))
