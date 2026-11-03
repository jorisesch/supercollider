"""Measure strum onset order, material spectra and independent double-stop pitch."""
import array
import csv
import json
import math
import statistics
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'infinite/experiments/dj/guitar-contact'
TEMP = [Path(tempfile.gettempdir()), Path.home() / 'Library/Application Support/SuperCollider/tmp', Path('/tmp')]
PROBE = next(p / 'rock-contact-probes.wav' for p in TEMP if (p / 'rock-contact-probes.wav').exists())


def read(path, channels, start=0, duration=None):
    with wave.open(str(path), 'rb') as f:
        assert (f.getframerate(), f.getnchannels(), f.getsampwidth()) == (48000, channels, 3)
        f.setpos(round(start*48000))
        raw = f.readframes(round(duration*48000) if duration else f.getnframes())
    return array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True)/8388608
                             for i in range(0, len(raw), 3)))


def rms(values):
    return math.sqrt(sum(x*x for x in values)/len(values))


def actual_pitch(values, expected):
    mean = statistics.mean(values)
    values = [x-mean for x in values]
    period = 48000/expected
    low, high = int(period*0.90), int(period*1.10)+1
    corr = {}
    for lag in range(low, high+1):
        a, b = values[:-lag], values[lag:]
        corr[lag] = sum(x*y for x, y in zip(a, b))/math.sqrt(sum(x*x for x in a)*sum(y*y for y in b))
    peak = max(range(low+1, high), key=corr.get)
    assert corr[peak] > 0.75
    l, m, r = [corr[peak+d] for d in (-1, 0, 1)]
    return 48000/(peak+0.5*(l-r)/(l-2*m+r))


def amplitude(values, hz):
    total = 0j
    for i, value in enumerate(values):
        window = 0.5-0.5*math.cos(2*math.pi*i/(len(values)-1))
        phase = -2*math.pi*hz*i/48000
        total += value*window*complex(math.cos(phase), math.sin(phase))
    return 4*abs(total)/len(values)


events = list(csv.DictReader((FOLDER / 'events.tsv').open(), delimiter='\t'))
probe_events = list(csv.DictReader((FOLDER / 'probes.tsv').open(), delimiter='\t'))
report = {'human_listening_review': 'pending', 'strums': {}, 'materials': {}, 'double_stop': {}, 'audio': {}}
for i, direction in enumerate(['down', 'up', 'simultaneous']):
    start = 0.1+i*2
    data = read(PROBE, 12, start-0.01, 1.3)
    onsets = []
    for string in range(6):
        voice = data[string*2::12]
        threshold = max(1e-6, max(map(abs, voice))*0.0001)
        at = next(j/48000 for j, value in enumerate(voice) if abs(value) > threshold)+start-0.01
        onsets.append(at)
    order = sorted(range(6), key=onsets.__getitem__)
    span = max(onsets)-min(onsets)
    if direction == 'simultaneous':
        assert span < 0.002, onsets
    else:
        assert order == (list(range(6)) if direction == 'down' else list(reversed(range(6)))), onsets
        assert 0.032 < span < 0.038, span
    report['strums'][direction] = {'string_order': order, 'sweep_ms': round(span*1000, 3),
                                   'onset_seconds': [round(t, 6) for t in onsets]}

length = 0.648*2**(-8/12)  # B string, eighth fret = G4
mass, diameter = 0.00068, 0.00033
ei = 200e9*math.pi*diameter**4/64
spectra, rows = {}, {}
for i, material in enumerate(['hard', 'angled', 'flexible', 'flesh', 'nail']):
    start = 6.1+i*2
    data = read(PROBE, 12, start, 1.25)
    row = next(r for r in probe_events if r['study'] == 'probe_material' and r['material'] == material)
    rows[material] = row
    center = round(0.28*48000)
    f0 = data[center*12+2]*2000
    measured = actual_pitch(data[(center-960)*12:(center+960)*12:12], f0)
    assert abs(1200*math.log2(measured/f0)) < 4
    tension = mass*(2*length*f0)**2-ei*math.pi**2/length**2
    b = ei*math.pi**2/(tension*length**2)
    frequencies = {n: n*f0*math.sqrt((1+b*n*n)/(1+b)) for n in range(1, 17)}
    window = data[round(0.14*48000)*12:round(0.42*48000)*12:12]
    magnitudes = {n: amplitude(window, frequencies[n]) for n in frequencies}
    assert min(magnitudes[n] for n in [1, 5, 8, 12]) > 1e-7
    spectra[material] = magnitudes
    centroid = sum(frequencies[n]*a*a for n, a in magnitudes.items())/sum(a*a for a in magnitudes.values())
    report['materials'][material] = {'actual_fundamental_hz': round(measured, 3),
        'modal_power_centroid_hz': round(centroid, 1), 'release_kernel_ms': float(row['release_kernel_ms'])}


