# Tokingo: especificação, brainstorm e design (v3)

> Bingo web multijogador, 1 sala, até 60 jogadores, Flutter Web, **open source**, custo R$ 0.
> Visual **inspirado** em uma paleta e tipografia de referência, **sem nenhum logo, marca ou nome de terceiros** (R12).
> Design de telas: canvas "Tokingo – telas" (36 telas, mapa de fluxos na tela 00).

## 0. Requisitos (consolidado)

| # | Requisito |
|---|---|
| R1 | Uma sala por partida, até **60 jogadores** (o host conta como um deles). |
| R2 | **Uma cartela por conta por partida.** É a mesma em qualquer dispositivo. Cartela nova só existe com jogo novo. |
| R3 | Cartela gerada proceduralmente e verificável: `sha256(uid \| gameId \| salt)` (§4). |
| R4 | **Acesso configurável por partida** (§2): domínio(s), mesmo domínio do host, lista de e-mails ou pública. Nenhum domínio fica fixo no código. |
| R5 | O jogador **grita BINGO**. O host recebe uma verificação automática e visual: válido, **comeu bola**, modalidade errada, não elegível ou cartela adulterada (§5). |
| R6 | **Tela de streamer** limpa, só leitura e sem nenhum controle de admin, para transmitir (§3.2). |
| R7 | **O host também joga**, com a própria cartela (§3.1). |
| R8 | **Open source** e auditável: código, regras e resultado de cada partida (§6). |
| R9 | **Cartela 100% personalizável**: títulos das colunas, conteúdo (números, textos, emojis), faixas, tamanho e centro livre (§4). |
| R10 | Visual inspirado na paleta e tipografia de referência (§8), sem reproduzir elementos de marca. |
| R11 | **Custo zero**: Firebase Spark + hosting grátis, sem cartão de crédito (§1). |
| R12 | **Nenhum logo, marca ou nome de empresa** no app, no repositório, nos assets ou nos presets, inclusive o símbolo/chevron do manual. Domínio de acesso, nome do evento e imagem do centro livre são **configuração do host em runtime**. Um lint no CI barra a reintrodução. |
| R13 | **Marcação 100% manual e sem dicas.** Não há auto-marcar. O app **nunca** diz se o jogador tem o número, nunca destaca padrão completo e nunca mostra "falta N". O BINGO tem sempre o mesmo visual. As únicas exceções, que não revelam nada sobre a cartela, são o BINGO bloqueado por **limite de prêmios** (R30) e, se a política de penalidade mudar no futuro, por **penalidade** (R31). O motivo vem sempre escrito. |
| R14 | **Web first (Flutter Web)**: layout desktop é o alvo principal, com mobile web responsivo e sem app nativo. |
| R15 | **Clean Architecture** obrigatória, com **go_router**, **freezed** e **get_it** (§9). |
| R16 | **Sorteio só manual**: o host clica em SORTEAR a cada bola, sem timer. |
| R17 | **Sem indicadores de proximidade** em nenhuma tela: nem quantos estão perto, nem quão perto. |
| R18 | **Flutter/Dart na versão estável mais recente** e sintaxe moderna da linguagem (§9.1). |
| R19 | **Prêmios e modalidades** definidos pelo host na criação (§5.1). A lista é ordenada, e cada prêmio tem modalidade, descrição e número de vencedores. O azarão é um prêmio de fim de jogo. |
| R20 | **Todo BINGO informa o tipo detectado** ("Horizontal · linha 2", "Vertical · coluna G"…) no modal do host, no streamer e no resultado. |
| R21 | **O jogo termina automaticamente quando o último prêmio sequencial é confirmado**, normalmente a cartela cheia. Aí o sorteio trava, o azarão é calculado e o `drawSeed` é revelado. |
| R22 | **"Como jogar"** em 4 passos na tela de entrada e no ícone "?" durante o jogo (§5.2). |
| R23 | **O jogador não vê contagem nem histórico de bolas.** Ele vê só a bola atual, a cartela, o prêmio valendo e os próximos prêmios, sem indicar qual encerra o jogo. A tabela de bolas sorteadas aparece só no host e no streamer, e o streamer também não mostra a contagem. |
| R24 | **A sala fecha no COMEÇAR** ("Começar e fechar sala"). Depois disso não entram novas cartelas. O streamer mostra "sala fechada · jogo em andamento", sem QR. Quem tentar entrar cai no erro "já começou" e pode assistir. |
| R25 | **QR code real** (ISO 18004, correção M) para `https://<host>/s/<código>`, gerado com `qr_flutter`, com o código de 4 caracteres embaixo. |
| R26 | **Sorteio de desempate**: 2 ou mais gritos válidos no mesmo prêmio e no mesmo `drawIndex` levam ao sorteio, que também aparece no streamer. O vencedor é `sha256(finalSeed \| prizeId \| uids ordenados) mod N`, determinístico e auditável. Opção da sala: "sorteio" (padrão) ou "todos ganham". Vale também para empate no azarão. |
| R27 | **Encerrar partida antes do fim** (host), com confirmação. Os prêmios restantes não são entregues, o azarão é calculado com as bolas até ali, a seed é revelada e o status vira `abandoned` ("encerrada pelo host"). |
| R28 | **Janela de gritos**: gritos de uma bola são aceitos até o próximo sorteio, e o SORTEAR fica bloqueado com grito pendente. Dois ou mais válidos no mesmo `drawIndex` levam à 12a "Empate detectado" e depois à 12b desempate. Grito depois do próximo sorteio já tem outro `drawIndex`. |
| R29 | **Estados do streamer** ligados à verificação, sempre sem controles: 13b conferindo → 13c válido / 13d comeu bola (se a regra estiver ligada) → 13e sorteando desempate → 13f decidido → volta ao 13 com o próximo prêmio. |
| R30 | **Limite de prêmios por pessoa** (passo 05): máximo global (1, 2, 3, sem limite) + matriz "quem ganhou X pode concorrer a Y", incluindo o azarão. Quem atinge o limite segue jogando, com o BINGO bloqueado e o motivo escrito, e sai do cálculo do azarão. |
| R31 | **Penalidade por comer bola: por enquanto, nenhuma além do grito não valer.** O jogador volta à cartela, o jogo continua e ele pode gritar de novo na próxima bola. A penalidade é um **ponto de extensão** (`ClaimPenaltyPolicy`, §5.4): trocar a regra no futuro, por exemplo para "N bolas sem gritar", não muda a UI nem o modelo de dados. |

