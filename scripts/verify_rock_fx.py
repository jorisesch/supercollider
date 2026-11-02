"""Compare effects/bypass renders: clean opening unchanged, later effects audible."""
import array
import math
import wave
from pathlib import Path

root = Path(__file__).resolve().parents[1]
for name, bpm, answer_bar in [('rock-ironwood', 102, 16), ('rock-green-room', 94, 12),
                              ('rock-open-road', 112, 12)]:
    def read(suffix):
        with wave.open(str(root / 'audio' / f'{name}{suffix}.wav'), 'rb') as wav:
            assert (wav.getframerate(), wav.getnchannels(), wav.getsampwidth()) == (48000, 2, 3)
            return wav.readframes(wav.getnframes())
    wet, dry = read(''), read('-base')
    assert len(wet) == len(dry)
    clean_end = int((0.1 + 8*4*60/bpm)*48000)*6
    assert wet[:clean_end] == dry[:clean_end], 'Clean opening was altered'
    start, end = [int((0.1 + bar*4*60/bpm)*48000)*6 for bar in (answer_bar, answer_bar+6)]
    a = array.array('d', (int.from_bytes(wet[i:i+3], 'little', signed=True)/8388608
                         for i in range(start, end, 3)))
    b = array.array('d', (int.from_bytes(dry[i:i+3], 'little', signed=True)/8388608
                         for i in range(start, end, 3)))
    change = math.sqrt(sum((x-y)**2 for x,y in zip(a,b)) / sum(y*y for y in b))
    assert change > 0.03, 'Selected effects are too small to measure'
    print(f'PASS: {name}: clean opening PCM-identical; effect-section difference/bypass RMS {change:.3f}')
