"""Compare rendered pickups to independently evaluated geometry and circuit."""
import cmath
import csv
import json
import math

from package import FOLDER, ROOT, RATE, probe_file, read, rms

with (FOLDER / 'presets.tsv').open() as f:
    presets = list(csv.DictReader(f, delimiter='\t'))
assert len(presets) == 5
manifest = json.loads((FOLDER / 'manifest.json').read_text())
report = {'human_listening_review': 'pending', 'circuit': {}, 'geometry': {}, 'hum': {}, 'audio': {}}


def sinusoid(values, frequency, window=False):
    rotation = cmath.exp(-2j*math.pi*frequency/RATE)
    phase, total = 1+0j, 0j
    length = len(values)
    for i, value in enumerate(values):
        w = 0.5-0.5*math.cos(2*math.pi*i/(length-1)) if window else 1
        total += value*phase*w
        phase *= rotation
    return total


def db(value):
    return 20*math.log10(abs(value))


def response(p, frequency, digital=True):
    # Independent impedance evaluation, without polynomial factorization.
    omega = 2*RATE*math.tan(math.pi*frequency/RATE) if digital else 2*math.pi*frequency
    s = 1j*omega
    r, l, cw, cc, rv, ra, rp, rt, ct = (float(p[k]) for k in
        ('rdc', 'leff', 'windingC', 'cableC', 'volumeR', 'ampR', 'lossR', 'toneR', 'toneC'))
    source = r+s*l
    load = 1/(1/rv+1/ra+1/rp+s*(cw+cc)+1/(rt+1/(s*ct)))
    return load/(source+load)


errors, phase_errors = [], []
for index, freq in enumerate([60, 110, 400, 1000, 1800, 2400, 3300, 4400, 6000, 10000]):
    raw = read(probe_file('rock-humbucker-circuit.wav'), 12, 0.4+index*0.85, 0.3)
    reference = sinusoid(raw[0::12], freq)
    for i, preset in enumerate(presets):
        actual = sinusoid(raw[(i+1)*2::12], freq)/reference
        expected = response(preset, freq)
        difference = actual/expected
        error, phase_error = abs(db(difference)), abs(math.degrees(cmath.phase(difference)))
        assert error < 0.15 and phase_error < 1.5, (preset['name'], freq, error, phase_error)
        errors.append(error)
        phase_errors.append(phase_error)
        report['circuit'].setdefault(preset['name'], []).append({'hz': freq, 'measured_db': round(db(actual), 3),
            'expected_db': round(db(expected), 3), 'phase_error_degrees': round(phase_error, 3)})
report['maximum_circuit_error_db'] = round(max(errors), 4)
report['maximum_circuit_phase_error_degrees'] = round(max(phase_errors), 4)

# G4 on the B string, vibration held at constant tension for this diagnostic.
length = 0.648*2**(-8/12)
f0 = 440*2**((67-69)/12)
mass = 0.00068
ei = 200e9*math.pi*0.00033**4/64
tension = mass*(2*length*f0)**2-ei*(math.pi/length)**2
stiffness = ei*math.pi**2/(tension*length**2)
raw = read(probe_file('rock-humbucker-spatial.wav'), 10, 0.20, 0.30)


def aperture(p, n):
    # Equivalent closed form for apertures wholly within this speaking length.
    k = n*math.pi/length
    w = float(p['width'])
    return sum(g*math.sin(k*x)*math.sin(k*w/2)/(k*w/2)
               for x, g in zip(map(float, p['centers'].split(',')), map(float, p['weights'].split(','))))


errors = []
for n in [1, 2, 5, 10, 17, 22, 23]:
    freq = n*f0*math.sqrt((1+stiffness*n*n)/(1+stiffness))
    reference = sinusoid(raw[0::10], freq, window=True)
    assert abs(reference) > 0.0001
    for i, preset in enumerate(presets[1:], 1):
        actual = sinusoid(raw[i*2::10], freq, window=True)/reference
        expected = aperture(preset, n)/aperture(presets[0], n)
        error = abs(db(actual/expected))
        # Also check sign: some upper modes flip, so magnitude alone is insufficient.
        assert error < 0.35 and abs(cmath.phase(actual/expected)) < 0.12, (preset['name'], n, error, actual, expected)
        errors.append(error)
        report['geometry'].setdefault(preset['name'], []).append({'mode': n, 'hz': round(freq, 2),
            'relative_level_db': round(db(actual), 3), 'predicted_db': round(db(expected), 3)})
report['maximum_spatial_error_db'] = round(max(errors), 4)
assert report['geometry']['Vintage series'][-1]['relative_level_db'] < -25
report['fundamental_hz'] = {}
for i, preset in enumerate(presets):
    values = raw[i*2::10]
    strengths = [abs(sinusoid(values, f0+offset, window=True)) for offset in range(-3, 4)]
    peak = max(range(7), key=strengths.__getitem__)
    assert 0 < peak < 6
    left, middle, right = strengths[peak-1:peak+2]
    frequency = f0+peak-3+0.5*(left-right)/(left-2*middle+right)
    assert abs(1200*math.log2(frequency/f0)) < 1
    report['fundamental_hz'][preset['name']] = round(frequency, 4)

for base, start in [(60, 0.22), (50, 1.02)]:
    raw = read(probe_file('rock-humbucker-hum.wav'), 12, start, 0.4)
    levels = [rms(raw[i*2::12]) for i in range(6)]
    assert levels[0] > 0.01 and levels[3] > 0.005
    assert max(levels[i] for i in [1, 2, 4]) < 1e-7
    residual = db(levels[5]/levels[3])
    assert abs(residual-db(0.03)) < 0.05
    report['hum'][str(base)] = {'balanced_series_parallel_and_hot_below_pcm_floor': True,
                                'three_percent_mismatch_db_relative_to_split': round(residual, 3)}

for track in manifest['tracks']:
    data = read(ROOT / 'audio' / track['file'], 2)
    peak, level = max(map(abs, data)), rms(data)
    assert abs(len(data)/2/RATE-track['seconds']) < 0.003
    assert 0.01 < peak < 0.95 and math.isfinite(level) and level > 0.001
    assert max(map(abs, data[:round(0.08*RATE)*2])) < 0.0001
    assert max(map(abs, data[-4800:])) < 0.0001
    report['audio'][track['file']] = {'peak_dbfs': round(db(peak), 2), 'rms_dbfs': round(db(level), 2)}
clean = read(ROOT / 'audio/rock-humbucker-clean.wav', 2)
levels = [db(rms(clean[i*10*RATE*2:(i+1)*10*RATE*2])) for i in range(5)]
assert max(levels)-min(levels) < 0.05, levels
report['clean_rms_spread_db'] = round(max(levels)-min(levels), 4)
baseline = manifest['sections'][0]
report['natural_level_change_db_vs_single'] = {
    p['pickup']: {path: round(p['unmatched_'+path+'_rms_dbfs']-baseline['unmatched_'+path+'_rms_dbfs'], 3)
                  for path in ['clean', 'drive']} for p in manifest['sections']}
assert report['natural_level_change_db_vs_single']['Hot series']['clean'] > 4
(FOLDER / 'verification.json').write_text(json.dumps(report, indent=2)+'\n')
print(f"PASS: 50 circuit measurements (max {max(phase_errors):.3f} degrees phase error), "
      f"28 spatial harmonic measurements (max {max(errors):.3f} dB error), "
      "50/60 Hz hum cancellation, comparable listening levels and audio format/headroom/tails.")