## 1. Stack e custo

| Peça | Escolha | Observação |
|---|---|---|
| Front | Flutter Web (`--wasm`, fallback CanvasKit) | |
| Auth | Firebase Auth com Google | `email_verified` garantido. Funciona com Google Workspace corporativo (`hd`). |
| Banco | Cloud Firestore (Spark) | Por volta de 28k leituras/dia com 5 jogos de 60 pessoas, contra o limite de 50k/dia. Nenhum listener em coleção inteira em loop. |
| Presença | Realtime Database `onDisconnect` (Spark) | Só para "host offline" (09d). |
| Hosting | **Cloudflare Pages** (ou GitHub Pages) | O Firebase Hosting no Spark tem 360 MB/dia, e 60 bundles Flutter de ~3 MB estouram isso em dia de evento. |
| CI | GitHub Actions público | Build, testes, lint de marca e deploy reproduzível (§6). |
| Cloud Functions | ❌ | Exigem o plano Blaze, que pede cartão. Tudo é feito com Security Rules e verificação pública no cliente. |

Plano B de cota: migrar o stream de sorteios para RTDB (cobra por bytes, ~1 MB por jogo). Se um dia precisar de servidor autoritativo, a opção é Cloudflare Workers + Durable Objects (grátis, sem pausa).

## 2. Controle de acesso por partida (R4)

| Política | Quem entra | Regra (Security Rules) |
|---|---|---|
| `domain` | E-mails dos domínios listados pelo host | `email.split('@')[1] in game.access.domains` |
| `sameAsHost` | Mesmo domínio do host | domínio do e-mail == `game.access.hostDomain` (gravado na criação) |
| `allowlist` | E-mails convidados (até 60) | `email in game.access.emails` |
| `public` | Qualquer conta Google verificada | `email_verified == true` |

