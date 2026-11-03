"""Split the paired render; match clean levels, preserve drive differences."""
import array
import json
import math
import tempfile
import wave
from pathlib import Path

FOLDER = Path(__file__).resolve().parent
ROOT = FOLDER.parents[3]
RATE = 48000
NAMES = ['Single coil', 'Vintage series', 'Vintage parallel', 'Vintage split', 'Hot series']


def probe_file(name):
    dirs = [Path(tempfile.gettempdir()), Path.home() / 'Library/Application Support/SuperCollider/tmp']
    return next(p / name for p in dirs if (p / name).exists())


def read(path, channels, start=0, seconds=None):
    with wave.open(str(path), 'rb') as f:
        assert (f.getframerate(), f.getnchannels(), f.getsampwidth()) == (RATE, channels, 3)
        f.setpos(round(start*RATE))
        raw = f.readframes(round(seconds*RATE) if seconds is not None else f.getnframes())
    return array.array('d', (int.from_bytes(raw[i:i+3], 'little', signed=True)/8388608
                             for i in range(0, len(raw), 3)))


def rms(values):
    return math.sqrt(sum(x*x for x in values)/len(values))


def pack(values, gain):
    return b''.join(round(x*gain*8388608).to_bytes(3, 'little', signed=True) for x in values)


def write(name, raw):
    with wave.open(str(ROOT / 'audio' / (name+'.wav')), 'wb') as f:
        f.setparams((2, 3, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes(raw)


def main():
    samples = read(probe_file('rock-humbucker-raw.wav'), 4)
    assert abs(len(samples)/4/RATE-50.5) < 0.003
    clean = array.array('d')
    clean[::] = array.array('d', (x for i, x in enumerate(samples) if i % 4 < 2))
    drive = array.array('d', (x for i, x in enumerate(samples) if i % 4 >= 2))
    clean_raw, blocks = bytearray(), []
    span = 10*RATE*2
    target = 10**(-24/20)
    for i, name in enumerate(NAMES):
        a, b = i*span, (i+1)*span
        clean_block, drive_block = clean[a:b], drive[a:b]
        clean_level, drive_level = rms(clean_block), rms(drive_block)
        gain = min(target/clean_level, 0.85/max(map(abs, clean_block)))
        clean_raw.extend(pack(clean_block, gain))
        blocks.append({'pickup': name, 'start_seconds': 10*i,
                       'clean_gain': gain, 'unmatched_clean_rms_dbfs': round(20*math.log10(clean_level), 3),
                       'unmatched_drive_rms_dbfs': round(20*math.log10(drive_level), 3)})
    clean_raw.extend(pack(clean[5*span:], blocks[-1]['clean_gain']))
    drive_gain = min(target/rms(drive), 0.85/max(map(abs, drive)))
    drive_raw = pack(drive, drive_gain)
    tracks = [('rock-humbucker-clean', clean_raw, 'Clean level-matched pickups'),
              ('rock-humbucker-drive', drive_raw, 'Same overdrive, natural pickup levels'),
              ('rock-humbucker-comparison', clean_raw+drive_raw, 'Clean then overdriven comparison')]
    specs = []
    for name, raw, title in tracks:
        write(name, raw)
        specs.append({'file': name+'.wav', 'preview': name+'.m4a', 'seconds': len(raw)/6/RATE, 'title': title})
    manifest = {'human_listening_review': 'pending', 'live_dj_changed': False, 'tracks': specs,
                'clean_start_seconds': 0, 'drive_start_seconds': len(clean_raw)/6/RATE,
                'drive_gain': drive_gain, 'sections': blocks}
    (FOLDER / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('Packaged level-matched clean and natural-level overdrive comparisons.')


if __name__ == '__main__':
    main()
