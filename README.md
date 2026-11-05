# Tokingo

Bingo web multijogador, **open source e auditável**, feito em Flutter Web.
Até 60 jogadores por sala, uma cartela por conta, prêmios configuráveis,
tela de transmissão sem controles de admin e auditoria pública de cada partida.

Especificação completa: [`docs/tokingo-design.md`](docs/tokingo-design.md).

## Rodando agora (modo demo, sem Firebase)

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome            # TOKINGO_DEMO=true é o padrão
```

No modo demo, tudo roda no navegador:
- os dados do jogo ficam no `localStorage` e sincronizam **entre abas**;
- cada aba é um jogador diferente, porque a identidade fica no `sessionStorage`.

Para testar, abra uma aba como host, outras como jogadores e uma em `/s/<código>/stream` para a tela de transmissão.

## Produção (Firebase Spark, custo zero)

1. Crie um projeto no Firebase e ative o Authentication (provedor Google), o Firestore e o Realtime Database.
2. Publique as regras: `firebase deploy --only firestore:rules,database`.
3. Faça o build passando a configuração por `--dart-define`. Nenhum segredo fica no repositório:

```bash
flutter build web --wasm --release \
  --dart-define=TOKINGO_DEMO=false \
  --dart-define=GIT_SHA=$(git rev-parse HEAD) \
  --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... --dart-define=FIREBASE_DATABASE_URL=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

4. Hospede em **Cloudflare Pages**: o workflow `.github/workflows/ci.yml` já faz o deploy. Evitamos o Firebase Hosting porque o limite de 360 MB/dia não aguenta um evento.

## Arquitetura

Clean Architecture, com features e camadas separadas: `domain` (Dart puro), `data` e `presentation`.
São obrigatórios o **go_router**, o **freezed** e o **get_it** (veja `lib/core/di`).

```
lib/core/        types (IDs), crypto, ui (tema/widgets), router, di, config
lib/features/    auth · room · game · stream · result · audit · help · errors
test/            domain · data · presentation · rules (emulador)
```

## Como verificar uma partida

Abra `/verify/<gameId>`. O navegador recalcula tudo a partir dos dados públicos e da seed revelada:
- o commit do sorteio;
- a seed final;
- a sequência de bolas;
- as cartelas;
- os vereditos;
- a ordem dos prêmios;
- o azarão.

Riscos conhecidos: o host conhece a sequência, mas não consegue escolhê-la. O host também pode sumir sem revelar a seed, e isso aparece como "não revelado".

## Licença

MIT