- A checagem acontece no `create` da cartela, nas Rules. Alterar o cliente não fura a barreira.
- A política fica **imutável depois do lobby**.
- A tela de login mostra a política antes do login. Em `domain` com um único domínio, o app passa `hd` ao Google Sign-In.
- Recusa: tela 15 ("Opa, essa sala é fechada… troca de conta?").

## 3. Rotas, papéis e telas

```
/login                Entrar + Como jogar (01–01d)
/                     Lobby: entrar com código / criar sala (02)
/create?step=…        Criar sala: access | card | prizes | review (03–06)
/s/:code              Sala de espera do jogador (08)
/s/:code/play         Jogo do jogador (09, 10) e cartela do host (11b)
/s/:code/host         Espera do host (07) e painel (11, 11c, 12, 12a, 12b)
/s/:code/stream       Tela de streamer (13–13f), só leitura
/s/:code/result       Fim de jogo (14)
/verify/:gameId       Auditoria pública (16)
```

O go_router faz o redirect: sem login → `/login?next=…`; sala em andamento e sem cartela → 15c; sala encerrada → `/result`.

### 3.1 Host também joga (R7)
- Na criação, o host gera `cards/{hostUid}`, que ocupa 1 das 60 vagas (opção na tela 06).
- O painel tem o atalho "Abrir minha cartela" (11b). A cartela do host tem um atalho para voltar ao painel.
- O BINGO do host vai para a mesma fila, com a mesma verificação automática e pública no streamer.
- O host não escolhe a sequência, porque ela só é fixada no start, depois das cartelas (§6). Ele também não escolhe desempates (R26).

### 3.2 Tela de streamer (R6, R29)
- Rota só leitura, **composta de widgets próprios**: não é a tela de admin com `if (isHost)` por cima. Não existe botão de admin, nem escondido.
- O host abre em outra janela ("Abrir tela de transmissão ↗") e compartilha só ela. Qualquer jogador ou espectador também pode abrir.
- Layout 16:9 (1080p):
  - **Centro:** a bola atual gigante dentro do token.
  - **Esquerda:** tabela do pool, com as bolas sorteadas acesas.
  - **Direita:** últimas bolas.
  - **Rodapé:** "Sala K7QP · fechada: jogo em andamento", prêmio valendo e modalidade.
  - **Sem contagem de bolas** (R23) e **sem QR durante o jogo** (R24).
- Overlays: 13b conferindo, 13c válido, 13d comeu bola (só com `showFailsOnStream`), 13e sorteando desempate, 13f desempate decidido.
- Parâmetros de URL: `?chroma=1` (fundo verde para OBS) e `?compact=1`.

## 4. Cartela personalizável (R3, R9)

O host monta um **template** (JSON, reutilizável e exportável) no passo 04:

```jsonc
{
  "name": "Clássico 75",
  "rows": 5, "cols": 5,                      // de 3x3 a 5x5
  "headers": ["B","I","N","G","O"],          // livres: "F E S T A", emojis…
  "colors": ["#779ccf","#09b5f0","#4ec45f","#c679cc","#914ec4"],
  "free": { "enabled": true, "label": "★", "imageUrl": null },  // imagem: upload do host
  "columns": [
    { "type": "range", "from": 1,  "to": 15 },
    { "type": "range", "from": 16, "to": 30 },
    { "type": "items", "items": ["Daily", "Deploy na sexta", "Bug em prod", "…"] },
    { "type": "range", "from": 46, "to": 60 },
    { "type": "range", "from": 61, "to": 75 }
  ]
}
```

- **Validação no editor:** cada coluna precisa ter pelo menos `rows` itens (um a menos na coluna do centro livre). A prévia é gerada ao vivo.
- **Pool do sorteio:** a união das colunas, com cada item carregando o ID da coluna. A bola mostra "N · Bug em prod".
- **Presets:** Clássico 75, Buzzwords Dev e Em branco. Importar/exportar JSON e "Salvar como modelo".
- O template é **copiado congelado** para o `game` na criação.
- **Algoritmo:** a seed é `sha256(uid | gameId | salt)`, onde `salt` são 32 bytes aleatórios do host criados quando o jogo abre (ninguém pré-calcula). Os 4 primeiros bytes vão para o **mulberry32**, seguido de Fisher-Yates por coluna. A cartela guarda IDs de itens (`algoVersion: 2`).
- A cartela é **gravada** no primeiro join e só lida depois, por isso é a mesma em qualquer dispositivo.
- **Determinismo no Dart Web:** use aritmética 32-bit com `package:fixnum` ou máscara `& 0xFFFFFFFF` e `imul` emulado. Teste golden com seeds fixas na VM e no Chrome.

