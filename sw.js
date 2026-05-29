const CACHE = 'beachflow-v17-cause-engine';
const asset = path => new URL(path, self.registration.scope).toString();
const ASSETS = [
  asset('./'),
  asset('./index.html'),
  asset('./confirmacao-aula.html'),
  asset('./supabase-config.js'),
  asset('./beachflow-pedagogy-ontology.js'),
  asset('./beachflow-diagnostic-cause-engine.js'),
  asset('./manifest.webmanifest'),
  asset('./icons/icon-192.png'),
  asset('./icons/icon-512.png')
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE)
      .then(c => c.addAll(ASSETS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  if (e.request.url.includes('supabase.co')) {
    e.respondWith(fetch(e.request));
    return;
  }
  if (e.request.mode === 'navigate' || e.request.url.endsWith('/index.html') || e.request.url.includes('/confirmacao-aula.html')) {
    e.respondWith(
      fetch(e.request)
        .then(response => {
          const copy = response.clone();
          caches.open(CACHE).then(cache => cache.put(e.request, copy));
          return response;
        })
        .catch(() => caches.match(e.request).then(cached => cached || caches.match(asset('./index.html'))))
    );
    return;
  }
  e.respondWith(
    caches.match(e.request).then(cached => {
      const network = fetch(e.request).then(response => {
        if (response.ok) caches.open(CACHE).then(cache => cache.put(e.request, response.clone()));
        return response;
      });
      return cached || network;
    })
  );
});