def sinc(x):
    return math.sin(x)/x if abs(x) > 1e-9 else 1


errors = []
for material in ['angled', 'flexible', 'flesh', 'nail']:
    row, hard = rows[material], rows['hard']
    tau, tau_hard = [float(r['release_kernel_ms'])/1000 for r in (row, hard)]
    width, width_hard = [float(r['footprint_mm'])/1000 for r in (row, hard)]

    def expected_ratio(n):
        frequency = n*391.9954
        h = math.sqrt((1+(2*math.pi*frequency*tau_hard)**2)/(1+(2*math.pi*frequency*tau)**2))
        shape = sinc(n*math.pi*width/(2*length))/sinc(n*math.pi*width_hard/(2*length))
        return h*shape

    measured_changes = {}
    for n in (5, 8, 12):
        measured = 20*math.log10((spectra[material][n]/spectra[material][1]) /
                                (spectra['hard'][n]/spectra['hard'][1]))
        expected = 20*math.log10(expected_ratio(n)/expected_ratio(1))
        assert abs(measured-expected) < 0.25, (material, n, measured, expected)
        errors.append(abs(measured-expected))
        measured_changes[str(n)] = round(measured, 2)
    report['materials'][material]['upper_partial_change_db_vs_hard'] = measured_changes
assert report['materials']['flesh']['modal_power_centroid_hz'] < report['materials']['hard']['modal_power_centroid_hz']*0.75
report['maximum_release_spectrum_error_db'] = round(max(errors), 3)

data = read(PROBE, 12, 16.1, 1.6)
upper = [data[frame*12+6]*2000 for frame in range(round(0.05*48000), round(1.48*48000), 240)]
assert 1200*math.log2(max(upper)/min(upper)) < 1, 'Held double-stop partner followed the bend'
measurements = []
for at in [0.10, 0.40, 0.80, 1.25, 1.47]:
    center = round(at*48000)
    frequencies = []
    for audio, trace in [(0, 2), (4, 6)]:
        expected = data[center*12+trace]*2000
        actual = actual_pitch(data[(center-720)*12+audio:(center+720)*12:12], expected)
        assert abs(1200*math.log2(actual/expected)) < 20
        frequencies.append(actual)
    measurements.append({'seconds': at, 'bending_string_hz': round(frequencies[0], 2),
                          'held_partner_hz': round(frequencies[1], 2)})
assert measurements[0]['bending_string_hz'] < 450
assert abs(1200*math.log2(measurements[-1]['bending_string_hz']/measurements[-1]['held_partner_hz'])) < 4
report['double_stop'] = {'held_partner_pitch_span_cents': round(1200*math.log2(max(upper)/min(upper)), 4),
                        'waveform_pitch': measurements}

manifest = json.loads((FOLDER / 'manifest.json').read_text())
for spec in manifest['tracks']:
    path = ROOT / 'audio' / spec['file']
    data = read(path, 2)
    peak, level = max(map(abs, data)), rms(data)
    assert 0.01 < peak < 0.95 and level > 0.001
    assert max(map(abs, data[-4800:])) < 0.0001
    with wave.open(str(path), 'rb') as f:
        assert abs(f.getnframes()/48000-spec['seconds']) < 0.003
    report['audio'][spec['file']] = {'peak_dbfs': round(20*math.log10(peak), 2),
                                    'rms_dbfs': round(20*math.log10(level), 2)}
contact = read(ROOT / 'audio/rock-contact-study.wav', 2)
matched = []
for i in range(5):
    block = contact[round((30+i*6)*48000)*2:round((36+i*6)*48000)*2]
    matched.append(20*math.log10(rms(block)))
assert max(matched)-min(matched) < 0.2, matched
report['matched_contact_level_spread_db'] = round(max(matched)-min(matched), 4)
(FOLDER / 'verification.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report, indent=2))
