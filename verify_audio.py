import array
import csv
import json
import math
import wave
from pathlib import Path

expected = {'quindar-in.wav', 'quindar-out.wav', 'quindar-in-out.wav',
            'quindar-in-noisy.wav', 'quindar-out-noisy.wav'}
studies = {}
study_manifest = {}
dj_manifests = {}
for manifest_path in (Path('infinite/experiments/dj/preview.json'), Path('infinite/experiments/dj/track.json'),
                      Path('infinite/experiments/dj/palette-tour.json'),
                      Path('infinite/experiments/dj/digital-drive.json')):
    if manifest_path.exists():
        spec = json.loads(manifest_path.read_text())
        dj_manifests[spec['file']] = spec
assert expected <= {p.name for p in Path('audio').glob('*.wav')}, 'Missing audio renders'
noise_signatures = {}
results = {}
for path in sorted(Path('audio').glob('*.wav')):
    if path.name not in expected and path.name not in dj_manifests:
        continue
    dj_manifest = dj_manifests.get(path.name)
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
        palettes = set()
        block_rms = []
        for bar, row in enumerate(timeline[:-1]):
            assert int(row['bar']) == bar and times[bar+1] > times[bar]
            assert 118 <= float(row['bpm']) <= 140
            start, end = int(times[bar]*rate)*2, int(times[bar+1]*rate)*2
            assert max(map(abs, values[start:end])) > 0.002, 'Unexpected silent DJ bar'
            records.update(int(row[key]) for key in ('record_a', 'record_b') if int(row[key]) >= 0)
            palettes.update(int(row[key]) for key in ('palette_a', 'palette_b') if int(row.get(key, -1)) >= 0)
        assert len(records) >= dj_manifest.get('minimum_records', 2), 'DJ render has too few records'
        assert len(palettes) >= dj_manifest.get('minimum_palettes', 0), 'DJ render has too few instrument palettes'
        automatic = []
        previous_auto = False
        for row in timeline[:-1]:
            active = row.get('stutter_source') == 'auto'
            if active:
                assert int(row['stutter_division']) == 16
                assert float(row['stutter_remaining']) == 0.5
                assert float(row['stutter_bars']) == 0.5 and float(row['stutter_start_beat']) == 2
                if not previous_auto:
                    bar = int(row['bar'])
                    half_seconds = (times[bar+1]-times[bar])*0.5
                    automatic.append(dict(bar=bar, seconds=round(float(row['seconds'])+half_seconds, 4),
                                          division=16, bars=0.5, duration_seconds=round(half_seconds, 4)))
            previous_auto = active
        assert len(automatic) >= dj_manifest.get('minimum_auto_stutters', 0), 'Automatic stutter is missing from render'
        if dj_manifest.get('settings', {}).get('autoStutter') is False:
            assert not automatic, 'Automatic stutter leaked into the clean palette comparison'
        result['automatic_stutter_phrases'] = automatic
        if dj_manifest.get('check_groove_gaps'):
            def window_rms(start, end):
                samples = values[int(start*rate)*channels:int(end*rate)*channels]
                return math.sqrt(sum(v*v for v in samples) / len(samples))

            gaps = []
            spotlights = []
            for bar, row in enumerate(timeline[:-1]):
                if int(row['mixing']):
                    continue
                start, end = times[bar], times[bar+1]
                breath = int(row['breath_a']) or int(row['breath_b'])
                pickup = int(row['low_gap_a']) or int(row['low_gap_b'])
                if breath or pickup:
                    cut_beat = min(float(row['cut_from_a']), float(row['cut_from_b']))
                    assert 4-cut_beat == dj_manifest['pullback_beats'], 'Pullback is too long'
                    cut_time = start+(end-start)*cut_beat/4
                    before = window_rms(start+0.08, cut_time-0.06)
                    after = window_rms(cut_time+0.12, end-0.04)
                    assert after < before*0.75, 'Pullback did not reduce the audio energy'
                    gaps.append(dict(bar=bar, seconds=round(cut_time, 4),
                                     duration_seconds=round(end-cut_time, 4),
                                     kind='phrase pullback' if breath else 'pre-drop pickup'))
                if int(row['drum_spotlight_a']) or int(row['drum_spotlight_b']):
                    spotlights.append(dict(bar=bar, seconds=start, duration_seconds=round(end-start, 4)))
            regular = [g for g in gaps if g['kind'] == 'phrase pullback']
            assert 0 < len(regular) <= dj_manifest['maximum_pullbacks'], 'Pullbacks are too frequent'
            assert any(g['kind'] == 'pre-drop pickup' for g in gaps)
            assert 0 < len(spotlights) <= dj_manifest['maximum_drum_spotlights'], 'Drum spotlights are too frequent'
            result['groove_gaps'] = gaps
            result['drum_spotlights'] = spotlights
        for bar in range(0, dj_manifest['bars'], 4):
            segment = values[int(times[bar]*rate)*2:int(times[min(bar+4,dj_manifest['bars'])]*rate)*2]
            level = math.sqrt(sum(v*v for v in segment)/len(segment))
            block_rms.append(round(20*math.log10(level), 2))
        active = values[int(times[0]*rate)*2:int(times[-1]*rate)*2]
        level = math.sqrt(sum(v*v for v in active)/len(active))
        result.update(title=dj_manifest['title'], seed=dj_manifest['seed'], bars=dj_manifest['bars'],
                      settings=dj_manifest['settings'], records=sorted(records), palettes=sorted(palettes),
                      music_seconds=round(times[-1]-times[0], 4),
                      music_rms_dbfs=round(20*math.log10(level), 2), four_bar_rms_dbfs=block_rms)
        if dj_manifest.get('segments'):
            palette_levels = {}
            segments = dj_manifest['segments']
            for i, spec in enumerate(segments):
                end = segments[i+1]['start_seconds'] if i+1 < len(segments) else times[-1]
                start = int((spec['start_seconds'] + 0.25) * rate) * channels
                stop = int((end - 0.15) * rate) * channels
                segment = values[start:stop]
                level = math.sqrt(sum(v*v for v in segment)/len(segment))
                palette_levels[spec['name']] = round(20*math.log10(level), 2)
            assert max(palette_levels.values()) - min(palette_levels.values()) < 6, 'Palette mix levels are poorly matched'
            result['palette_rms_dbfs'] = palette_levels
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
