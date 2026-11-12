"""Verify rendered audition WAVs and package a local listening and rating page."""
from html import escape
import json
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory
import wave

out = Path(sys.argv[1])
number, _, revision = (sys.argv[2] if len(sys.argv) > 2 else '01').partition('-')
round_number = f'{int(number):02}'
if revision:
    if not revision.isascii() or not revision.isalpha():
        raise SystemExit('The optional revision must contain letters only.')
    round_number += f'-{revision}'
rows = []
recipes = []
verification = {}
channels = {'edme': 'EDM', 'pop': 'Pop', 'rock': 'Rock', 'dubstep': 'London Dubstep'}
for recipe_file in sorted(out.glob('[A-Z].json')):
    recipe = json.loads(recipe_file.read_text())
    track_id = recipe['id']
    wav = out / recipe['file']
    m4a = wav.with_suffix('.m4a')
    recipes.append(recipe)
    with wave.open(str(wav)) as audio:
        assert (audio.getnchannels(), audio.getframerate(), audio.getsampwidth()) == (2, 48000, 3)
        seconds = audio.getnframes() / 48000
        assert abs(seconds - recipe['seconds']) < 0.03
        samples = audio.readframes(audio.getnframes())
    peak = 0
    energy = 0
    for offset in range(0, len(samples), 3):
        sample = int.from_bytes(samples[offset:offset+3], 'little', signed=True)
        peak = max(peak, abs(sample))
        energy += sample * sample
    peak /= 8388608
    rms = (energy / (len(samples) // 3)) ** 0.5 / 8388608
    assert 0.01 < peak < 0.95 and 0.002 < rms < 0.5, (track_id, peak, rms)
    edge_frames = 1920
    start_peak = max(abs(int.from_bytes(samples[i:i+3], 'little', signed=True))
                     for i in range(0, edge_frames * 6, 3)) / 8388608
    end_peak = max(abs(int.from_bytes(samples[i:i+3], 'little', signed=True))
                   for i in range(len(samples) - edge_frames * 6, len(samples), 3)) / 8388608
    assert start_peak < 0.0001 and end_peak < 0.0001, (track_id, start_peak, end_peak)
    verification[track_id] = dict(seconds=seconds, sample_rate=48000, channels=2,
                                  peak=peak, rms=rms, start_peak=start_peak, end_peak=end_peak,
                                  human_listening_review="pending")
    # A valid WAV can still be padded with silence after a scheduling error.
    tail_offset = max(0, round((seconds - 4) * 48000) * 6)
    tail_peak = max(abs(int.from_bytes(samples[i:i+3], 'little', signed=True))
                    for i in range(tail_offset, len(samples), 12)) / 8388608
    assert tail_peak > 0.002, f'{track_id} loses the music before its closing bars'
    print(f"{track_id} {seconds:.1f}s peak={peak:.3f} RMS={rms:.3f} {recipe['keyName']} {recipe['sections']}", flush=True)
    # Tame unusually loud previews for comparison while keeping the WAV masters intact.
    with TemporaryDirectory(dir=out) as temporary:
        source = wav
        if rms > 0.12:
            gain = 0.12 / rms
            source = Path(temporary) / 'preview.wav'
            leveled = b''.join(round(int.from_bytes(samples[i:i+3], 'little', signed=True) * gain)
                               .to_bytes(3, 'little', signed=True) for i in range(0, len(samples), 3))
            with wave.open(str(source), 'wb') as preview:
                preview.setparams((2, 3, 48000, 0, 'NONE', 'not compressed'))
                preview.writeframes(leveled)
        encoded = Path(temporary) / m4a.name
        subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '160000', str(source), str(encoded)], check=True)
        encoded.replace(m4a)
    details = f"{channels[recipe['channel']]} · {recipe['bpm']} BPM · {recipe['keyName']} · {recipe['paletteName']}"
    if round_number == '01':
        details += f" · {recipe['energy']:.0%} Energy"
    rows.append(f'''<section data-track="{track_id}">
      <h2>{track_id} · {escape(recipe['name'])}</h2>
      <p>{escape(details)}</p>
      <audio controls preload="none" src="{track_id}.m4a" aria-label="{escape(recipe['name'])}"></audio>
      <div class="votes">
        <button type="button" data-vote="up" aria-pressed="false">👍 Approve</button>
        <button type="button" data-vote="down" aria-pressed="false">👎 Pass</button>
      </div>
      <label>What stood out?<input type="text" maxlength="300" placeholder="Optional"></label>
    </section>''')

if not recipes:
    raise SystemExit('No rendered audition recipes found.')

