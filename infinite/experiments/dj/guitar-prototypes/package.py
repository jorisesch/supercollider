"""Concatenate the four rendered PCM studies and write their portable manifest."""
import json
import wave
from pathlib import Path

FOLDER = Path(__file__).resolve().parent
REPO = FOLDER.parents[3]
profiles = ['reference', 'restrained', 'loose', 'urgent']
tracks, segments, frames = [], [], 0
with wave.open(str(REPO / 'audio/rock-phrasing-comparison.wav'), 'wb') as output:
    output.setparams((2, 3, 48000, 0, 'NONE', 'not compressed'))
    for profile in profiles:
        name = f'rock-phrasing-{profile}'
        with wave.open(str(REPO / 'audio' / f'{name}.wav'), 'rb') as source:
            assert (source.getnchannels(), source.getsampwidth(), source.getframerate()) == (2, 3, 48000)
            count = source.getnframes()
            assert abs(count/48000-22.1) < 0.003
            output.writeframes(source.readframes(count))
        tracks.append({'file': name+'.wav', 'preview': name+'.m4a',
                       'seconds': count/48000, 'profile': profile})
        segments.append({'profile': profile, 'start_seconds': frames/48000,
                         'end_seconds': (frames+count)/48000})
        frames += count
tracks.append({'file': 'rock-phrasing-comparison.wav', 'preview': 'rock-phrasing-comparison.m4a',
               'seconds': frames/48000, 'profile': 'comparison'})
manifest = {'reference_commit': 'fa608b9', 'bpm': 96, 'seed': 731,
            'phrase_beats': 32, 'common_listening_gain': 2.5, 'human_listening_review': 'pending',
            'live_dj_changed': False, 'tracks': tracks, 'comparison_segments': segments}
(FOLDER / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
print('Packaged four phrasing studies and comparison')
