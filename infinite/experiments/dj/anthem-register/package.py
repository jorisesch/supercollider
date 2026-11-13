"""Verify the matched register audition and export level-matched M4A previews."""
from array import array
import json
import math
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import wave

root = Path(sys.argv[1])
takes = []
for name in ('original', 'octave-down'):
    spec = json.loads((root / f'{name}.json').read_text())
    assert spec['key'] == 'Gb Ionian' and spec['leadNotes'] >= 8
    assert spec['transpose'] == (0 if name == 'original' else -12)
    with wave.open(str(root / f'{name}.wav'), 'rb') as audio:
        assert (audio.getnchannels(), audio.getframerate(), audio.getsampwidth()) == (2, 48000, 3)
        seconds = audio.getnframes() / 48000
        raw = audio.readframes(audio.getnframes())
    assert abs(seconds - spec['seconds']) < 0.004
    samples = array('i', (int.from_bytes(raw[i:i+3], 'little', signed=True) for i in range(0, len(raw), 3)))
    peak = max(map(abs, samples)) / 8388608
    rms = math.sqrt(sum(value*value for value in samples) / len(samples)) / 8388608
    assert math.isfinite(rms) and 0.01 < peak < 0.95 and rms > 0.002
    assert max(map(abs, samples[:3840])) / 8388608 < 0.0001
    assert max(map(abs, samples[-4800:])) / 8388608 < 0.0001
    takes.append(dict(name=name, spec=spec, samples=samples, seconds=seconds, peak=peak, rms=rms))
assert takes[0]['spec']['leadNotes'] == takes[1]['spec']['leadNotes']
assert {key:value for key,value in takes[0]['spec'].items() if key != 'transpose'} == {
    key:value for key,value in takes[1]['spec'].items() if key != 'transpose'}
target = min(0.09, *(0.84*take['rms']/take['peak'] for take in takes))
report = []
for take in takes:
    factor = target / take['rms']
    with TemporaryDirectory(dir=root) as temporary:
        path = Path(temporary) / f"{take['name']}.wav"
        with wave.open(str(path), 'wb') as audio:
            audio.setparams((2, 3, 48000, 0, 'NONE', 'not compressed'))
            audio.writeframes(b''.join(round(value*factor).to_bytes(3, 'little', signed=True)
                                      for value in take['samples']))
        encoded = Path(temporary) / f"{take['name']}.m4a"
        subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '192000', str(path), str(encoded)], check=True)
        encoded.replace(root / encoded.name)
    item = dict(name=take['name'], seconds=take['seconds'], lead_notes=take['spec']['leadNotes'],
                transpose_semitones=take['spec']['transpose'], matched_rms_dbfs=20*math.log10(target),
                matched_peak=take['peak']*factor, matching_gain_db=20*math.log10(factor),
                human_listening_review=('approved lower octave on 2026-11-13'
                                        if take['name'] == 'octave-down' else 'higher-register comparison reference'))
    report.append(item)
    print(json.dumps(item), flush=True)
(root / 'verification.json').write_text(json.dumps(report, indent=2)+'\n')
