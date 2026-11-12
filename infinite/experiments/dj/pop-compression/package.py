"""Verify compression gain, match comparison levels and package a local listening page."""
from array import array
from html import escape
import json
import math
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import wave

root = Path(sys.argv[1])
takes = []
config_path = root / 'comparison.json'
config = json.loads(config_path.read_text()) if config_path.exists() else {}
title = config.get('title', 'Pop compression')
recipes = [json.loads((root / f'{track}.json').read_text()) for track in config.get('tracks', ('F', 'G'))]
version_ids = [version['id'] for version in recipes[0]['versions']]
version_labels = dict(zip(version_ids, (('A · Uncompressed', 'B · Previous EDM', 'C · Gentle', 'D · Stronger')
                      if 'current' in version_ids else ('A · Uncompressed', 'B · Gentle', 'C · Stronger'))))
for recipe in recipes:
    for version in recipe['versions']:
        name = f"{recipe['id']}-{version['id']}"
        with wave.open(str(root / f'{name}-analysis.wav'), 'rb') as wav:
            assert (wav.getnchannels(), wav.getframerate(), wav.getsampwidth()) == (3, 48000, 3)
            seconds = wav.getnframes() / 48000
            assert abs(seconds - (recipe['seconds'] + 0.05)) < 0.004
            raw = wav.readframes(wav.getnframes())
        audio = array('i')
        gains = []
        for i in range(0, len(raw), 9):
            left = int.from_bytes(raw[i:i+3], 'little', signed=True)
            right = int.from_bytes(raw[i+3:i+6], 'little', signed=True)
            audio.extend((left, right))
            if max(abs(left), abs(right)) > 1600:
                gains.append(int.from_bytes(raw[i+6:i+9], 'little', signed=True) / 4194304)
        peak = max(map(abs, audio)) / 8388608
        rms = math.sqrt(sum(s*s for s in audio) / len(audio)) / 8388608
        assert 0.005 < peak < 0.95 and rms > 0.002, (name, peak, rms)
        assert gains and all(math.isfinite(g) and 0 < g <= 1.00001 for g in gains), name
        gains.sort()
        reduction = -20 * math.log10(gains[0])
        median_reduction = -20 * math.log10(gains[len(gains)//2])
        if version['id'] == 'dry':
            assert reduction < 0.001, name
            with wave.open(str(root / f"{recipe['id']}-mix.wav"), 'rb') as source:
                source_bytes = source.readframes(source.getnframes())
            original = array('i', (int.from_bytes(source_bytes[i:i+3], 'little', signed=True)
                                   for i in range(0, len(source_bytes), 3)))
            source_onset = next(i for i, sample in enumerate(original) if abs(sample) > 1600)
            result_onset = next(i for i, sample in enumerate(audio) if abs(sample) > 1600)
            offset = result_onset - source_onset
            assert offset >= 0 and offset % 2 == 0, name
            shared = min(len(original), len(audio)-offset)
            assert max(abs(a-b) for a,b in zip(original[:shared], audio[offset:offset+shared])) <= 2, \
                f'{name} did not preserve the original waveform'
        elif version['id'] != 'current':
            assert reduction > 0.25, f'{name} did not apply measurable compression'
        last_music = round((recipe['seconds'] - 4) * 48000) * 2
        assert max(abs(s) for s in audio[last_music:last_music+96000]) / 8388608 > 0.003, name
        takes.append(dict(name=name, samples=audio, peak=peak, rms=rms, seconds=seconds,
                          max_reduction_db=reduction, median_reduction_db=median_reduction))
target_rms = min(0.09, *(0.84*take['rms']/take['peak'] for take in takes))
report = {'rms_target_dbfs': 20*math.log10(target_rms), 'takes': []}
for take in takes:
    factor = target_rms / take['rms']
    samples = b''.join(round(s*factor).to_bytes(3, 'little', signed=True) for s in take['samples'])
    wav_path = root / f"{take['name']}.wav"
    with wave.open(str(wav_path), 'wb') as wav:
        wav.setparams((2, 3, 48000, 0, 'NONE', 'not compressed'))
        wav.writeframes(samples)
    with TemporaryDirectory(dir=root) as temp:
        encoded = Path(temp) / f"{take['name']}.m4a"
        subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '160000',
                        str(wav_path), str(encoded)], check=True)
        encoded.replace(root / encoded.name)
    item = {key:value for key,value in take.items() if key != 'samples'}
    item['matched_peak'] = take['peak'] * factor
    item['gain_db'] = 20*math.log10(factor)
    report['takes'].append(item)
    print(f"{take['name']} {take['seconds']:.1f}s, reduction peak {take['max_reduction_db']:.1f} dB, "
          f"median {take['median_reduction_db']:.1f} dB, matched peak {item['matched_peak']:.3f}", flush=True)
