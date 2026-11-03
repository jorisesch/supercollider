"""Prepare comparable listening levels and join the four harmony studies."""
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
        assert (f.getnchannels(), f.getsampwidth(), f.getframerate()) == (2, 3, 48000)
        return f.readframes(f.getnframes())


def write(name, raw):
    with wave.open(str(AUDIO / name), 'wb') as f:
        f.setparams((2, 3, 48000, 0, 'NONE', 'not compressed'))
        f.writeframes(raw)


tracks, segments, gains = [], [], {}
combined = bytearray()
studies = [('rock-triad-voicings', 'triads'), ('rock-chord-colors', 'extensions'),
           ('rock-slash-chords', 'slash chords'), ('rock-chord-phrasing', 'phrasing')]
for name, label in studies:
    raw = read(name+'-raw.wav')
    data = array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True)/8388608
                            for i in range(0, len(raw), 3)))
    level = math.sqrt(sum(x*x for x in data)/len(data))
    gain = min(10**(-23/20)/level, 0.85/max(map(abs, data)))
    gains[label] = gain
    listening = bytearray()
    for value in data:
        listening.extend(round(value*gain*8388608).to_bytes(3, 'little', signed=True))
    write(name+'.wav', listening)
    start, duration = len(combined)/6/48000, len(listening)/6/48000
    segments.append({'study': label, 'start_seconds': start, 'end_seconds': start+duration})
    tracks.extend([{'file': name+'.wav', 'preview': name+'.m4a', 'seconds': duration, 'study': label},
                   {'file': name+'-raw.wav', 'seconds': duration, 'study': 'raw render source'}])
    combined.extend(listening)
write('rock-harmony-comparison.wav', combined)
tracks.append({'file': 'rock-harmony-comparison.wav', 'preview': 'rock-harmony-comparison.m4a',
               'seconds': len(combined)/6/48000, 'study': 'combined'})
manifest = {'reference_commit': 'fa608b9', 'human_listening_review': 'pending', 'live_dj_changed': False,
            'tracks': tracks, 'comparison_segments': segments, 'listening_gains': gains,
            'triad_sections': ['A inversions', 'F#m inversions', 'root-position progression', 'voice-led progression'],
            'color_sections': ['A', 'Amaj7', 'A7', 'Am7', 'Aadd9', 'A9'],
            'slash_sections': ['A / A-C# / A-E', 'E pedal', 'descending bass', 'A-E resolving riff'],
            'phrasing_sections': ['block strums', 'syncopated stabs', 'bass and treble answers', 'arpeggios with anticipations']}
(FOLDER / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
print('Packaged triad, color, slash-chord and phrasing studies')
