#!/usr/bin/env python3
"""Generate placeholder WAV audio files for all Tickeys sound schemes."""

import struct
import math
import os
import random

SAMPLE_RATE = 44100

def write_wav(filename, samples, sample_rate=SAMPLE_RATE):
    """Write 16-bit mono WAV file."""
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    num_samples = len(samples)
    data_size = num_samples * 2

    with open(filename, 'wb') as f:
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))
        f.write(struct.pack('<H', 1))      # PCM
        f.write(struct.pack('<H', 1))      # mono
        f.write(struct.pack('<I', sample_rate))
        f.write(struct.pack('<I', sample_rate * 2))
        f.write(struct.pack('<H', 2))      # block align
        f.write(struct.pack('<H', 16))     # bits per sample
        f.write(b'data')
        f.write(struct.pack('<I', data_size))
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            f.write(struct.pack('<h', int(clamped * 32767)))

def gen_click(freq=800, duration=0.04, volume=0.6, decay=40):
    """Generate a short click/tap sound."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * decay) * volume
        # Mix fundamental with a noise burst
        sig = math.sin(2 * math.pi * freq * t) * 0.7
        sig += (random.random() * 2 - 1) * 0.3 * math.exp(-t * 80)
        samples.append(sig * env)
    return samples

def gen_bubble(freq=600, duration=0.08, volume=0.5):
    """Generate a bubble/pop sound with pitch drop."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 20) * volume
        # Descending frequency
        f = freq * (1.0 - t * 3)
        if f < 100: f = 100
        sig = math.sin(2 * math.pi * f * t)
        samples.append(sig * env)
    return samples

def gen_typewriter_key(freq=1200, duration=0.05, volume=0.5):
    """Generate a typewriter key press sound."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 50) * volume
        sig = math.sin(2 * math.pi * freq * t) * 0.4
        sig += (random.random() * 2 - 1) * 0.6 * math.exp(-t * 100)
        samples.append(sig * env)
    return samples

def gen_typewriter_return(duration=0.15, volume=0.6):
    """Generate a typewriter carriage return sound."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 12) * volume
        sig = math.sin(2 * math.pi * 400 * t) * 0.3
        sig += math.sin(2 * math.pi * 200 * t) * 0.3
        sig += (random.random() * 2 - 1) * 0.4 * math.exp(-t * 20)
        samples.append(sig * env)
    return samples

def gen_mechanical(freq=2000, duration=0.03, volume=0.5):
    """Generate a mechanical keyboard click."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 80) * volume
        sig = math.sin(2 * math.pi * freq * t) * 0.3
        sig += (random.random() * 2 - 1) * 0.7 * math.exp(-t * 120)
        samples.append(sig * env)
    return samples

def gen_sword(freq=300, duration=0.12, volume=0.5):
    """Generate a sword swoosh sound."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = (1 - math.exp(-t * 30)) * math.exp(-t * 10) * volume
        f = freq + 1500 * math.exp(-t * 15)
        sig = math.sin(2 * math.pi * f * t) * 0.3
        sig += (random.random() * 2 - 1) * 0.7 * env
        samples.append(sig * env)
    return samples

def gen_drum(freq=150, duration=0.1, volume=0.6):
    """Generate a drum hit sound."""
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 15) * volume
        f = freq * (1 + 2 * math.exp(-t * 40))
        sig = math.sin(2 * math.pi * f * t) * 0.7
        sig += (random.random() * 2 - 1) * 0.3 * math.exp(-t * 50)
        samples.append(sig * env)
    return samples

def main():
    base = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        '..', 'Sources', 'Tickeys', 'Resources', 'data')
    base = os.path.normpath(base)
    print(f"Generating audio files in: {base}")

    random.seed(42)  # Reproducible

    # Bubble scheme
    for i in range(1, 9):
        freq = 400 + i * 80
        write_wav(f"{base}/bubble/{i}.wav", gen_bubble(freq=freq))
    write_wav(f"{base}/bubble/enter.wav", gen_bubble(freq=300, duration=0.12))

    # Typewriter scheme
    for i in range(1, 6):
        freq = 1000 + i * 100
        write_wav(f"{base}/typewriter/key-new-0{i}.wav", gen_typewriter_key(freq=freq))
    write_wav(f"{base}/typewriter/space.wav", gen_typewriter_key(freq=800, duration=0.06))
    write_wav(f"{base}/typewriter/scroll-up.wav", gen_click(freq=1500, duration=0.03))
    write_wav(f"{base}/typewriter/scroll-down.wav", gen_click(freq=1000, duration=0.03))
    write_wav(f"{base}/typewriter/backspace.wav", gen_typewriter_key(freq=600, duration=0.04))
    write_wav(f"{base}/typewriter/return.wav", gen_typewriter_return())

    # Mechanical scheme
    for i in range(1, 6):
        freq = 1800 + i * 150
        write_wav(f"{base}/mechanical/{i}.wav", gen_mechanical(freq=freq))
    write_wav(f"{base}/mechanical/enter.wav", gen_mechanical(freq=1200, duration=0.05))

    # Sword scheme
    for i in range(1, 6):
        freq = 200 + i * 50
        write_wav(f"{base}/sword/{i}.wav", gen_sword(freq=freq))
    write_wav(f"{base}/sword/enter.wav", gen_sword(freq=150, duration=0.18))

    # Drum scheme
    for i in range(1, 7):
        freq = 80 + i * 30
        write_wav(f"{base}/drum/{i}.wav", gen_drum(freq=freq))
    write_wav(f"{base}/drum/enter.wav", gen_drum(freq=60, duration=0.15))

    # Cherry G80-3000
    for i in range(1, 6):
        freq = 2200 + i * 100
        write_wav(f"{base}/Cherry_G80_3000/{i}.wav", gen_mechanical(freq=freq, duration=0.025))
    write_wav(f"{base}/Cherry_G80_3000/enter.wav", gen_mechanical(freq=1800, duration=0.04))

    # Cherry G80-3494
    for i in range(1, 6):
        freq = 2500 + i * 80
        write_wav(f"{base}/Cherry_G80_3494/{i}.wav", gen_mechanical(freq=freq, duration=0.028))
    write_wav(f"{base}/Cherry_G80_3494/enter.wav", gen_mechanical(freq=2000, duration=0.045))

    print("Done! All placeholder audio files generated.")
    print("To use original Tickeys audio, copy WAV files from:")
    print("  /Applications/Tickeys.app/Contents/Resources/data/")

if __name__ == '__main__':
    main()
