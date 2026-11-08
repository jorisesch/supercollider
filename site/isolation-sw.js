// GitHub Pages serves static files. Isolate this app's scope for threaded WASM.
self.addEventListener("install", (event) => event.waitUntil(self.skipWaiting()));
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));
self.addEventListener("fetch", (event) => {
  const { request } = event;
  if (!request.url.startsWith(self.registration.scope)
      || (request.cache === "only-if-cached" && request.mode !== "same-origin")) return;

  event.respondWith(fetch(request).then((response) => {
    if (!response.ok || response.status === 0) return response;
    const headers = new Headers(response.headers);
    headers.set("Cross-Origin-Opener-Policy", "same-origin");
    headers.set("Cross-Origin-Embedder-Policy", "require-corp");
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  }));
});
