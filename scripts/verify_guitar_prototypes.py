"""Verify prototype PCM, gesture variety, actual pitch and accepted-timbre match."""
import array
import csv
import json
import math
import statistics
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'infinite/experiments/dj/guitar-prototypes'
TEMP = [Path(tempfile.gettempdir()),
        Path.home() / 'Library/Application Support/SuperCollider/tmp', Path('/tmp')]


def temporary(name):
    return next(p / name for p in TEMP if (p / name).exists())


def samples(path, channels, start=0, duration=None):
    with wave.open(str(path), 'rb') as f:
        assert (f.getframerate(), f.getsampwidth(), f.getnchannels()) == (48000, 3, channels)
        f.setpos(round(start*48000))
        raw = f.readframes(round(duration*48000) if duration else f.getnframes())
    return array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True)/8388608
                             for i in range(0, len(raw), 3)))


def rms(values):
    return math.sqrt(sum(x*x for x in values)/len(values))


events = list(csv.DictReader((FOLDER / 'events.tsv').open(), delimiter='\t'))
lookup = {(r['profile'], r['index']): r for r in events}
report = {'human_listening_review': 'pending', 'profiles': {}, 'probes': []}
for profile in ['reference', 'restrained', 'loose', 'urgent']:
    rows = [r for r in events if r['profile'] == profile]
    assert len(rows) == 19
    assert [(r['beat'], r['note'], r['hold']) for r in rows] == [
        (r['beat'], r['note'], r['hold']) for r in events if r['profile'] == 'reference']
    active = [r for r in rows if float(r['vibrato_depth']) > 0]
    straight = [r for r in rows if max(map(float, r['bend_levels'].split(','))) == 0]
    if profile == 'reference':
        straight = [r for r in rows if float(r['reference_bend']) == 0]
    if profile != 'reference':
        assert len(straight) >= 8 and len(active) <= 14
        assert len({round(float(r['vibrato_delay']), 2) for r in active}) >= 4
    report['profiles'][profile] = {
        'notes': len(rows), 'notes_without_finger_bend': len(straight),
        'notes_with_vibrato': len(active) if profile != 'reference' else sum(float(r['reference_vibrato']) > 0 for r in rows),
        'vibrato_delay_seconds': [round(float(r['vibrato_delay']), 3) for r in active]}

probe_path = temporary('rock-phrasing-probes.wav')
with (FOLDER / 'probes.tsv').open() as f:
    probes = list(csv.DictReader(f, delimiter='\t'))
errors = []
for probe in probes:
    start, hold, note = [float(probe[k]) for k in ('start_seconds', 'hold', 'note')]
    data = samples(probe_path, 8, start, hold+0.08)
    row = lookup[(probe['profile'], probe['index'])]
    target = 440*2**((note-69)/12)

    def trace(at, channel, factor):
        return data[min(int(at*48000), len(data)//8-1)*8+channel]*factor

    def measured(at):
        center = int(at*48000)
        values = data[(center-768)*8:(center+768)*8:8]
        mean = statistics.mean(values)
        values = [v-mean for v in values]
        assert rms(values) > 0.0001
        frequency = trace(at, 2, 2000)
        period = 48000/frequency
        low, high = int(period*0.91), int(period*1.09)+1
        corr = {}
        for lag in range(low, high+1):
            a, b = values[:-lag], values[lag:]
            corr[lag] = sum(x*y for x, y in zip(a, b))/math.sqrt(sum(x*x for x in a)*sum(y*y for y in b))
        peak = max(range(low+1, high), key=corr.get)
        assert corr[peak] > 0.75, 'Unreliable periodicity'
        left, mid, right = [corr[peak+d] for d in (-1, 0, 1)]
        return 48000/(peak+0.5*(left-right)/(left-2*mid+right))

    points = [0.04+j*0.005 for j in range(max(1, int((hold-0.09)/0.005)))]
    frequencies = [trace(t, 2, 2000) for t in points]
    cents = [1200*math.log2(v/target) for v in frequencies]
    assert all(0 < v < 1500 for v in frequencies)
    assert max(trace(t, 7, 1/20) for t in points) < 0.045, 'Unbounded finger displacement'
    if probe['kind'] == 'preRelease':
        assert cents[0] > 150 and abs(cents[-1]) < 8, 'Missing picked pre-bend release'
    if probe['kind'] == 'arrival':
        assert cents[0] < -175, 'Missing upward arrival'
        if probe['profile'] == 'loose' and probe['index'] == '8':
            assert -18 < cents[-1] < -4, 'Intentionally under-bent passing note became perfect'
        else:
            assert abs(cents[-1]) < 8, 'Unintended bend landing error'
    if probe['kind'] == 'anchor':
        assert abs(cents[-1]) < 4, 'Phrase root did not settle'
    depth = float(row['vibrato_depth'])
    onset = None
    if depth:
        onset = next(t for t in points if trace(t, 4, 2) > 0.01)
        delay = min(float(row['vibrato_delay']), max(hold-0.18, 0))
        rise = min(max(float(row['vibrato_rise']), 0.01), max(hold-delay-0.12, 0.01))
        assert delay-0.01 <= onset <= delay+rise+0.06, (probe, onset, delay, rise)
    for t in [hold*f for f in (0.20, 0.40, 0.65, 0.86, 0.96)]:
        movement = abs(1200*math.log2(trace(t+0.016, 2, 2000)/trace(t-0.016, 2, 2000)))
        if movement < 30:
            actual = measured(t)
            error = abs(1200*math.log2(actual/trace(t, 2, 2000)))
            assert error < 22, (probe, t, error)
            errors.append(error)
    report['probes'].append({'profile': probe['profile'], 'index': int(probe['index']),
                             'kind': probe['kind'], 'vibrato_onset_seconds': round(onset, 3) if onset else None,
                             'end_cents_from_written_note': round(cents[-1], 2)})

# Shared-term optimization must preserve the accepted body; the extra hand
# controls must leave it equivalent when gestures are disabled. Exclude pick noise.
timbre = samples(temporary('rock-phrasing-timbre.wav'), 6, 0.14, 1.1)
original = timbre[::6]
timbre_errors = []
for channel in (2, 4):
    other = timbre[channel::6]
    relative = rms([a-b for a, b in zip(original, other)])/rms(original)
    assert relative < 0.005, relative
    timbre_errors.append(relative)
report['body_relative_error'] = timbre_errors
report['max_waveform_pitch_error_cents'] = round(max(errors), 2)
report['waveform_pitch_measurements'] = len(errors)

manifest = json.loads((FOLDER / 'manifest.json').read_text())
report['audio'] = {}
for track in manifest['tracks']:
    path = ROOT / 'audio' / track['file']
    data = samples(path, 2)
    peak = max(map(abs, data))
    assert 0.01 < peak < 0.95 and rms(data) > 0.002
    assert max(map(abs, data[-4800:])) < 0.0001
    with wave.open(str(path), 'rb') as f:
        assert abs(f.getnframes()/48000-track['seconds']) < 0.003
    report['audio'][track['file']] = {'peak_dbfs': round(20*math.log10(peak), 2),
                                     'rms_dbfs': round(20*math.log10(rms(data)), 2)}
levels = [r['rms_dbfs'] for name, r in report['audio'].items() if 'comparison' not in name]
assert max(levels)-min(levels) < 1, 'Listening levels obscure the gesture comparison'
report['profile_level_spread_db'] = round(max(levels)-min(levels), 2)
(FOLDER / 'verification.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report, indent=2))
