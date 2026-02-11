const CACHE_NAME = 'apk-reverse-tool-v1';
const RUNTIME_CACHE_NAME = 'apk-reverse-tool-runtime-v1';

// Files to cache on install
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/offline.html',
  // Add other static assets as needed
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Installing Service Worker...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[Service Worker] Caching app shell');
        return cache.addAll(PRECACHE_URLS);
      })
      .catch((error) => {
        console.error('[Service Worker] Precache failed', error);
      })
  );
  
  // Force the waiting service worker to become the active service worker
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activating Service Worker...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== CACHE_NAME && cacheName !== RUNTIME_CACHE_NAME) {
              console.log('[Service Worker] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => {
        // Take control of all open clients
        return self.clients.claim();
      })
  );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Handle only same-origin requests
  if (url.origin !== location.origin) {
    // For API requests, don't cache
    if (url.pathname.startsWith('/api/')) {
      event.respondWith(
        fetch(request)
          .then((response) => {
            // Cache successful API responses
            if (response.ok) {
              const clonedResponse = response.clone();
              caches.open(RUNTIME_CACHE_NAME).then((cache) => {
                cache.put(request, clonedResponse);
              });
            }
            return response;
          })
          .catch(() => {
            // Try to serve from cache on network failure
            return caches.match(request);
          })
      );
      return;
    }
  }

  // For static resources and navigation requests, use cache-first strategy
  event.respondWith(
    caches.match(request)
      .then((cachedResponse) => {
        if (cachedResponse) {
          // Return cached response immediately
          return cachedResponse;
        }

        // No cache hit - fetch from network
        return fetch(request)
          .then((networkResponse) => {
            if (!networkResponse || !networkResponse.ok) {
              // Network response not valid
              throw new Error('Network response was not ok');
            }

            // Cache the response
            const clonedResponse = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(request, clonedResponse);
            });

            return networkResponse;
          })
          .catch((error) => {
            // Network request failed
            console.log('[Service Worker] Fetch failed:', error);

            // Check if it's a navigation request
            if (request.mode === 'navigate') {
              // Return offline page for navigation
              return caches.match('/offline.html');
            }

            // Return a generic error response
            return new Response('Network error occurred', {
              status: 503,
              statusText: 'Service Unavailable',
              headers: new Headers({
                'Content-Type': 'text/plain',
              }),
            });
          });
      })
  );
});

// Background sync event
self.addEventListener('sync', (event) => {
  console.log('[Service Worker] Background sync event:', event.tag);
  
  if (event.tag === 'sync-analyses') {
    event.waitUntil(syncAnalyses());
  }
});

// Push notification event
self.addEventListener('push', (event) => {
  const options = {
    body: event.data ? event.data.text() : 'Analysis completed',
    icon: '/icon-192.png',
    badge: '/badge-72.png',
    vibrate: [200, 100, 200],
    data: {
      dateOfArrival: Date.now(),
    },
    actions: [
      {
        action: 'explore',
        title: 'View Results',
      },
      {
        action: 'close',
        title: 'Close',
      },
    ],
  };

  event.waitUntil(
    self.registration.showNotification('APK Analysis Complete', options)
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  const action = event.action;
  const notification = event.notification;

  notification.close();

  if (action === 'explore') {
    // Navigate to results page
    event.waitUntil(
      self.clients.openWindow('/analysis/' + notification.data?.analysisId)
    );
  }
});

// Message event
self.addEventListener('message', (event) => {
  console.log('[Service Worker] Message received:', event.data);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  } else if (event.data && event.data.type === 'CACHE_URLS') {
    event.waitUntil(
      caches.open(CACHE_NAME).then((cache) => {
        return cache.addAll(event.data.urls);
      })
    );
  }
});

// Sync analyses from cache
function syncAnalyses() {
  return caches.open(RUNTIME_CACHE_NAME)
    .then((cache) => {
      return cache.keys();
    })
    .then((requests) => {
      return Promise.all(
        requests.map((request) => {
          return cache.match(request).then((response) => {
            return response?.json();
          });
        })
      );
    })
    .then((analyses) => {
      console.log('[Service Worker] Syncing analyses:', analyses.length);
      // Send analyses to server
      // This would integrate with an online sync service
      return Promise.resolve();
    })
    .catch((error) => {
      console.error('[script:worker:sync] Sync failed:', error);
      return Promise.reject(error);
    });
}

// Cache size helper
function getCacheSize(cacheName) {
  return caches.open(cacheName)
    .then((cache) => {
      return cache.keys().then((requests) => {
        return Promise.all(
          requests.map((request) => {
            return cache.match(request).then((response) => {
              return {
                url: request.url,
                size: response?.headers.get('content-length') || '0',
              };
            });
          })
        );
      });
    })
    .then((items) => {
      return items.reduce((total, item) => {
        return total + parseInt(item.size);
      }, 0);
    });
}

// Expose cache size for debugging
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'GET_CACHE_SIZE') {
    event.waitUntil(
      getCacheSize(CACHE_NAME)
        .then((size) => {
          event.ports[0].postMessage({ type: 'CACHE_SIZE', size });
        })
    );
  }
});