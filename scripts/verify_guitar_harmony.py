"""Check guitar chord spelling, performed bass notes, timing and dry string pitches."""
import array
import csv
import json
import math
import statistics
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'infinite/experiments/dj/guitar-harmony'
TEMP = [Path(tempfile.gettempdir()), Path.home() / 'Library/Application Support/SuperCollider/tmp']
PROBE = next(p / 'rock-harmony-probes.wav' for p in TEMP if (p / 'rock-harmony-probes.wav').exists())
SPELLINGS = {
    'a': {9, 1, 4}, 'fsmin': {6, 9, 1}, 'd': {2, 6, 9}, 'e': {4, 8, 11},
    'amaj7': {9, 1, 4, 8}, 'a7': {9, 1, 4, 7}, 'amin7': {9, 0, 4, 7},
    'aadd9': {9, 1, 4, 11}, 'a9': {9, 1, 4, 7, 11},
    'fsmin7': {6, 9, 1, 4}, 'dadd9': {2, 6, 9, 4}, 'e7': {4, 8, 11, 2},
    'e7shell': {4, 8, 2}, 'bmin7': {11, 2, 6, 9},
    'ae': {9, 1, 4}, 'acs': {9, 1, 4}, 'egs': {4, 8, 11}, 'de': {2, 6, 9, 4},
}
BASS = {'ae': 4, 'acs': 1, 'egs': 8, 'de': 4}
OPEN = [40, 45, 50, 55, 59, 64]


def rows(name):
    with (FOLDER / name).open() as f:
        return list(csv.DictReader(f, delimiter='\t'))


def ints(value):
    return list(map(int, value.split(',')))


def read(path, channels, start=0, duration=None):
    with wave.open(str(path), 'rb') as f:
        assert (f.getframerate(), f.getnchannels(), f.getsampwidth()) == (48000, channels, 3)
        f.setpos(round(start*48000))
        raw = f.readframes(round(duration*48000) if duration else f.getnframes())
    return array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True)/8388608
                             for i in range(0, len(raw), 3)))


def rms(values):
    return math.sqrt(sum(x*x for x in values)/len(values))


def pitch(values, expected):
    mean = statistics.mean(values)
    values = [x-mean for x in values]
    period = 48000/expected
    low, high = int(period*0.9), int(period*1.1)+1
    corr = {}
    for lag in range(low, high+1):
        a, b = values[:-lag], values[lag:]
        corr[lag] = sum(x*y for x, y in zip(a, b))/math.sqrt(sum(x*x for x in a)*sum(y*y for y in b))
    peak = max(range(low+1, high), key=corr.get)
    assert corr[peak] > 0.75, corr[peak]
    left, middle, right = [corr[peak+d] for d in (-1, 0, 1)]
    return 48000/(peak+0.5*(left-right)/(left-2*middle+right))


chords = rows('chords.tsv')
events = rows('events.tsv')
by_id = {r['id']: r for r in chords}
for chord in chords:
    notes, strings, frets = [ints(chord[key]) for key in ['notes', 'strings', 'frets']]
    assert len(strings) == len(set(strings)) == len(notes)
    assert frets == [note-OPEN[string] for note, string in zip(notes, strings)]
    assert all(0 <= fret <= 19 for fret in frets)
    stopped = [fret for fret in frets if fret > 0]
    assert max(stopped)-min(stopped) <= 4
    assert len(set(stopped)) <= 4
    assert {n % 12 for n in notes} == SPELLINGS[chord['key']], chord
    assert min(notes) == int(chord['bass'])
    if chord['key'] in BASS:
        assert min(notes) % 12 == BASS[chord['key']], chord
    if chord['study'] == 'triads':
        root = {'a': 9, 'fsmin': 6, 'd': 2, 'e': 4}[chord['key']]
        intervals = [0, 3 if chord['key'] == 'fsmin' else 4, 7]
        assert (min(notes)-root) % 12 == intervals[int(chord['inversion'])]
for event in events:
    chord = by_id[event['change']]
    assert event['study'] == chord['study']
    assert (int(event['string']), int(event['note'])) in zip(ints(chord['strings']), ints(chord['notes']))
    assert 0.06 <= float(event['hold']) <= 4
    if event['study'] == 'phrasing':
        assert float(event['at'])+float(event['hold'])+0.08 < float(chord['until'])+0.00001