template = '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Infinite DJ · Listening round __ROUND__</title>
<style>
:root {color-scheme:dark;background:#0c141a;color:#e9f0f0;font:16px/1.5 system-ui,sans-serif}
body {max-width:44rem;margin:0 auto;padding:2rem 1rem 3rem}
h1,h2,p {margin:0} h1 {font-size:clamp(2rem,7vw,3rem);line-height:1.05}
header p,section p {color:#aac0c6;margin-top:.35rem}
header {margin-bottom:1rem} section {border-bottom:1px solid #355058;padding:1rem 0}
h2 {font-size:1.1rem} audio {display:block;width:100%;margin:.6rem 0}
.votes {display:flex;gap:.5rem;flex-wrap:wrap}
button,input,textarea {font:inherit;color:inherit;background:#192a31;border:1px solid #617980;border-radius:.4rem;padding:.4rem .6rem}
button {cursor:pointer} button[aria-pressed="true"] {background:#a9ede3;color:#122421}
label {display:block;margin-top:.5rem;color:#aac0c6}
input,textarea {box-sizing:border-box;width:100%;display:block}
footer {margin-top:1.25rem}
textarea {margin-top:.65rem;min-height:4rem}
</style>
</head>
<body>
<header>
<h1>Infinite DJ listening round __ROUND__</h1>
<p>Play any excerpt, rate it, and add an optional note. __INTRO__Share the feedback summary in the chat when you’re done.</p>
</header>
<main>
__ROWS__
</main>
<footer>
<button type="button" id="copy">Copy feedback</button>
<button type="button" id="export">Save ratings with recipes</button>
<p id="status" role="status"></p>
<textarea id="summary" readonly aria-label="Feedback summary"></textarea>
</footer>
<script>
const recipes = __RECIPES__;
const round = "infinite-dj-listening-__ROUND__";
const ratings = {};
try { Object.assign(ratings, JSON.parse(localStorage.getItem(round) || "{}")); } catch {}
const summary = document.querySelector("#summary");
const status = document.querySelector("#status");
function sync() {
  try { localStorage.setItem(round, JSON.stringify(ratings)); } catch {}
  const lines = recipes.flatMap(({id}) => {
    const entry = ratings[id];
    if (!entry?.vote && !entry?.note?.trim()) return [];
    const vote = entry.vote === "up" ? "👍" : entry.vote === "down" ? "👎" : "";
    return [[id, vote, entry.note?.trim()].filter(Boolean).join(" ")];
  });
  summary.value = lines.length ? ["Infinite DJ listening round __ROUND__", ...lines].join("\\n") : "";
}
for (const track of document.querySelectorAll("[data-track]")) {
  const id = track.dataset.track;
  const entry = ratings[id] ??= {};
  const buttons = track.querySelectorAll("[data-vote]");
  const note = track.querySelector("input");
  note.value = entry.note || "";
  const showVote = () => buttons.forEach(button => {
    button.setAttribute("aria-pressed", String(button.dataset.vote === entry.vote));
  });
  showVote();
  for (const button of buttons) {
    button.onclick = () => {
      entry.vote = entry.vote === button.dataset.vote ? null : button.dataset.vote;
      showVote();
      sync();
    };
  }
  note.oninput = () => { entry.note = note.value; sync(); };
}
for (const audio of document.querySelectorAll("audio")) {
  audio.onplay = () => document.querySelectorAll("audio").forEach(other => {
    if (other !== audio) other.pause();
  });
}
document.querySelector("#copy").onclick = async () => {
  if (!summary.value) { status.textContent = "Rate a track or write a note first."; return; }
  summary.focus();
  summary.select();
  try {
    await navigator.clipboard.writeText(summary.value);
    status.textContent = "Copied. Paste the summary into the chat.";
  } catch { status.textContent = "Feedback selected. Copy it and paste it into the chat."; }
};
document.querySelector("#export").onclick = () => {
  const results = recipes.filter(({id}) => ratings[id]?.vote || ratings[id]?.note?.trim())
    .map(recipe => ({recipe, ...ratings[recipe.id]}));
  if (!results.length) { status.textContent = "Rate a track or write a note first."; return; }
  const url = URL.createObjectURL(new Blob([JSON.stringify({round, results}, null, 2)], {type:"application/json"}));
  const link = Object.assign(document.createElement("a"), {href:url, download:round + "-ratings.json"});
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
};
sync();
</script>
</body>
</html>
'''
intro = 'A is the Wired House reference. ' if round_number == '01' else ''
(out / 'listen.html').write_text(template.replace('__ROUND__', round_number).replace('__INTRO__', intro)
                                 .replace('__ROWS__', '\n'.join(rows)).replace('__RECIPES__', json.dumps(recipes)))

(out / 'verification.json').write_text(json.dumps(verification, indent=2) + '\n')
