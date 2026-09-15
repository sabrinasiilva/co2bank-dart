# CO2Bank App

Carteira inteligente com limite ecológico — app cliente (Flutter) do CO2Bank.

## O que é

Interface visual do CO2Bank: mostra o CO2 estimado das compras, o limite
ecológico mensal, alertas preventivos e recompensas em tokens de marcas
parceiras. Este app **não contém regra de negócio** (cálculo de CO2, política
de limite) — toda essa lógica vive no backend, no repositório
[`Co2Bank-flask`](../Co2Bank-flask). Aqui só chamamos a API e exibimos os
dados.

O pitch completo do projeto (ODS 12/13/17, metodologia, referência ao
Doconomy, mapeamento de CO2 por categoria) está documentado no README do
backend.

## Arquitetura

Estrutura em camadas dentro de `lib/`, espelhando o backend:

```
lib/
├── main.dart
├── core/            # cliente HTTP base, constantes (ex.: URL da API)
├── domain/          # modelos: Transaction, CarbonLimit, Reward
├── data/            # serviços que consomem a API do Co2Bank-flask
└── presentation/    # telas (home, extrato de carbono, limite, recompensas)
```

## Como rodar

### Pré-requisitos

Antes de começar, você precisa ter instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) na versão estável (3.x)
- JDK 17, recomendamos o [Eclipse Temurin](https://adoptium.net/)
- Android SDK com as command-line tools (pode instalar via `sdkmanager` ou pelo Android Studio)
- A variável de ambiente `ANDROID_HOME` configurada apontando para a pasta do SDK

Para verificar se tudo está certo:

```bash
flutter doctor
```

Os itens relevantes devem aparecer com ✓. O item de iOS pode ser ignorado se você só for testar no Android.

### Instalação de dependências

```bash
flutter pub get
```

### Rodar no emulador

```bash
flutter run
```

Por padrão, o app aponta para `http://10.0.2.2:5000`, que é o endereço do `localhost` da sua máquina visto de dentro do emulador Android. O backend precisa estar rodando para o app funcionar.

### Rodar os testes

```bash
flutter test
```

## Testar no celular físico (Android)

O backend precisa estar rodando na máquina antes de começar.

### 1. Ativar Depuração USB no celular

Vá em Configurações > Sobre o telefone e toque 7 vezes em "Número da versão" para ativar as Opções do desenvolvedor. Depois vá em Configurações > Opções do desenvolvedor e ative a Depuração USB.

### 2. Conectar e autorizar

Conecte o celular por USB. Quando aparecer a pergunta "Permitir depuração USB?", toque em Permitir. Para confirmar que o dispositivo foi reconhecido:

```bash
adb devices
```

### 3. Mapear a porta do backend

```bash
adb reverse tcp:5000 tcp:5000
```

Isso faz o `localhost:5000` do celular apontar para o backend no PC, sem precisar de IP fixo ou mesma rede Wi-Fi.

### 4. Rodar o app no celular

```bash
flutter run
```

O Flutter detecta o celular automaticamente. Se tiver mais de um dispositivo conectado ao mesmo tempo, ele vai perguntar qual usar.

Se o celular desconectar durante o build, reconecte o cabo, rode `adb reverse tcp:5000 tcp:5000` de novo e execute `flutter run` novamente.

### Apontar para outro endereço de API

Se não quiser usar o `adb reverse` e preferir conectar direto por IP na rede:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP_LOCAL:5000
```
