const play = document.querySelector("#play");
const channel = document.querySelector("#channel");
const next = document.querySelector("#next");
const energy = document.querySelector("#energy");
const status = document.querySelector("#status");
const engineEvents = new EventTarget();
const runtime = new URL("./runtime/", import.meta.url);
const manifestURL = new URL("./dj/manifest.json", import.meta.url);
const pageVersion = new URL(import.meta.url).searchParams.get("v");
const appVersion = "__INFINITE_DJ_RELEASE__";
const runtimeVersion = "__INFINITE_DJ_RUNTIME__";
manifestURL.searchParams.set("v", appVersion);
const releaseSettingsKey = "infinite-dj-release-settings";
let recovery = new URL(location.href).searchParams.get("retry");
let language, audioContext, initialized, unlockAudio, latestTrack;
let state = "loading";

class StartupError extends Error {}
class DownloadError extends StartupError {}
let retryDownload = false;

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
  channel.disabled = state === "loading" || state === "unlock" || state === "resume";
  next.disabled = !playing;
  document.querySelector("#play-icon").textContent = playing ? "■" : "▶";
  const label = { playing: "Stop", error: "Retry", unlock: "Enable audio", resume: "Resume audio" };
  document.querySelector("#play-label").textContent = label[state] ?? "Play";
  if (!playing) delete status.dataset.track;
}

async function download(url, read, cache = "default") {
  for (let attempt = 0; ; attempt += 1) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 45000);
    try {
      const result = await fetch(url, {
        signal: controller.signal,
        cache: recovery || attempt ? "reload" : cache,
      });
      if (!result.ok) throw new Error(`Could not load ${url.pathname} (${result.status})`);
      return await read(result);
    } catch (error) {
      if (attempt === 1) throw error;
    } finally {
      clearTimeout(timer);
    }
    await new Promise((resolve) => setTimeout(resolve, 600));
  }
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
  retryDownload = error instanceof DownloadError;
  const message = error instanceof StartupError ? error.message : "The set couldn’t start or respond.";
  const action = retryDownload ? "Tap Retry to download again." : "Tap Retry to restart the player.";
  show("error", `${message} ${action}`);
}

async function startupStep(message, action, Failure = StartupError) {
  try {
    return await action();
  } catch (error) {
    throw new Failure(message, { cause: error });
  }
}