paths = [[ints(c['notes']) for c in chords if c['study'] == 'triads' and int(c['section']) == s] for s in [2, 3]]
movement = [sum(sum(abs(x-y) for x, y in zip(a, b)) for a, b in zip(path, path[1:])) for path in paths]
assert paths[0][0] == paths[1][0]  # Same starting register for the comparison.
assert movement[1] < movement[0]*0.6
descending = [int(c['bass']) for c in chords if c['pattern'] == 'descending_bass']
assert descending == [57, 56, 54, 52, 50, 49, 47, 52]
pedal = [c for c in chords if c['pattern'] == 'e_pedal']
assert len(pedal) == 4 and all(int(c['bass']) == 40 for c in pedal)
pedal_bass = [e for e in events if e['change'] in {c['id'] for c in pedal} and e['string'] == '0']
assert len(pedal_bass) == 2 and all(float(e['hold']) == 2.85 for e in pedal_bass)
assert abs(float(pedal_bass[1]['at'])-float(pedal_bass[0]['at'])-3) < 0.00001

rhythm = {}
for section, pattern in enumerate(['block', 'syncopation', 'bass_answer', 'arpeggio']):
    frames = [c for c in chords if c['study'] == 'phrasing' and int(c['section']) == section]
    signatures = []
    for bar, chord in enumerate(frames):
        selected = [e for e in events if e['change'] == chord['id']]
        firsts = {}
        for event in selected:
            firsts.setdefault(event['stroke'], float(event['at']))
        onsets = sorted(firsts.values())
        origin = 0.1+section*10+bar*2.4
        offsets = [round((t-origin)/0.6, 2) for t in onsets]
        expected = {'block': [0, 2], 'syncopation': [0.5, 1.75, 2.5, 3.5],
                    'bass_answer': [0, 0.5, 2, 2.5],
                    'arpeggio': [-0.25 if bar else 0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5]}[pattern]
        assert offsets == expected, (pattern, bar, offsets)
        signatures.append(offsets)
    rhythm[pattern] = signatures

probes = rows('probes.tsv')
measurements, errors = [], []
for case in sorted({r['case'] for r in probes}, key=int):
    voices = [r for r in probes if r['case'] == case]
    at = min(float(v['at']) for v in voices)+0.35
    audio = read(PROBE, 12, at-0.06, 0.12)
    observed = []
    for voice in voices:
        string, note = int(voice['string']), int(voice['note'])
        samples = audio[string*2::12]
        assert rms(samples) > 0.00001
        target = 440*2**((note-69)/12)
        actual = pitch(samples, target)
        cents = 1200*math.log2(actual/target)
        measured_note = round(69+12*math.log2(actual/440))
        assert measured_note == note and abs(cents) < 18, (case, note, cents)
        observed.append(measured_note)
        errors.append(abs(cents))
        measurements.append({'case': int(case), 'label': by_id[voice['change']]['label'], 'string': string,
                             'midi': note, 'waveform_hz': round(actual, 3), 'error_cents': round(cents, 3)})
    chord = by_id[voices[0]['change']]
    assert set(observed) == set(ints(chord['notes']))
    assert min(observed) == int(chord['bass'])
    for string in set(range(6))-{int(v['string']) for v in voices}:
        assert max(map(abs, audio[string*2::12])) < 0.00001

manifest = json.loads((FOLDER / 'manifest.json').read_text())
audio_results = {}
for spec in manifest['tracks']:
    path = ROOT / 'audio' / spec['file']
    data = read(path, 2)
    peak, level = max(map(abs, data)), rms(data)
    assert math.isfinite(peak) and math.isfinite(level)
    assert 0.01 < peak < 0.95 and level > 0.001
    assert max(map(abs, data[:round(0.08*48000)*2])) < 0.0001
    assert max(map(abs, data[-4800:])) < 0.0001
    with wave.open(str(path), 'rb') as f:
        assert abs(f.getnframes()/48000-spec['seconds']) < 0.003
    audio_results[spec['file']] = {'peak_dbfs': round(20*math.log10(peak), 2),
                                  'rms_dbfs': round(20*math.log10(level), 2)}

report = {'human_listening_review': 'pending', 'chord_shapes_checked': len(chords),
          'performed_string_events': len(events), 'root_position_movement_semitones': movement[0],
          'inverted_movement_semitones': movement[1], 'descending_bass_midi': descending,
          'rhythm_onsets_beats': rhythm, 'waveform_pitch_checks': len(measurements),
          'maximum_waveform_pitch_error_cents': round(max(errors), 3),
          'dry_string_measurements': measurements, 'audio': audio_results}
(FOLDER / 'verification.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps({k: v for k, v in report.items() if k not in ['dry_string_measurements', 'rhythm_onsets_beats']}, indent=2))