## 5. BINGO, verificação e "comeu bola" (R5)

### Jogador
- Marca tocando na célula (R13). O BINGO fica sempre visível e igual, exceto com limite de prêmios (R30) ou, no futuro, se uma penalidade bloquear (R31).
- Ao gritar, aparece uma confirmação ("Tem certeza? Se errar, todo mundo vai saber"). O claim envia `{prizeId, drawIndex}`. **O jogador não escolhe a modalidade**: o verifier detecta.
- Resultado no overlay 10: aguardando → válido / comeu bola / modalidade errada.

### Host: verificação em uma olhada (12)
1. **Veredito:**

   | `verdict` | Significado |
   |---|---|
   | `valid` | Fechou a modalidade do prêmio atual |
   | `missed` | **Comeu bola**: marcou bola que não saiu ou não fechou nada |
   | `wrongPattern` | Fechou outra modalidade, não a que está valendo |
   | `notEligible` | Atingiu o limite de prêmios (R30) |
   | `penalized` | Gritou durante uma penalidade. **Reservado**: não ocorre com a política atual (R31) |
   | `tampered` | Cartela gravada ≠ recalculada pela seed: desclassificação |

2. **Tipo detectado** (R20) e **cartela colorida**: verde ✓ no padrão; azul para sorteada; roxo ✕ tracejado para "marcou e não saiu" (sem vermelho); cinza para o resto.
3. **Checklist:** seed confere · modalidade do prêmio atual · validado com as bolas até o grito.
4. **Botões:** Confirmar / Rejeitar. Com empate, viram "Empate detectado → sorteio de desempate" (12a, R28).

- A validação usa `draws[0..drawIndex]`: quem gritou cedo demais continua tendo comido bola.
- O `drawIndex` do claim tem que ser **igual** a `draws.size()` no momento da criação (regra nas Rules), para ninguém "voltar no tempo".
- Limite de prêmios e penalidade (quando houver) são aplicados pelo verifier com dados públicos (claims + `prizePolicy` + `claimPenalty`) e reconferidos em `/verify`.

### 5.4 Penalidade extensível (R31)
Hoje vale **`none`**: comer bola só invalida aquele grito, sem outra consequência. Para mudar depois sem retrabalho, a estrutura já fica pronta:

```dart
sealed class ClaimPenaltyPolicy {
  const ClaimPenaltyPolicy();
}
final class NoPenalty extends ClaimPenaltyPolicy { const NoPenalty(); }          // atual
final class SkipDraws extends ClaimPenaltyPolicy {                               // futuro
  const SkipDraws(this.draws);
  final int draws;
}
// futuros: LoseEligibility (sai do prêmio atual), MaxMisses(n) …

abstract interface class PenaltyEvaluator {
  /// null = pode gritar; senão, o motivo para a UI e o verifier.
  PenaltyBlock? blockFor(UserId player, List<Claim> history, int currentDrawIndex);
}
```

- Persistência: `settings.claimPenalty` com discriminador `type` (`none`, `skipDraws`, …), como union `freezed`. Um jogo antigo sem o campo é lido como `none`.
- `BingoVerifier` e `/verify` consultam o `PenaltyEvaluator`. O veredito `penalized` e a tela 09b (BINGO bloqueado) já existem, mas ficam **inativos** com `NoPenalty`.
- Na tela 06, a regra aparece como "Penalidade por comer bola: nenhuma (o grito só não vale)". As outras opções entram no mesmo seletor quando forem implementadas.

### 5.1 Prêmios e modalidades (R19–R21, R30)

