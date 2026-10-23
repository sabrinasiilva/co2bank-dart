<p align="center">
  <img src="assets/logo.png" alt="CO2Bank" width="180">
</p>

<h1 align="center">CO2Bank</h1>

<p align="center">
  Carteira inteligente com limite ecológico: cada compra mostra o CO₂ que gerou, e o app avisa antes de você passar do limite do mês.
</p>

<p align="center">
  <a href="https://sabrinasiilva.github.io/co2bank-dart/"><b>Abrir no navegador</b></a>
  &nbsp;·&nbsp;
  <a href="https://sabrinasiilva.github.io/co2bank-dart/co2bank.apk"><b>Baixar o app para Android (.apk)</b></a>
  &nbsp;·&nbsp;
  <a href="https://co2bank-flask.onrender.com/docs"><b>Documentação da API</b></a>
</p>

---

## Sobre o projeto

Os aplicativos de pegada de carbono que existem hoje dependem de digitação manual e só mostram o impacto depois que a compra já aconteceu. O CO2Bank faz isso sozinho: conecta no banco pelo Open Finance, calcula o CO₂ de cada compra pela categoria do estabelecimento e acompanha um limite ecológico mensal definido pelo usuário. Quando o mês passa de 80% do limite, uma Inteligência Artificial escreve um alerta personalizado. E o CO₂ que a pessoa deixa de emitir vira desconto em lojas parceiras.

Projeto acadêmico do curso de Engenharia de Software da Universidade de Mogi das Cruzes (2026).

## Funcionalidades

- **Cadastro e login** com verificação por selfie e recuperação de senha por e-mail. O app lembra o e-mail e deixa entrar com a digital, o rosto ou o PIN do celular
- **Open Finance:** conecta bancos e importa as compras do mês e dos últimos seis meses
- **CO₂ por compra:** cada transação do extrato mostra a categoria e o CO₂ estimado, com tela de detalhes
- **Lançar compra manualmente**, para quem quiser registrar algo que não veio do banco
- **Simulador "Antes de comprar":** mostra quanto CO₂ uma compra geraria e como ficaria o limite do mês
- **Limite ecológico mensal** com sugestão de valor baseada no histórico dos últimos três meses
- **Alerta preventivo com IA** na tela inicial e por notificação no celular quando o mês passa de 80%
- **Gráfico de evolução mensal** e **card de impacto** com equivalências (árvores, quilômetros de carro) e as ODS 12, 13 e 17
- **Shopping Verde:** CO₂ economizado vira CO2Coins, que podem ser trocadas por cupons de desconto em parceiros reais
- **Conquistas e Meus cupons**, com o código de cada cupom para copiar
- **Central de notificações** no sininho da tela inicial, com os alertas da IA, as conquistas, os cupons e o aviso de versão nova do app

## Instalar no celular

