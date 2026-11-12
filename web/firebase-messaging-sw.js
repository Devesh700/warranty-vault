// Firebase Cloud Messaging Web Service Worker for WarrantyVault.
// Configuration parameters can be provided via registration URL query params
// so no API keys are hardcoded in source control.
/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

(function initMessagingWorker() {
  try {
    const params = new URLSearchParams(self.location.search || '');
    const apiKey = params.get('apiKey') || '';
    const projectId = params.get('projectId') || '';
    const messagingSenderId = params.get('messagingSenderId') || '';
    const appId = params.get('appId') || '';

    if (!apiKey || !projectId || !messagingSenderId || !appId) {
      return;
    }

    firebase.initializeApp({
      apiKey,
      projectId,
      messagingSenderId,
      appId,
      authDomain: params.get('authDomain') || undefined,
      storageBucket: params.get('storageBucket') || undefined,
    });

    const messaging = firebase.messaging();
    messaging.onBackgroundMessage((payload) => {
      const title =
        (payload.notification && payload.notification.title) ||
        (payload.data && payload.data.title) ||
        'WarrantyVault';
      const body =
        (payload.notification && payload.notification.body) ||
        (payload.data && payload.data.body) ||
        '';

      return self.registration.showNotification(title, {
        body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        data: payload.data || {},
      });
    });
  } catch (_) {
    // Graceful no-op when offline or unconfigured
  }
})();

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const data = (event.notification && event.notification.data) || {};
  const itemId = data.itemId ? String(data.itemId).trim() : '';
  const targetUrl = itemId ? `/item/${encodeURIComponent(itemId)}` : '/';

  event.waitUntil(
    self.clients
        .matchAll({ type: 'window', includeUncontrolled: true })
        .then((clientList) => {
          for (const client of clientList) {
            if ('focus' in client) {
              return client.focus();
            }
          }
          if (self.clients.openWindow) {
            return self.clients.openWindow(targetUrl);
          }
          return null;
        })
  );
});