```jsonc
"prizes": [
  { "id": "p1", "order": 1, "pattern": "horizontal", "label": "Caneca",         "winners": 1 },
  { "id": "p2", "order": 2, "pattern": "vertical",   "label": "Vale-café",      "winners": 1 },
  { "id": "p3", "order": 3, "pattern": "full",       "label": "Fone bluetooth", "winners": 1 }
],
"endOfGamePrizes": [
  { "id": "u1", "pattern": "underdog", "label": "Prêmio azarão", "winners": 1 }
],
"prizePolicy": {
  "maxPerPlayer": 1,                       // 1 | 2 | 3 | null (sem limite)
  "allow": { "p1": ["p2"], "p2": [], "p3": [] }   // quem ganhou X pode concorrer a Y (inclui "u1")
}
```

| Modalidade | Regra | Exibição |
|---|---|---|
| `horizontal` | qualquer linha | "Horizontal · linha 2" |
| `vertical` | qualquer coluna | "Vertical · coluna G" |
| `diagonal` | uma das diagonais | "Diagonal ↘ / ↙" |
| `line` | horizontal, vertical ou diagonal | o tipo que fechou |
| `corners` | 4 cantos | "Quatro cantos" |
| `x` | as duas diagonais | "X" |
| `frame` | borda | "Moldura" |
| `full` | todas as células | "Cartela cheia" |
| `custom` | máscara desenhada pelo host | nome do host |
| `underdog` (**azarão**) | no fim, quem tem **menos números sorteados** na cartela (o centro não conta) | "Azarão · só 9 de 24 saíram" |

- As rodadas seguem a ordem e as bolas **não zeram** entre prêmios. Confirmar um prêmio mostra 09c / 13c "agora vale…".
- **Fim (R21):** confirmar o último prêmio sequencial faz `status = finished`. Aí o azarão é calculado, a seed é revelada e todos vão para a tela 14.
- **Azarão:** não tem grito. É calculado de forma determinística no fim e respeita `prizePolicy`. Empate cai no R26.
- O `BingoVerifier` devolve `ClaimResult` (union do freezed) com `verdict` + `matched: List<(PatternKind, int)>`. Se mais de um padrão fechou na mesma bola, todos são listados.

### 5.2 Como jogar (R22)
1. **Entre e pegue sua cartela**: é única e igual em qualquer dispositivo.
2. **Fique de olho nas bolas**: na tela de transmissão e no topo da sua tela.
3. **Carimbe você mesmo**: o app não marca nem avisa.
4. **Fechou? BINGO!**: o host confere. Se marcou bola que não saiu, comeu bola.

Inclui miniaturas das modalidades e a explicação do azarão. Aparece no login (01–01d) e no "?" do jogo (09e).

### 5.3 Fluxos e inventário de telas

- **Jogador:** 01 (01b–d) → 02 (erros 15–15e) → 08 → 09 (09b penalidade (reservada) · 09c prêmio entregue · 09d host offline · 09e como jogar) → 10 (10b válido · 10c comeu bola · 10d modalidade errada) → 14 → 16
- **Host:** 01 → 02 → 03 → 04 → 05 → 06 → 07 → 11 (11b minha cartela · 11c encerrar) → 12 (12a empate → 12b desempate) → 14 → "novo jogo" volta ao 06 com a config pré-preenchida
- **Telão:** 13 → 13b → 13c / 13d → (empate) 13e → 13f → 13 (próximo prêmio) → 14
- **Público:** 15c → 13 (assistir) → 14 → 16

| # | Tela | Rota |
|---|---|---|
| 00 | Mapa de fluxos | — |
| 01 / 01b–d | Entrar + Como jogar | `/login` |
| 02 | Lobby | `/` |
| 03 / 04 / 05 / 06 | Criar sala: acesso, cartela, prêmios + limite, regras e revisão | `/create` |
| 07 | Espera · host (QR real, "Começar e fechar sala") | `/s/:code/host` |
| 08 | Espera · jogador | `/s/:code` |
| 09 / 09b–e | Jogo · penalidade (**reservada**, inativa hoje) · prêmio entregue · host offline · como jogar | `/s/:code/play` |
| 10 / 10b–d | Após o grito: aguardando · válido · comeu bola · modalidade errada | overlay em `/play` |
| 11 / 11b / 11c | Painel · minha cartela · encerrar partida | `/s/:code/host` |
| 12 / 12a / 12b | Verificar · empate detectado · sorteio de desempate | modal em `/host` |
| 13 / 13b–f | Streamer · conferindo · válido · comeu bola · sorteando · decidido | `/s/:code/stream` |
| 14 | Fim de jogo (vencedores, azarão, auditar, novo jogo) | `/s/:code/result` |
| 15 / 15b–e | Erros: sem acesso · sala cheia · já começou · encerrado · código inválido | vários |
| 16 | Auditoria pública | `/verify/:gameId` |

