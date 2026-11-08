const play = document.querySelector("#play");
const channel = document.querySelector("#channel");
const next = document.querySelector("#next");
const energy = document.querySelector("#energy");
const volume = document.querySelector("#volume");
const status = document.querySelector("#status");
const engineEvents = new EventTarget();
const runtime = new URL("./runtime/", import.meta.url);
const sources = new URL("./dj/", import.meta.url);
let language, audioContext, initialized, unlockAudio, latestTrack;
let state = "loading";

const repository = document.querySelector('meta[name="repository-url"]')?.content;
if (repository) {
  document.querySelectorAll("[data-repo-path]").forEach((link) => {
    const path = link.dataset.repoPath;
    link.href = path ? `${repository}/blob/main/${path}` : repository;
  });
}

function show(nextState, message) {
  state = nextState;
  document.body.dataset.playback = state;
  status.textContent = message;
  const playing = state === "playing";
  play.disabled = state === "loading" || state === "unavailable";
  channel.disabled = state === "loading";
  next.disabled = !playing;
  document.querySelector("#play-icon").textContent = playing ? "■" : "▶";
  document.querySelector("#play-label").textContent = playing ? "Stop" : state === "error" ? "Retry" : "Play";
  if (!playing) delete status.dataset.track;
}

async function response(url) {
  const result = await fetch(url);
  if (!result.ok) throw new Error(`Could not load ${url.pathname} (${result.status})`);
  return result;
}

function awaitEngine(name, timeout = 12000) {
  return new Promise((resolve, reject) => {
    function cleanup() {
      clearTimeout(timer);
      engineEvents.removeEventListener(name, complete);
      engineEvents.removeEventListener("error", fail);
    }
    function complete(event) {
      cleanup();
      resolve(event.detail);
    }
    function fail(event) {
      cleanup();
      reject(new Error(event.detail));
    }
    const timer = setTimeout(() => fail({ detail: "The audio engine did not respond in time." }), timeout);
    engineEvents.addEventListener(name, complete);
    engineEvents.addEventListener("error", fail);
  });
}

function reportError(error) {
  console.error(error);
  show("error", "Local audio couldn’t start. Retry to reload the player.");
}

function onLanguagePrint(message) {
  for (const line of message.split("\n")) {
    if (line.includes("Welcome to SuperCollider")) engineEvents.dispatchEvent(new Event("welcome"));
    const match = line.trim().match(/^WEB_DJ (\w+)(?: (.*))?$/);
    if (!match) {
      if (line.trim()) console.debug("[sclang]", line);
      continue;
    }
    const [, event, detail] = match;
    if (event === "track") {
      latestTrack = detail;
      if (state === "playing") {
        status.dataset.track = detail;
        status.textContent = detail;
      }
    }
    if (event === "error" && state === "playing") reportError(new Error(detail));
    engineEvents.dispatchEvent(new CustomEvent(event, { detail }));
  }
}

async function initialize() {
  const manifest = await (await response(new URL("manifest.json", sources))).json();
  const load = async (name) => {
    const { default: create } = await import(new URL(name, runtime));
    return create({ locateFile: (file) => new URL(file, runtime).href });
  };
  const [synth, lang, files] = await Promise.all([
    load("scsynth.js"),
    load("sclang.js"),
    Promise.all([...manifest.files, manifest.entry].map(async (name) => [
      name, new Uint8Array(await (await response(new URL(name, sources))).arrayBuffer()),
    ])),
  ]);
  language = lang;

  const directories = new Set();
  for (const [name, contents] of files) {
    const separator = name.lastIndexOf("/");
    const folder = name.slice(0, separator);
    if (!directories.has(folder)) {
      lang.FS_createPath("/", folder, true, true);
      directories.add(folder);
    }
    lang.FS_createDataFile(`/${folder}`, name.slice(separator + 1), contents, true, false, true);
  }

  const pending = [];
  let driverReady = false;
  lang.onOsc = (packet) => {
    if (driverReady) synth.sendOsc(packet);
    else pending.push(new Uint8Array(packet));
  };
  synth.onOscReply = (reply) => lang.sendOsc(reply);
  synth.onPrint = (line) => console.debug("[scsynth]", line);
  lang.printCallback = onLanguagePrint;
  lang.printErrCallback = (line) => console.error("[sclang]", line);

  // The sclang WASM Server.boot bridge calls this instead of starting an OS process.
  window.bootServer = (options) => {
    setTimeout(() => {
      try {
        synth.boot(options);
        const started = performance.now();
        const check = setInterval(() => {
          const context = synth.getAudioContext();
          if (context && context !== audioContext) {
            audioContext = context;
            if (context.state === "suspended") {
              context.resume().catch(() => {});
              setTimeout(() => {
                if (context.state === "suspended" && state === "loading") {
                  unlockAudio = () => context.resume();
                  show("unlock", "Press Play to enable audio.");
                }
              }, 500);
            }
          }
          if (synth.scsynthIsReady()) {
            driverReady = true;
            pending.splice(0).forEach((packet) => synth.sendOsc(packet));
            clearInterval(check);
          } else if (performance.now() - started > 18000) {
            clearInterval(check);
            engineEvents.dispatchEvent(new CustomEvent("error", { detail: "Web Audio did not initialize." }));
          }
        }, 25);
      } catch (error) {
        engineEvents.dispatchEvent(new CustomEvent("error", { detail: error.message }));
      }
    }, 0);
  };

  const welcome = awaitEngine("welcome", 25000);
  lang.bootInterpreter();
  await welcome;
  const interpreter = awaitEngine("interpreter", 10000);
  const probe = setInterval(() => lang.runCode('"WEB_DJ interpreter".postln;'), 125);
  try {
    await interpreter;
  } finally {
    clearInterval(probe);
  }
  const ready = awaitEngine("ready", 35000);
  lang.runCode(`"/${manifest.entry}".load;`);
  await ready;
}

