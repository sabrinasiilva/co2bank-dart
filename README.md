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

```bash
flutter pub get
flutter run
```

Por padrão, o app aponta para `http://10.0.2.2:5000` (endereço do `localhost`
da máquina host quando rodando no emulador Android) — é onde o backend
(`Co2Bank-flask`) deve estar rodando em desenvolvimento. Para apontar para
outro endereço:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP:5000
```

Rodar os testes:

```bash
flutter test
```