1. No celular Android, abra o link [Baixar o app (.apk)](https://sabrinasiilva.github.io/co2bank-dart/co2bank.apk).
2. Quando o Android perguntar, permita instalar apps desta fonte (o app não está na Play Store).
3. Abra o CO2Bank e crie uma conta.

O backend fica no plano gratuito do Render, que "dorme" quando passa um tempo sem uso. Por isso o primeiro acesso do dia pode levar até um minuto.

## Tecnologias

| Parte | O que usamos |
|---|---|
| App | Flutter (Dart 3), voltado para Android, com versão web |
| Back-end | Python com Flask, API REST em camadas, JWT e Pydantic ([repositório](https://github.com/sabrinasiilva/co2bank-flask)) |
| Banco de dados | PostgreSQL em produção e SQLite nos testes, com SQLAlchemy |
| Inteligência Artificial | Google Gemini, que escreve a mensagem do alerta preventivo |
| Hospedagem | Render (API) e GitHub Pages (site e download do app) |
| Organização | Jira (Scrum com Kanban), GitHub e Canva (identidade visual) |

## Equipe

| Nome | Função |
|---|---|
| Sabrina da Conceição | Product Owner, Analista de Sistemas e Programadora |
| Emily Cristina da Silva Lima | Scrum Master |
| Júlia de Aquino Souza | Scrum Master |
| Gustavo Gonzaga dos Santos | Desenvolvimento |
| Maitê Gonçalves | Programador |

## Estrutura do código

O código fica em `lib/`, organizado por funcionalidade. Cada pasta tem as telas e, quando precisa falar com a API, uma subpasta `servico/`. Toda a regra de negócio (cálculo de CO₂, política de limite, recompensas) fica no backend; o app chama a API e mostra os dados.

```
lib/
├── main.dart              # AplicativoCo2Bank
├── navegacao.dart         # barra inferior + menu lateral
├── tela_abertura.dart     # tela de abertura com a logo
├── nucleo/                # cliente HTTP, token JWT, cores, notificações, validadores, formatadores
├── compartilhado/widgets/ # widgets reutilizados (botão, campo, logo, menu lateral...)
├── autenticacao/          # login, cadastro (etapas) e esqueci a senha
├── inicio/                # aba Início
├── transacoes/            # aba Extrato, detalhes da transação e nova compra
├── co2/                   # aba Limite Ecológico, gráfico mensal e card de impacto
├── perfil/                # aba Perfil e sugestão de limite
├── open_finance/          # conexão com bancos e sincronização de compras
└── recompensas/           # Shopping Verde, conquistas e cupons
```

## Como rodar o código

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) na versão estável (3.x)
- Para rodar no Android (emulador ou celular):
  - JDK 17, recomendamos o [Eclipse Temurin](https://adoptium.net/)
  - Android SDK com as command-line tools (pode instalar via `sdkmanager` ou pelo Android Studio)
  - A variável de ambiente `ANDROID_HOME` apontando para a pasta do SDK

Para verificar se está tudo certo, rode `flutter doctor`. O item "Visual Studio" só é necessário para rodar como app de Windows.

### Instalar as dependências e rodar

```bash
flutter pub get
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

### Testar no celular por USB (Android)

1. No celular, vá em Configurações > Sobre o telefone e toque 7 vezes em "Número da versão" para liberar as Opções do desenvolvedor. Depois ative a Depuração USB em Configurações > Opções do desenvolvedor.
2. Conecte o celular por USB e toque em Permitir quando aparecer "Permitir depuração USB?". Confira com `adb devices`.
3. Rode `flutter run`.

### Qual backend o app usa

Por padrão, o app usa a API publicada em `https://co2bank-flask.onrender.com`, então não é preciso rodar o backend na sua máquina.

Para usar um backend rodando localmente na porta 5000, passe o endereço com `--dart-define`. O endereço muda conforme onde o app roda:

| Onde o app roda | Comando |
|---|---|
| Chrome ou Windows | `flutter run --dart-define=API_BASE_URL=http://localhost:5000` |
| Emulador Android | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000` |
| Celular por USB | `adb reverse tcp:5000 tcp:5000` e depois `flutter run --dart-define=API_BASE_URL=http://localhost:5000` |
| Celular pelo Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://SEU_IP_LOCAL:5000` |

O `10.0.2.2` só funciona dentro do emulador Android: é como o emulador enxerga o `localhost` do PC. O `adb reverse` faz o `localhost:5000` do celular apontar para o backend no PC. Sem o `--dart-define`, o app volta a usar a API de produção.

### Gerar o APK e a versão web

```bash
flutter build apk --release --target-platform android-arm64   # build/app/outputs/flutter-apk/app-release.apk
flutter build web --release --base-href /co2bank-dart/        # build/web, publicado no GitHub Pages
```

O `--target-platform android-arm64` gera o APK só para o processador dos celulares atuais. Sem ele, o APK leva também as versões para celulares antigos de 32 bits e para emuladores de PC, e fica com uns 55 MB em vez de uns 20 MB, além de demorar mais para compilar. Para testar no emulador, use `flutter run`, que já compila para o processador certo.

O site e o APK ficam na branch `gh-pages`: o conteúdo de `build/web` vai na raiz, e o APK vai junto como `co2bank.apk`.