## 6. Open source e prova de justiça (R8)

1. **Repositório público (MIT)**: app, `firestore.rules`, algoritmos e testes.
2. **Build público**: o GitHub Actions faz o build e o deploy no Cloudflare Pages. O app mostra o `commit SHA` com link para o GitHub.
3. **Commit-reveal do sorteio:**
   - **Criação:** o host gera `drawSeed` (32 bytes, `Random.secure()`), guarda localmente e publica `drawCommit = sha256(drawSeed)`.
   - **Start:** publica `cardsHash = sha256(lista ordenada de uid+cartela)`. Internamente usa `finalSeed = sha256(drawSeed | cardsHash)`. **`finalSeed` não é publicado durante o jogo**, senão todos saberiam a sequência.
   - **Sorteio:** a bola *i* é o item *i* da permutação mulberry32(`finalSeed`) do pool. O host grava 1 item por vez em `draws`.
   - **Fim (ou encerramento):** o host revela `drawSeed`. Qualquer pessoa recalcula `finalSeed`, a sequência, as cartelas, os vereditos, os desempates e o azarão.
4. **`/verify/:gameId`** (16): checklist recalculado no navegador e selo "Partida 100% verificada" ou a lista de divergências. Os dados podem ser baixados em JSON.
5. **Riscos que restam (documentados no README):**
   - O host conhece a sequência, mas não a escolhe.
   - O host pode sumir sem revelar a seed (aparece como "não revelado ⚠️").
   - Contas Google múltiplas = várias cartelas. Com `domain` corporativo isso é praticamente resolvido.

## 7. Modelo de dados (Firestore + RTDB)

```
templates/{templateId}           ownerUid, name, json (§4), public
rooms/{roomCode}                 hostUid, currentGameId, createdAt
games/{gameId}
  roomCode, hostUid, eventName, status: lobby|running|finished|abandoned
  access: { mode, domains[], emails[], hostDomain }          # imutável após lobby
  template: {...}                                            # cópia congelada
  prizes[], endOfGamePrizes[], prizePolicy                   # imutáveis após lobby
  settings: { hostPlays, showFailsOnStream, tieBreak: draw|allWin,
              claimPenalty: { type: "none" } }               # extensível (§5.4)
  salt, drawCommit, cardsHash?, drawSeed?                    # drawSeed só no fim
  playerCount, maxPlayers: 60, currentPrizeIndex
  draws: [itemId]                                            # só cresce, +1
  winners: [{ prizeId, uid, drawIndex, tieBreak: bool }]
  createdAt, startedAt, endedAt
games/{gameId}/cards/{uid}       items[], algoVersion, displayName, photoUrl, joinedAt
games/{gameId}/claims/{id}       uid, prizeId, drawIndex, matched[],
                                 verdict: valid|missed|wrongPattern|notEligible|penalized|tampered,
                                 status: pending|confirmed|rejected|tied, createdAt
RTDB presence/{gameId}/host      online: bool, lastSeen (onDisconnect)
```

**Regras principais:**
- **`cards`:** `create` só se `auth.uid == uid`, o e-mail está verificado, a política de acesso permite, `status == lobby`, há vaga (`playerCount < 60`, na mesma transação) e o tamanho bate com o template. `update` e `delete` são proibidos.
- **`games`:** só o host escreve.
  - `draws` cresce exatamente 1 item por vez, e só sem claim `pending` no `drawIndex` atual.
  - `access`, `template`, `prizes`, `prizePolicy`, `settings`, `salt` e `drawCommit` são imutáveis.
  - `drawSeed` só pode ser gravado quando `status ∈ {finished, abandoned}`. O hash é conferido no cliente, porque as Rules não fazem sha256.
- **`claims`:** `create` pelo próprio jogador com `drawIndex == draws.size()` e `status == running`. Só o host altera `status`/`verdict`.

