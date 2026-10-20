# Push do alerta de limite (Firebase) — CO2B-58

O app já tem o código do push (`lib/nucleo/push_firebase.dart`), mas o projeto
Firebase ainda não existe. Enquanto ninguém fizer os passos abaixo, o app abre e
funciona normalmente: o push é pulado em silêncio e o alerta continua chegando
pela notificação local (só com o app aberto).

O backend (CO2B-57) recebe o aparelho em `POST /devices` e envia o push quando o
mês passa de 80% do limite. Se essas rotas ainda responderem 404, o app ignora.

## 0. Quem faz o quê

O Gustavo cria o projeto Firebase (plano Spark, gratuito) e:

- gera a chave da conta de serviço para o backend em **Configurações do projeto >
  Contas de serviço > Gerar nova chave privada** e coloca no Render como
  `FIREBASE_CREDENTIALS` (nunca no Git);
- adiciona a Sabrina como membro em **Configurações do projeto > Usuários e
  permissões > Adicionar membro** (papel Editor), para ela ligar o app ao
  projeto no passo 1. Se ele preferir, ele mesmo pode rodar o passo 1 no
  repositório do app e commitar os arquivos gerados.

## 1. Ligar o app ao projeto Firebase

```bash
npm install -g firebase-tools        # se ainda não tiver o Firebase CLI
firebase login --reauth
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android,web   # escolha o projeto que o Gustavo criou
```

O `flutterfire configure` cria/sobrescreve:

- `lib/firebase_options.dart` (hoje é um arquivo provisório que avisa "não configurado")
- `android/app/google-services.json`

Os dois podem ir para o repositório (são dados de app cliente, não são segredo).
Nunca coloque no repositório a chave de conta de serviço (service account) do
servidor: essa fica só no backend.

Se o `flutterfire` acrescentar `id("com.google.gms.google-services")` no bloco
`plugins { }` do `android/app/build.gradle.kts`, pode tirar: o plugin já é
aplicado lá embaixo, só quando o `google-services.json` existe.

## 2. Chave VAPID (push na web)

No console do Firebase: **Configurações do projeto > Cloud Messaging >
Web Push certificates > Gerar par de chaves**. Copie a chave pública e passe no
run/build da web:

```bash
flutter run -d chrome --dart-define=FIREBASE_VAPID_KEY=SUA_CHAVE_PUBLICA
flutter build web --release --base-href /co2bank-dart/ --dart-define=FIREBASE_VAPID_KEY=SUA_CHAVE_PUBLICA
```

(Use o mesmo `--base-href` de sempre do GitHub Pages.) Sem essa chave o push na
web fica desligado; o Android não precisa dela.

## 3. Preencher o service worker da web

Abra `web/firebase/firebase-messaging-sw.js` e troque os `PREENCHER_...` pelos valores de
`web` que o `flutterfire configure` gerou em `lib/firebase_options.dart`
(`apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`,
`storageBucket`). Ele fica na pasta `web/firebase/` de propósito (escopo
separado do service worker do Flutter); não mova para a raiz do `web/`.

## 4. Testar

1. Rode o app (Android ou web com a chave VAPID), entre na conta e ligue
   **Perfil > Notificações de alerta**.
2. Pegue o token do aparelho: no terminal do `flutter run` aparece
   `Token do push (FCM): ...` (ele também vai no corpo do `POST /devices`).
3. No console do Firebase: **Messaging > Nova campanha > Notificações >
   Enviar mensagem de teste**, cole o token e envie.
4. Com o app fechado/em segundo plano, a notificação aparece pelo sistema.
   Com o app aberto, ela aparece como notificação local do CO2Bank — mas só
   uma vez por mês, como o aviso local. Se o aviso do mês já saiu, para testar
   de novo limpe os dados do app (ou o armazenamento do site).

Ao desligar a opção no Perfil ou sair da conta, o app chama
`DELETE /devices/<token>` e apaga o token do aparelho.
