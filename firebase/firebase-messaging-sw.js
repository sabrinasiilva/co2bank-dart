// Service worker do push do CO2Bank (Firebase Cloud Messaging) na versão web.
// Ele mostra o alerta do limite de CO2 mesmo com a aba do app fechada.
//
// Fica na pasta firebase/ (e não na raiz do web/, como no exemplo do FlutterFire)
// para ter um escopo só dele: na raiz, ele brigaria com o flutter_service_worker.js
// pelo mesmo escopo e um ficaria substituindo o outro a cada abertura do site.
//
// Os valores abaixo são os mesmos de `web` em lib/firebase_options.dart (gerado
// pelo `flutterfire configure`). Se rodar o configure de novo, atualize aqui.
// São dados de app cliente, não são segredo.
//
// A versão das bibliotecas é a mesma que o firebase_core_web usa
// (supportedFirebaseJsSdkVersion). Ao atualizar o firebase_core, confira.
importScripts('https://www.gstatic.com/firebasejs/13.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyC2bpKr_rcRQN_FpW_gGO2HAT2J3VSOXpM',
  appId: '1:166356725639:web:44f1680ebcdcdf05c36d22',
  messagingSenderId: '166356725639',
  projectId: 'co2bank',
  authDomain: 'co2bank.firebaseapp.com',
  storageBucket: 'co2bank.firebasestorage.app',
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