## 8. Design: "token arredondado" (R10, R12)

### Princípios
- **Voz leve, descontraída e alegre** ("comeu bola", "segura o coração").
- **Sem marca:** o grafismo é o **token**, um quadrado com cantos bem arredondados e inclinado -8°. Ele aparece na bola, no carimbo, nos avatares e nos fundos.
- **Cores chapadas**, sem gradientes coloridos e **sem vermelho**: erro e "comeu bola" em roxo ou grafite.
- **Ícones:** vetoriais próprios ou de licença aberta (ex.: Lucide). Nenhum logo de terceiros, inclusive no botão "Entrar com Google", que usa ícone genérico conforme R12. Antes do deploy, confirmar se as diretrizes de marca do provedor de login exigem o botão oficial.
- **Nome:** "Tokingo" é o nome do projeto. Telas de login, espera e streamer mostram o **nome do evento** configurado pelo host.

### Paleta (tokens editáveis)
| Token | Hex | Uso |
|---|---|---|
| `primary` | `#779ccf` | Botões, cabeçalhos, carimbo |
| `primaryStrong` | `#4f86c6` | Hover/pressionado |
| `navy` | `#204a77` | Fundo do streamer, CTAs, texto forte |
| `deepBlue` | `#1868a1` | Formas de fundo |
| `cyan` | `#09b5f0` | Bola atual |
| `pink` | `#c679cc` | Detalhes, azarão |
| `purple` | `#914ec4` | Comeu bola e erros |
| `green` | `#4ec45f` | Válido / padrão completo |
| `light` | `#e6e9e9` | Fundo e células neutras |
| `graphite` | `#424041` | Texto, modo escuro |

Colunas padrão: `#779ccf` `#09b5f0` `#4ec45f` `#c679cc` `#914ec4`. Sobre `#09b5f0` e `#4ec45f`, o texto é grafite escuro (contraste AA).

### Tipografia (Google Fonts, OFL)
- **Days One:** números, bola, letras das colunas, BINGO e o wordmark.
- **Montserrat:** textos e títulos no estilo "sala de **espera**".
- **JetBrains Mono:** hashes e IDs na auditoria.

### Componentes
- **Cartela:** branca, células com raio de 16–18px e cabeçalhos em pílula colorida.
- **Bola atual:** token inclinado, entrada `easeOutBack`.
- **Carimbo:** mini-token `#779ccf` a 85%, rotação de -10° a 10°, escala de 1,3 para 1,0 em 180ms.
- **Fundos:** formas arredondadas chapadas cortando as bordas.
- **Confetes** só nas cores da paleta.

### Acessibilidade
- Estado nunca só por cor: carimbo, ✓/✕ e tracejado.
- Contraste AA, alvos de toque de pelo menos 44–48px, teclado e foco visíveis.
- `Semantics` por célula ("G 52, marcado") e `announce` a cada bola.
- `disableAnimations` troca as animações por fade.

## 9. Arquitetura: Clean Architecture (R15)

```
presentation ──▶ domain ◀── data
```
- **domain:** Dart puro.
  - Entidades `freezed` e contratos de repositório (`abstract interface class`).
  - Serviços: `CardGenerator`, `DrawSequence`, `BingoVerifier`, `PrizePolicyEvaluator`, `UnderdogCalculator`, `TieBreaker`, `AccessPolicy`.
  - Penalidade: `PenaltyEvaluator` + `ClaimPenaltyPolicy` (§5.4).
  - Use cases: `CreateGame`, `JoinGame`, `StartGame`, `DrawNext`, `MarkCell`, `CallBingo`, `VerifyClaim`, `ResolveTie`, `ConfirmPrize`, `EndGame`, `RevealSeed`, `AuditGame`.
- **data:** DTOs (`freezed` + `json_serializable`), datasources (Firestore, Auth, RTDB), mappers e implementações dos repositórios.
- **presentation:** páginas e widgets. Estados de UI como unions `freezed`. O streamer é uma feature própria, sem dependência da do host.
- Um lint (`import_lint` ou regra custom) impede imports entre camadas fora da regra.