(root / 'verification.json').write_text(json.dumps(report, indent=2)+'\n')
sections = []
for recipe in recipes:
    track = recipe['id']
    buttons = ''.join(f'<button type="button" data-version="{version}" aria-pressed="{str(i == 0).lower()}">{escape(version_labels[version])}</button>'
                      for i, version in enumerate(version_ids))
    choices = ''.join(f'<option>{escape(version_labels[version])}</option>' for version in version_ids)
    sections.append(f'''<section data-track="{track}">
<h2>{escape(recipe['name'])}</h2>
<p>{recipe['bpm']} BPM · same performance for all {len(version_ids)} versions</p>
<audio controls preload="none" src="{track}-dry.m4a"></audio>
<div class="versions">
{buttons}
</div>
<label>Your preference<select><option value="">Choose after listening</option>
{choices}<option>No preference</option></select></label>
<label>Notes<input maxlength="300" placeholder="Optional"></label>
</section>''')

html = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Infinite DJ · __TITLE__ comparison</title>
<style>
:root{color-scheme:dark;background:#0c141a;color:#e9f0f0;font:16px/1.5 system-ui,sans-serif}
body{max-width:48rem;margin:auto;padding:2rem 1rem}
h1{font-size:clamp(2rem,6vw,2.8rem);line-height:1.1}
h1,h2,p{margin:.5rem 0}p,label{color:#acc1c6}
section{padding:1rem 0 1.5rem;border-bottom:1px solid #355058}
h2{font-size:1.25rem}audio{width:100%;margin:.5rem 0}
.versions{display:flex;flex-wrap:wrap;gap:.5rem}
button,select,input,textarea{font:inherit;color:inherit;background:#192a31;border:1px solid #617980;border-radius:.4rem;padding:.5rem}
button{cursor:pointer}button[aria-pressed=true]{color:#122421;background:#a9ede3}
label{display:block;margin-top:.7rem}select,input,textarea{width:100%;box-sizing:border-box;display:block}
footer{padding:1rem 0}textarea{min-height:5rem;margin-top:.7rem}
</style></head><body>
<h1>__TITLE__</h1>
<p>Switch versions while listening. The player keeps your position. All versions have matched average levels.</p>
<p>__INTRO__</p>
__SECTIONS__
<footer><button id="copy" type="button">Copy feedback</button><p id="status" role="status"></p>
<textarea readonly id="summary" aria-label="Feedback summary"></textarea></footer>
<script>
const key = __STORAGE_KEY__;
let feedback = {};
try { feedback = JSON.parse(localStorage.getItem(key) || "{}"); } catch {}
function update() {
  try { localStorage.setItem(key, JSON.stringify(feedback)); } catch {}
  const lines = [__FEEDBACK_TITLE__];
  document.querySelectorAll("[data-track]").forEach(section => {
    const entry = feedback[section.dataset.track];
    if (entry?.preference || entry?.note?.trim())
      lines.push([section.querySelector("h2").textContent, entry.preference, entry.note].filter(Boolean).join(" · "));
  });
  document.querySelector("#summary").value = lines.length > 1 ? lines.join("\\n") : "";
}
for (const section of document.querySelectorAll("[data-track]")) {
  const id = section.dataset.track;
  const audio = section.querySelector("audio");
  let version = "dry", desiredTime = 0;
  const buttons = section.querySelectorAll("[data-version]");
  audio.addEventListener("loadedmetadata", () => {
    audio.currentTime = Math.min(desiredTime, Math.max(0, audio.duration - 0.05));
  });
  audio.addEventListener("play", () => {
    document.querySelectorAll("audio").forEach(other => { if (other !== audio) other.pause(); });
  });
  buttons.forEach(button => {
    button.onclick = () => {
      if (button.dataset.version === version) return;
      if (audio.readyState >= 1) desiredTime = audio.currentTime;
      const resume = !audio.paused;
      version = button.dataset.version;
      audio.src = id + "-" + version + ".m4a";
      buttons.forEach(item => item.setAttribute("aria-pressed", String(item === button)));
      if (resume) audio.play().catch(() => {
        document.querySelector("#status").textContent = "Press Play to continue the comparison.";
      });
    };
  });
  const preference = section.querySelector("select"), note = section.querySelector("input");
  preference.value = feedback[id]?.preference || "";
  note.value = feedback[id]?.note || "";
  const save = () => { feedback[id] = {preference:preference.value, note:note.value}; update(); };
  preference.onchange = save;
  note.oninput = save;
}
document.querySelector("#copy").onclick = async () => {
  const summary = document.querySelector("#summary");
  if (!summary.value) return;
  summary.focus(); summary.select();
  try {
    await navigator.clipboard.writeText(summary.value);
    document.querySelector("#status").textContent = "Copied. Paste the feedback in the chat.";
  } catch { document.querySelector("#status").textContent = "Copy the selected feedback and paste it in the chat."; }
};
update();
</script></body></html>
'''
intro = config.get('intro', 'A has the mix-bus compressor bypassed. B adds gentle compression. C uses a stronger setting. The deck’s existing kick ducking is present in all three.')
html = (html.replace('__SECTIONS__', '\n'.join(sections)).replace('__TITLE__', escape(title))
        .replace('__INTRO__', escape(intro)).replace('__STORAGE_KEY__', json.dumps(config.get('storageKey', 'infinite-dj-pop-compression-01')))
        .replace('__FEEDBACK_TITLE__', json.dumps('Infinite DJ ' + title)))
(root / 'listen.html').write_text(html)
