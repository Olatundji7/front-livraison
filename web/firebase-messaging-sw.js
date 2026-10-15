importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAvIjK4Xj9KpvgZ_7UD7StCTZ-0gtWNhjo',
  authDomain: 'ma-livraison-43517.firebaseapp.com',
  projectId: 'ma-livraison-43517',
  storageBucket: 'ma-livraison-43517.firebasestorage.app',
  messagingSenderId: '1084690560866',
  appId: '1:1084690560866:web:4a4b6a048ccf827d50de3b'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'MA Livraison';
  const options = {
    body: payload.notification?.body || 'Vous avez une nouvelle notification.',
    icon: '/icons/Icon-192.png',
    data: payload.data || {}
  };

  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