### 9.1 Versão e estilo de código (R18)
- **Versão:** Flutter e Dart estáveis mais recentes no início do projeto, fixados no `pubspec.yaml` e no CI (`subosito/flutter-action`).
- **Lint:** `flutter_lints` ou `very_good_analysis` (mais recente), com `strict-casts`, `strict-inference` e `strict-raw-types`.
- **Sintaxe moderna obrigatória**, conforme a versão:
  - modificadores de classe (`sealed`, `final`, `interface`, `base`), repositórios como `abstract interface class` e implementações como `final class`;
  - `switch` exaustivo e switch expressions, records e patterns;
  - extension types para IDs (`GameId`, `UserId`, `RoomCode`, `PrizeId`);
  - super parameters, wildcard `_`, null-aware elements, dot shorthands e digit separators;
  - primary constructors quando estiverem estáveis;
  - widgets `const` sempre que possível, sem funções que retornam widget, e `async`/`await` em vez de `.then()`.
- **Proibido:** APIs deprecated, `dynamic` sem motivo, `!` sem justificativa e `late` para contornar inicialização.
- `dart fix --apply` e `dart format` no pre-commit e no CI.

### Libs
| Obrigatórias | Uso |
|---|---|
| `go_router` | Rotas, deep link `/s/:code`, redirects de auth, acesso e status da sala |
| `freezed` (+ `freezed_annotation`, `json_serializable`, `build_runner`) | Entidades, DTOs, `ClaimResult`/`ClaimVerdict`, estados de UI |
| `get_it` | Composition root (`core/di/injection.dart`): datasources e repositórios em `registerLazySingleton`, use cases em `registerFactory` |

| De apoio | Uso |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_database` | Backend Spark |
| `crypto`, `fixnum` | sha256 e aritmética 32-bit determinística |
| `qr_flutter` | QR real (R25) |
| `google_fonts` | Days One, Montserrat, JetBrains Mono |
| `confetti` | Fim de jogo |

Gerência de estado: `ValueNotifier`/`ChangeNotifier` injetados via get_it, para não adicionar uma quarta lib obrigatória.

### Estrutura de pastas
```
lib/
  core/      di/ router/ theme/ crypto/ (prng, hashing)
  features/
    auth/            domain/ data/ presentation/
    room/            domain/ data/ presentation/      # criar sala, acesso, prêmios, regras
    template_editor/ domain/ data/ presentation/
    game/
      domain/   entities/ repositories/ services/ usecases/
      data/     dtos/ datasources/ repositories/
      presentation/  player/ host/ verify_claim/ tiebreak/
    stream/          presentation/                     # só leitura
    result/          presentation/
    audit/           domain/ presentation/             # /verify
test/
  domain/   golden VM×Chrome, verifier, prize policy, underdog, tiebreak
  data/     Firebase Emulator (Rules)
  presentation/  widget tests das telas-chave
firestore.rules · database.rules.json
.github/workflows/ci.yml       # analyze, test, lint de marca, build, deploy
```

## 10. Ordem de implementação
1. `card_template` + `card_generator` + golden test (VM vs Chrome).
2. `draw_sequence` (commit-reveal) + `bingo_verifier` (todos os vereditos) + `prize_policy` + `underdog` + `tiebreaker`, com testes.
3. `firestore.rules`: acesso, cartela única, limite de 60, `draws` +1, claims com `drawIndex` atual e imutabilidades, testadas no Emulator.
4. Auth + lobby + assistente Criar sala (03–06) + espera (07/08) com QR.
5. Jogo do jogador (09–10d) e painel do host (11–11c) com sorteio manual.
6. Verificação (12), janela de gritos, empate e desempate (12a/12b), troca de prêmio.
7. Streamer (13–13f) como feature isolada.
8. Fim de jogo (14), encerramento antecipado, revelação da seed e `/verify` (16).
9. Erros (15–15e), presença do host (09d), Como jogar (01–01d, 09e).
10. Polimento visual e acessibilidade, CI público e lint de marca (R12).

## 11. Decisões tomadas
- **Bola perdida:** é intencional. O jogador não vê o histórico (R23), e quem se distrair confere pelo streamer.
- **Botão de login:** ícone genérico, sem logo de terceiros (R12).
- **Penalidade:** por enquanto só invalida o grito. A estrutura é extensível (R31, §5.4).
