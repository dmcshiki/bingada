# Pendências (ficam para depois)

Itens que bloqueavam o desenvolvimento ou que eram complementares. Foram registrados aqui para o trabalho seguir.

## Precisam de você / do ambiente
- [ ] **Rodar a suíte de testes Dart** (`flutter test` e `flutter test --platform chrome test/domain`). Neste ambiente, um hook do plugin VGV bloqueia `flutter test`. Os testes já estão escritos em `test/domain`, `test/data` e `test/presentation`. O domínio passou 50/50 num harness alternativo, e o golden VM × JS (dart2js) bateu.
- [ ] **Criar o projeto no Firebase** e preencher os `--dart-define` e os secrets do GitHub (`FIREBASE_*`, `CLOUDFLARE_*`).
- [ ] **Testar as regras do Realtime Database** no emulador. O download do emulador foi bloqueado pelo proxy. As regras do Firestore passaram 5/5 em `test/rules`.

## Funcionalidade
- [x] "Novo jogo (host)": pré-preencher o assistente com a configuração da partida anterior. Rota `/create?from=<gameId>` (`AppRoutes.createFrom`) + `CreateRoomController.prefillFrom`. Falta só o botão em `result_page.dart` apontar para `AppRoutes.createFrom(game.id)`.
- [x] Editor de cartela: "Importar JSON", "Salvar como modelo" (localStorage via `KeyValueStore`) e imagem no centro livre (URL em `FreeCell.imageUrl`; a renderização da imagem nas cartelas do jogo ainda mostra o rótulo).
- [x] Desempate do azarão separado do desempate dos prêmios (`GameSettings.underdogTieBreak`; jogos antigos sem o campo usam `tieBreak`).
- [x] Auditoria: "Baixar dados da partida (JSON)" e link para o commit no GitHub (repo via `--dart-define=TOKINGO_REPO_URL`).
- [x] Streamer: parâmetro `?compact=1` (só bola atual, últimas bolas e rodapé).
- [ ] Penalidade por comer bola: opção na tela 06 feita (Nenhuma / Pular N bolas → `SkipDraws`). Falta a ativação da 09b.
- [ ] Checagem de "grito pendente" no sorteio é aplicada no cliente e em transação otimista. As Rules não conseguem consultar claims sem Cloud Functions (limitação aceita do plano Spark).

## Visual (diferenças pequenas do canvas)
- [ ] Bordas tracejadas: bloco do azarão e "+ Adicionar prêmio" feitos (`room/presentation/dashed_border.dart`). Falta a célula "marcou e não saiu".
- [x] Seletor de cor das colunas: dialog com paleta + campo hex.
- [ ] Revisar cada tela em layout mobile (o desktop foi conferido com screenshots).
- [ ] Servir as fontes localmente (hoje o `google_fonts` busca em runtime) para eventos com rede ruim.
- [ ] Lint de marca (R12): criar `.brand-denylist` com os termos proibidos. O passo do CI já está pronto.
