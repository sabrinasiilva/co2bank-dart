// Service worker do push do CO2Bank (Firebase Cloud Messaging) na versão web.
// Ele mostra o alerta do limite de CO2 mesmo com a aba do app fechada.
//
// Fica na pasta firebase/ (e não na raiz do web/, como no exemplo do FlutterFire)
// para ter um escopo só dele: na raiz, ele brigaria com o flutter_service_worker.js
// pelo mesmo escopo e um ficaria substituindo o outro a cada abertura do site.
//
// PREENCHER: copie os valores de `web` do lib/firebase_options.dart gerado pelo
// `flutterfire configure` (passo a passo em docs/FIREBASE.md). Enquanto estiver
// com os placeholders abaixo, o app não usa este arquivo (o push fica desligado).
//
// A versão das bibliotecas é a mesma que o firebase_core_web usa
// (supportedFirebaseJsSdkVersion). Ao atualizar o firebase_core, confira.
importScripts('https://www.gstatic.com/firebasejs/13.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'PREENCHER_API_KEY',
  appId: 'PREENCHER_APP_ID',
  messagingSenderId: 'PREENCHER_MESSAGING_SENDER_ID',
  projectId: 'PREENCHER_PROJECT_ID',
  authDomain: 'PREENCHER_PROJECT_ID.firebaseapp.com',
  storageBucket: 'PREENCHER_PROJECT_ID.firebasestorage.app',
});

const messaging = firebase.messaging();

// Mensagens com `notification` o próprio Firebase mostra. Esta parte cobre as
// que chegam só com `data` (texto em data.body ou data.message).
messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const dados = payload.data || {};
  const texto = dados.body || dados.message || dados.mensagem;
  if (!texto) return;
  return self.registration.showNotification(
    dados.title || 'Atenção ao seu limite de CO2',
    { body: texto, icon: '../icons/Icon-192.png' },
  );
});

// Tocar na notificação abre (ou traz para frente) o app.
self.addEventListener('notificationclick', (evento) => {
  evento.notification.close();
  evento.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((abas) => {
      for (const aba of abas) {
        if ('focus' in aba) return aba.focus();
      }
      // O escopo é .../firebase/; o app fica uma pasta acima.
      return clients.openWindow(new URL('..', self.registration.scope).href);
    }),
  );
});
