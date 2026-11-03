"""Make raw/matched contact comparisons and concatenate the three hand studies."""
import array
import json
import math
import wave
from pathlib import Path

FOLDER = Path(__file__).resolve().parent
REPO = FOLDER.parents[3]
AUDIO = REPO / 'audio'


def read(name):
    with wave.open(str(AUDIO / name), 'rb') as f:
        assert (f.getnchannels(), f.getframerate(), f.getsampwidth()) == (2, 48000, 3)
        return f.readframes(f.getnframes())


def values(raw):
    return array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True)/8388608
                             for i in range(0, len(raw), 3)))


def write(name, raw):
    with wave.open(str(AUDIO / name), 'wb') as f:
        f.setparams((2, 3, 48000, 0, 'NONE', 'not compressed'))
        f.writeframes(raw)


def normalize(raw):
    data = values(raw)
    level = math.sqrt(sum(x*x for x in data)/len(data))
    gain = min(10**(-23/20)/level, 0.85/max(map(abs, data)))
    output = bytearray()
    for x in data:
        output.extend(round(x*gain*8388608).to_bytes(3, 'little', signed=True))
    return output, gain


raw = read('rock-contact-raw.wav')
block_bytes = 6*48000*6
reference = values(raw[:block_bytes])
target = math.sqrt(sum(x*x for x in reference)/len(reference))
matched = bytearray()
materials = ['hard', 'angled', 'flexible', 'flesh', 'nail']
gains = {}
for i, material in enumerate(materials):
    data = values(raw[i*block_bytes:(i+1)*block_bytes])
    level = math.sqrt(sum(x*x for x in data)/len(data))
    gain = min(target/level, 0.85/max(map(abs, data)))
    gains[material] = gain
    for x in data:
        matched.extend(round(x*gain*8388608).to_bytes(3, 'little', signed=True))
contact, contact_gain = normalize(raw[:5*block_bytes]+matched+bytes(round(0.5*48000)*6))
write('rock-contact-study.wav', contact)
gains_by_study = {'contact': contact_gain}
for name, kind in [('rock-strum', 'strumming'), ('rock-double-stops', 'double stops')]:
    pcm, gain = normalize(read(name+'-raw.wav'))
    write(name+('-study' if name == 'rock-strum' else '')+'.wav', pcm)
    gains_by_study[kind] = gain

tracks = []
segments = []
comparison = bytearray()
for name, kind in [('rock-strum-study', 'strumming'), ('rock-contact-study', 'contact'),
                   ('rock-double-stops', 'double stops')]:
    pcm = read(name+'.wav')
    start, duration = len(comparison)/6/48000, len(pcm)/6/48000
    segments.append({'study': kind, 'start_seconds': start, 'end_seconds': start+duration})
    tracks.append({'file': name+'.wav', 'preview': name+'.m4a', 'seconds': duration, 'study': kind})
    comparison.extend(pcm)
write('rock-hand-comparison.wav', comparison)
tracks.append({'file': 'rock-hand-comparison.wav', 'preview': 'rock-hand-comparison.m4a',
               'seconds': len(comparison)/6/48000, 'study': 'combined'})
for name in ['rock-strum-raw.wav', 'rock-contact-raw.wav', 'rock-double-stops-raw.wav']:
    tracks.append({'file': name, 'seconds': len(read(name))/6/48000, 'study': 'raw render source'})
manifest = {'reference_commit': 'fa608b9', 'human_listening_review': 'pending',
            'live_dj_changed': False, 'tracks': tracks, 'comparison_segments': segments,
            'contact_matched_gains': gains,
            'post_rig_listening_gains': gains_by_study,
            'strum_sections': ['simultaneous control', 'full downstrokes', 'full upstrokes',
                               'full down / treble up', 'slow rake / fast upstroke'],
            'contact_sections': materials,
            'double_stop_sections': ['picked thirds', 'finger-pinched sixths',
                                     'one string bends against held partner', 'short chops and ringing pairs']}
(FOLDER / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
print('Packaged strum, pick/finger and double-stop studies with raw/matched contact passes')
