"""Independent PCM checks of string mechanics, diode KCL and guitar-only routing.

Run rock-physical-render.scd first. Numerical checks are not a listening review.
Uses only the Python standard library.
"""
import array
import json
import math
import statistics
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDERS = [Path(tempfile.gettempdir()),
           Path.home() / 'Library/Application Support/SuperCollider/tmp', Path('/tmp')]


def read(path, channels):
    with wave.open(str(path), 'rb') as f:
        assert (f.getframerate(), f.getnchannels(), f.getsampwidth()) == (48000, channels, 3)
        raw = f.readframes(f.getnframes())
    return array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True) / 8388608
                             for i in range(0, len(raw), 3)))


def probe(name, channels):
    return read(next(p / name for p in FOLDERS if (p / name).exists()), channels)


def rms(values):
    return math.sqrt(sum(x*x for x in values) / len(values))


pitch = probe('rock-physical-pitch.wav', 6)
report = {}
for i, name in enumerate(['plain', 'bend_return', 'bend_arrival', 'vibrato', 'fretted_slide']):
    start = 0.1 + i*3.4

    def trace(at, channel=2, scale=2000):
        return pitch[int((start+at)*48000)*6+channel]*scale

    def actual(at):
        center = int((start+at)*48000)
        samples = pitch[(center-1200)*6:(center+1200)*6:6]
        mean = statistics.mean(samples)
        samples = [x-mean for x in samples]
        assert rms(samples) > 0.0001, 'Silent physical string'
        # Search a register around the expected note, then estimate the period
        # from waveform correlation, independent of the synth's pitch detector.
        period = 48000/trace(at)
        low, high = int(period*0.92), int(period*1.08)+1
        corr = {}
        for lag in range(low, high+1):
            a, b = samples[:-lag], samples[lag:]
            corr[lag] = sum(x*y for x,y in zip(a,b)) / math.sqrt(sum(x*x for x in a)*sum(x*x for x in b))
        peak = max(range(low+1, high), key=corr.get)
        assert corr[peak] > 0.75, 'Unreliable string periodicity'
        l, m, r = [corr[peak+d] for d in (-1, 0, 1)]
        return 48000/(peak+0.5*(l-r)/(l-2*m+r))

    times = [0.3+j*0.08 for j in range(31)]
    errors = [1200*math.log2(actual(t)/trace(t)) for t in times]
    # Moving gestures curve within the 50 ms correlation window; exclude fret
    # crossings from this accuracy bound, but check their settled output below.
    if name != 'fretted_slide':
        assert max(map(abs, errors)) < 22, (name, errors)
    end = actual(2.75)
    assert abs(1200*math.log2(end/440)) < 16, (name, end)
    if name == 'bend_return':
        assert 487 < trace(1.3) < 497 and 438 < trace(2.7) < 442
        # Bent frets stay fixed: the pitch rise must come from added tension.
        assert abs(trace(0.2, 3, 32)-trace(1.3, 3, 32)) < 0.002
        assert trace(1.3, 4, 200) > trace(0.2, 4, 200)*1.20
    elif name == 'bend_arrival':
        assert 388 < trace(0.01) < 397 and 437 < trace(1.3) < 442
    elif name == 'vibrato':
        values = [trace(0.9+j*0.01) for j in range(100)]
        assert min(values) > 439 and 25 < 1200*math.log2(max(values)/min(values)) < 50
    elif name == 'fretted_slide':
        values = [trace(0.03+j*0.04, 3, 32) for j in range(14)]
        assert len(set(round(v) for v in values)) >= 4, 'Slide skipped intermediate frets'
        assert 328 < trace(0.01) < 335 and 437 < trace(1.0) < 445
    report[name] = {'max_pitch_error_cents': round(max(map(abs, errors)), 2),
                    'ending_hz': round(end, 2)}

