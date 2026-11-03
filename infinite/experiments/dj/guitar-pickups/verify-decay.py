"""Measure single-coil partial decay in the rendered, unmixed A3 probe."""

import array
import math
import sys
import wave

with wave.open(sys.argv[1], 'rb') as wav:
    rate = wav.getframerate()
    assert (rate, wav.getnchannels(), wav.getsampwidth()) == (48000, 2, 3)
    raw = wav.readframes(wav.getnframes())

# Take the left channel and decimate fourfold. The measured partials are below 2 kHz.
samples = array.array('d', (
    int.from_bytes(raw[i:i + 3], 'little', signed=True)
    for i in range(0, len(raw), 24)
))
probe_rate = rate // 4
window_length = round(0.24 * probe_rate)
hann = [0.5 - 0.5 * math.cos(2 * math.pi * i / (window_length - 1))
        for i in range(window_length)]


def partial_power(start_seconds, center_hz):
    """Find the local spectral peak, allowing for stiffness and slight pitch drift."""
    start = round(start_seconds * probe_rate)
    window = [value * weight for value, weight in
              zip(samples[start:start + window_length], hann)]
    peaks = []
    for detune_hz in range(-5, 17, 2):
        coefficient = 2 * math.cos(2 * math.pi * (center_hz + detune_hz) / probe_rate)
        previous = older = 0
        for value in window:
            next_value = value + coefficient * previous - older
            older, previous = previous, next_value
        peaks.append(previous**2 + older**2 - coefficient * previous * older)
    return max(1, *peaks)


partials = (1, 3, 6, 8)
rates = []
for note_start in (0.10, 4.60):
    rates.append([
        10 * math.log10(partial_power(note_start + 1.30, 220 * n)
                        / partial_power(note_start + 0.30, 220 * n))
        for n in partials
    ])

print('Partials 1, 3, 6, 8, measured in dB/s')
print('Earlier:', [round(x, 1) for x in rates[0]])
print('Revised:', [round(x, 1) for x in rates[1]])
assert rates[1][2] < rates[1][0] - 8, 'Revised sixth partial needs to fade faster than the fundamental'
assert rates[1][3] < rates[0][3] - 15, 'Revised eighth partial needs stronger damping'
