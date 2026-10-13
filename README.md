# CO2Bank App

App mobile do CO2Bank, feito em Flutter.

## O que é

O CO2Bank App é a interface visual do projeto. Ele mostra o CO2 estimado das compras, o limite ecológico mensal, alertas preventivos e recompensas em tokens. Toda a regra de negócio (cálculo de CO2, política de limite) fica no backend, no repositório `Co2Bank-flask`. Aqui só chamamos a API e exibimos os dados.

O pitch completo do projeto (ODS 12/13/17, metodologia, referência ao Doconomy e mapeamento de CO2 por categoria) está no README do backend.

## Arquitetura

O código fica em `lib/`, organizado por funcionalidade. Cada pasta tem as telas e, quando precisa falar com a API, uma subpasta `servico/`.

```
lib/
├── main.dart              # AplicativoCo2Bank
├── navegacao.dart         # barra inferior + menu lateral
├── tela_splash.dart
├── nucleo/                # cliente HTTP, token JWT, cores, validadores, formatadores
├── compartilhado/widgets/ # widgets reutilizados (botão, campo, menu lateral...)
├── autenticacao/          # login, cadastro (etapas) e esqueci a senha
├── inicio/                # aba Início
├── transacoes/            # aba Extrato
├── co2/                   # aba Limite Ecológico
├── perfil/                # aba Perfil
├── open_finance/          # conexão com bancos e sincronização de compras
├── presentation/rewards/  # tela de Recompensas
└── core/app_colors.dart   # apelido de CoresApp usado pela tela de Recompensas, não remover
```

## Como rodar

### Pré-requisitos

Antes de começar, você precisa ter instalado:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) na versão estável (3.x)
- Para rodar no Android (emulador ou celular):
  - JDK 17, recomendamos o [Eclipse Temurin](https://adoptium.net/)
  - Android SDK com as command-line tools (pode instalar via `sdkmanager` ou pelo Android Studio)
  - A variável de ambiente `ANDROID_HOME` configurada apontando para a pasta do SDK

Para verificar se tudo está certo:

```bash
flutter doctor
```

Os itens relevantes devem aparecer com ✓. O item de iOS pode ser ignorado se você só for testar no Android. O item "Visual Studio" só é necessário para rodar como app de Windows.

### Instalação de dependências

```bash
flutter pub get
```

### Qual backend o app usa

Por padrão o app usa o backend publicado em produção:

```
https://co2bank-flask.onrender.com
```

Então não é preciso rodar o backend na sua máquina para testar o app. O servidor do Render "dorme" quando fica um tempo sem uso, por isso a primeira chamada do dia pode demorar até um minuto.

Para usar um backend rodando localmente, veja [Usar o backend local](#usar-o-backend-local).

### Rodar o app

```bash
flutter run
```

Se tiver mais de um dispositivo disponível, o Flutter pergunta qual usar. Para escolher direto:

```bash
flutter devices          # lista os dispositivos disponíveis
flutter run -d chrome    # no navegador
flutter run -d <id>      # no emulador ou celular, com o id que aparece no flutter devices
```

No Chrome a câmera da selfie e a biometria têm suporte limitado. Para testar essas partes, use um celular ou o emulador Android.

Com o app rodando: `r` recarrega as mudanças, `R` reinicia o app e `q` encerra.

### Rodar os testes

```bash
flutter test
```

## Testar no celular físico (Android)

### 1. Ativar Depuração USB no celular

Vá em Configurações > Sobre o telefone e toque 7 vezes em "Número da versão" para ativar as Opções do desenvolvedor. Depois vá em Configurações > Opções do desenvolvedor e ative a Depuração USB.

### 2. Conectar e autorizar

Conecte o celular por USB. Quando aparecer a pergunta "Permitir depuração USB?", toque em Permitir. Para confirmar que o dispositivo foi reconhecido:

```bash
adb devices
```

### 3. Rodar o app no celular

```bash
flutter run
```

O Flutter detecta o celular automaticamente. Se tiver mais de um dispositivo conectado ao mesmo tempo, ele vai perguntar qual usar.

## Usar o backend local

Só é necessário se você estiver mexendo no backend e quiser testar o app contra ele antes do deploy. Com o backend rodando na porta 5000, passe o endereço com `--dart-define`. O endereço muda conforme onde o app roda:

| Onde o app roda | Comando |
|---|---|
| Chrome ou Windows | `flutter run --dart-define=API_BASE_URL=http://localhost:5000` |
| Emulador Android | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000` |
| Celular por USB | `adb reverse tcp:5000 tcp:5000` e depois `flutter run --dart-define=API_BASE_URL=http://localhost:5000` |
| Celular pelo Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://SEU_IP_LOCAL:5000` |

O `10.0.2.2` só funciona dentro do emulador Android: é como o emulador enxerga o `localhost` do PC. O `adb reverse` faz o `localhost:5000` do celular apontar para o backend no PC. Se o celular desconectar, rode o `adb reverse` de novo.

Sem o `--dart-define`, o app volta a usar o backend de produção.