function control(name, slider) {
  language?.runCode(`~${name}.value(${(Number(slider.value) / 100).toFixed(3)});`);
}

async function start() {
  const selected = channel.value;
  show("loading", initialized ? "Starting set…" : "Loading SuperCollider…");
  try {
    initialized ??= initialize();
    await initialized;
    if (audioContext?.state === "suspended") {
      const resume = audioContext.resume();
      const resumed = await Promise.race([resume.then(() => true), new Promise((resolve) => setTimeout(() => resolve(false), 400))]);
      if (!resumed) {
        unlockAudio = start;
        show("unlock", "Press Play to enable audio.");
        return;
      }
    }
    control("webEnergy", energy);
    control("webVolume", volume);
    const seed = (crypto.getRandomValues(new Uint32Array(1))[0] % 2147483646) + 1;
    latestTrack = null;
    const playing = awaitEngine("playing");
    language.runCode(`~webStart.value(${seed}, '${selected}');`);
    await playing;
    show("playing", latestTrack || channel.selectedOptions[0].text);
    if (latestTrack) status.dataset.track = latestTrack;
  } catch (error) {
    reportError(error);
  }
}

play.addEventListener("click", async () => {
  if (state === "error") {
    location.reload();
  } else if (state === "unlock") {
    const resume = unlockAudio;
    unlockAudio = null;
    show("loading", "Starting local audio…");
    try {
      await resume();
    } catch (error) {
      reportError(error);
    }
  } else if (state === "playing") {
    show("loading", "Stopping…");
    try {
      const stopped = awaitEngine("stopped");
      language.runCode("~webStop.value;");
      await stopped;
      show("idle", "Ready to play.");
    } catch (error) {
      reportError(error);
    }
  } else {
    await start();
  }
});
channel.addEventListener("change", () => {
  if (state === "playing") void start();
});
next.addEventListener("click", () => {
  if (channel.value === "soundscape") {
    void start();
  } else {
    status.textContent = "Next queued";
    language.runCode("~webNext.value;");
  }
});
for (const [name, slider] of [["webEnergy", energy], ["webVolume", volume]]) {
  slider.addEventListener("input", () => {
    if (state === "playing") control(name, slider);
  });
}

async function enablePlayer() {
  if (crossOriginIsolated && typeof AudioWorkletNode !== "undefined") {
    sessionStorage.removeItem("infinite-dj-isolation");
    show("idle", "Ready to play.");
    return;
  }
  if (!isSecureContext || !navigator.serviceWorker || sessionStorage.getItem("infinite-dj-isolation")) {
    show("unavailable", "This browser couldn’t enable local audio. Try opening the page directly in a current browser.");
    return;
  }
  try {
    const controller = new Promise((resolve) => {
      navigator.serviceWorker.addEventListener("controllerchange", resolve, { once: true });
    });
    await navigator.serviceWorker.register(new URL("./isolation-sw.js", import.meta.url));
    if (!navigator.serviceWorker.controller) {
      await Promise.race([controller, new Promise((_, reject) => setTimeout(() => reject(new Error("Isolation timed out")), 8000))]);
    }
    sessionStorage.setItem("infinite-dj-isolation", "1");
    location.reload();
  } catch (error) {
    console.error(error);
    show("unavailable", "This browser couldn’t enable local audio. Try opening the page directly in a current browser.");
  }
}

void enablePlayer();