strip = probe('rock-physical-strip.wav', 8)
assert strip[:int(4.2*48000)*8:8] == strip[2:int(4.2*48000)*8:8], 'Rig changed bass/drums left'
assert strip[1:int(4.2*48000)*8:8] == strip[3:int(4.2*48000)*8:8], 'Rig changed bass/drums right'
# Independently solve Shockley's equation with bisection, then check the actual
# root UGen and ADAA samples against that reference, not another SC control trace.
offset = int(4.7*48000)
errors = []
for frame in range(offset, offset+4800, 7):
    x = strip[frame*8+4]*8
    low, high = -2.0, 2.0
    for _ in range(48):
        y = (low+high)/2
        if y+2200*5.04e-9*math.sinh(y/0.045) > x:
            high = y
        else:
            low = y
    errors.append(abs(strip[frame*8+6]-(low+high)/2))
assert max(errors) < 0.0001, max(errors)
report['diode_root_max_error_volts'] = max(errors)


def root_and_integral(x):
    a, thermal = 2200*5.04e-9, 0.045
    low, high = -2.0, 2.0
    for _ in range(48):
        y = (low+high)/2
        if y+a*math.sinh(y/thermal) > x:
            high = y
        else:
            low = y
    y = (low+high)/2
    integral = 0.5*y*y+a*(y*math.sinh(y/thermal)-thermal*(math.cosh(y/thermal)-1))
    return y, integral


adaa_errors = []
for frame in range(offset, offset+4800, 17):
    x, previous = [strip[f*8+4]*8 for f in (frame, frame-1)]
    y, integral = root_and_integral(x)
    old_y, old_integral = root_and_integral(previous)
    expected = ((integral-old_integral)/(x-previous) if abs(x-previous) >= 0.0002
                else (y+old_y)/2)
    adaa_errors.append(abs(expected-strip[frame*8+5]))
assert max(adaa_errors) < 0.001, max(adaa_errors)
report['adaa_max_error_volts'] = max(adaa_errors)


def amplitude(values, hz):
    return 2*abs(sum(x*complex(math.cos(2*math.pi*hz*i/48000),
                              -math.sin(2*math.pi*hz*i/48000))
                     for i, x in enumerate(values)))/len(values)


start, end = int(5.9*48000), int(6.1*48000)
aa, raw = [strip[start*8+c:end*8:8] for c in (5, 6)]
alias_reduction = 20*math.log10((amplitude(raw, 16500)/amplitude(raw, 6300)) /
                              (amplitude(aa, 16500)/amplitude(aa, 6300)))
assert alias_reduction > 4, alias_reduction
report['fifth_harmonic_alias_reduction_db'] = round(alias_reduction, 2)
start, end = int(7.1*48000), int(7.3*48000)
joined, separate = [strip[start*8+c:end*8:8] for c in (5, 6)]
interaction = rms([a-b for a, b in zip(joined, separate)])/rms(joined)
assert interaction > 0.1, 'Chord bypassed the shared nonlinear stage'
assert amplitude(joined, 110) > amplitude(separate, 110)*10, 'Missing chord intermodulation'
report['shared_chord_interaction_relative_rms'] = round(interaction, 3)
source = strip[offset*8+4:(offset+4800)*8:8]
compressed = strip[offset*8+7:(offset+4800)*8:8]
assert 0.20 < rms(compressed)/rms(source) < 0.75, 'Compressor did not reduce the hot signal'
report['compressor_gain'] = round(rms(compressed)/rms(source), 4)
report['bass_drums_pcm_identical'] = True

study = read(ROOT / 'audio/rock-guitar-study.wav', 2)
assert max(map(abs, study)) < 0.95 and rms(study) > 0.005
assert max(map(abs, study[-4800:])) < 0.0001
report['study_peak_dbfs'] = round(20*math.log10(max(map(abs, study))), 2)
report['human_listening_review'] = 'pending'
print(json.dumps(report, indent=2))