async function loadWithTimeout(promise) {
  let timer;
  try {
    return await Promise.race([
      promise,
      new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error("The runtime did not respond in time.")), 45000);
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}

function runtimeFailed(name) {
  const message = name === "scsynth" ? "The audio engine stopped unexpectedly." : "The language runtime stopped unexpectedly.";
  engineEvents.dispatchEvent(new CustomEvent("error", { detail: message }));
  if (state === "playing" || state === "resume" || state === "unlock") {
    reportError(new StartupError(message));
  }
}

async function resumeAudio() {
  const context = audioContext;
  let timer;
  try {
    await Promise.race([
      context.resume(),
      new Promise((resolve) => { timer = setTimeout(resolve, 500); }),
    ]);
  } catch (error) {
    if (context.state === "closed") throw error;
  } finally {
    clearTimeout(timer);
  }
  return context.state === "running";
}

async function audioClockIsRunning() {
  const before = audioContext.currentTime;
  await new Promise((resolve) => setTimeout(resolve, 350));
  return audioContext.state === "running" && audioContext.currentTime > before;
}

function showPlaying() {
  show("playing", latestTrack || channel.selectedOptions[0].text);
  if (latestTrack) status.dataset.track = latestTrack;
}

function promptForAudio(onRunning) {
  unlockAudio = async () => {
    // Call resume from the tap itself so Safari can use the user activation.
    if (await resumeAudio()) await onRunning();
    else promptForAudio(onRunning);
  };
  show("unlock", "Tap Enable audio to start playback.");
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

function refreshRelease(update) {
  const url = new URL(location.href);
  if (url.searchParams.get("update") === update) {
    throw new StartupError("The latest player files are still out of sync.");
  }
  try {
    sessionStorage.setItem(releaseSettingsKey, JSON.stringify({ channel: channel.value, energy: energy.value }));
  } catch (error) {
    console.debug("Could not carry settings across the refresh", error);
  }
  show("loading", "Updating the player…");
  url.searchParams.set("update", update);
  location.replace(url);
  return false;
}

async function initialize() {
  if (pageVersion !== appVersion) return refreshRelease(appVersion);
  const runtimeURL = (name) => {
    const url = new URL(name, runtime);
    url.searchParams.set("v", runtimeVersion);
    return url;
  };
  const binary = (name) => download(runtimeURL(name), (result) => result.arrayBuffer());
  const prepare = async (name) => {
    const moduleURL = runtimeURL(`${name}.js`);
    if (recovery) moduleURL.searchParams.set("retry", recovery);
    const [{ default: create }, wasm, data] = await Promise.all([
      loadWithTimeout(import(moduleURL)),
      binary(`${name}.wasm`),
      name === "sclang" ? binary("sclang.data") : null,
    ]);
    return () => loadWithTimeout(create({
      locateFile: (file) => file === `${name}.js` ? moduleURL.href : runtimeURL(file).href,
      mainScriptUrlOrBlob: moduleURL.href,
      wasmBinary: new Uint8Array(wasm),
      onAbort: () => runtimeFailed(name),
      printErr: (line) => {
        console.error(`[${name}]`, line);
        if (String(line).includes("worker sent an error!")) runtimeFailed(name);
      },
      ...(data ? { getPreloadedPackage: () => data } : {}),
    }));
  };
  // Start no workers until all downloads succeed, so a failed fetch can be retried in this tab.
  const [createSynth, createLang, manifest] = await Promise.all([
    startupStep("Couldn’t download the audio engine.", () => prepare("scsynth"), DownloadError),
    startupStep("Couldn’t download the language runtime.", () => prepare("sclang"), DownloadError),
    startupStep("Couldn’t download the music sources.", () => download(manifestURL, (result) => result.json(), "no-cache"), DownloadError),
  ]);
  if (manifest.version !== appVersion) return refreshRelease(manifest.version || "latest");
  status.textContent = "Starting SuperCollider…";
  const [synth, lang] = await Promise.all([
    startupStep("Couldn’t initialize the audio engine.", createSynth),
    startupStep("Couldn’t initialize the language runtime.", createLang),
  ]);
  language = lang;

  const directories = new Set();
  const encoder = new TextEncoder();
  for (const [name, contents] of Object.entries(manifest.sources)) {
    const separator = name.lastIndexOf("/");
    const folder = name.slice(0, separator);
    if (!directories.has(folder)) {
      lang.FS_createPath("/", folder, true, true);
      directories.add(folder);
    }
    lang.FS_createDataFile(`/${folder}`, name.slice(separator + 1), encoder.encode(contents), true, false, true);
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
          const context = synth.getWebAudioContext();
          if (context && context !== audioContext) {
            audioContext = context;
            if (context.state !== "running") {
              context.resume().catch(() => {});
              setTimeout(() => {
                if (context.state !== "running" && state === "loading") {
                  promptForAudio(() => {});
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

  await startupStep("The SuperCollider language runtime didn’t start.", async () => {
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
  });
  status.textContent = "Connecting to browser audio…";
  await startupStep("SuperCollider couldn’t connect to browser audio.", async () => {
    const ready = awaitEngine("ready", 35000);
    lang.runCode(`"/${manifest.entry}".load;`);
    await ready;
  });
  return true;
}

function setEnergy() {
  language.runCode(`~webEnergy.value(${(Number(energy.value) / 100).toFixed(3)});`);
}

async function start() {
  const selected = channel.value;
  show("loading", initialized ? "Starting set…" : "Downloading SuperCollider…");
  try {
    initialized ??= initialize();
    if (!await initialized) return;
    if (audioContext && audioContext.state !== "running" && !await resumeAudio()) {
      promptForAudio(start);
      return;
    }
    setEnergy();
    const seed = (crypto.getRandomValues(new Uint32Array(1))[0] % 2147483646) + 1;
    latestTrack = null;
    const playing = awaitEngine("playing");
    language.runCode(`~webStart.value(${seed}, '${selected}');`);
    await playing;
    showPlaying();
  } catch (error) {
    reportError(error);
  }
}

play.addEventListener("click", async () => {
  if (state === "error") {
    recovery = String(Date.now());
    if (retryDownload) {
      initialized = null;
      await start();
    } else {
      const url = new URL(location.href);
      url.searchParams.set("retry", recovery);
      location.replace(url);
    }
  } else if (state === "resume") {
    show("loading", "Resuming browser audio…");
    try {
      if (!await resumeAudio() || !await audioClockIsRunning()) {
        throw new StartupError("Browser audio stayed paused.");
      }
      showPlaying();
    } catch (error) {
      reportError(error);
    }
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
document.addEventListener("visibilitychange", async () => {
  if (document.hidden || state !== "playing" || !audioContext) return;
  const running = await audioClockIsRunning();
  if (!document.hidden && state === "playing" && !running) {
    show("resume", "Playback paused while the page was in the background.");
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
energy.addEventListener("input", () => {
  if (state === "playing") setEnergy();
});

async function enablePlayer() {
  if (crossOriginIsolated && typeof AudioWorkletNode !== "undefined") {
    sessionStorage.removeItem("infinite-dj-isolation");
    try {
      const settings = JSON.parse(sessionStorage.getItem(releaseSettingsKey));
      sessionStorage.removeItem(releaseSettingsKey);
      if (settings && Array.from(channel.options).some((option) => option.value === settings.channel)) {
        channel.value = settings.channel;
        energy.value = settings.energy;
      }
    } catch (error) {
      console.debug("Could not restore player settings", error);
    }
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
