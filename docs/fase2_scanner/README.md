# 📑 Documento de Engenharia de Software da Fase 2: Vale do Scanner

> **Grupo:** 2
> **Fase:** Vale do Scanner (Análise Léxica)
> **Disciplina:** Compiladores, Ciência da Computação, UENP
> **Professor Orientador:** Prof. Luciano Rovanni
> **Período:** 2026/2
> **Período de desenvolvimento:** 03/08/2026 a 29/08/2026
> **Cena principal:** `res://scenes/fase2_scanner/main.tscn`

**Integrantes e Funções:**

| Integrante | Função |
|---|---|
| Pedro Carulla | Líder |
| José Neres | Conteúdo Pedagógico |
| Eduardo Mattos | Conteúdo Pedagógico |
| Felipe Muraro | Interface (UI/UX) |
| Richard Ribeiro | Interface (UI/UX) |
| Heitor Vidal | Programação |
| Gustavo Favorin | Programação |
| Filipe Sudário | Testes / QA |
| Pedro Gomes | Documentação |
| Caio Nogueira | Documentação |

---

## 1. 🎯 Descrição Geral e Objetivos Pedagógicos

### 1.1 Visão geral da fase

O Vale do Scanner é a segunda fase do Compiler Edu Game. O jogador chega ao vale por um portal de entrada e encontra o código-fonte já fragmentado: o Scanner quebrou a linha `int x = 10;` em cinco blocos físicos, espalhados pelas plataformas do vale.

No centro do mapa existe um vão intransponível: uma ponte incompleta com cinco encaixes vazios. O objetivo é atravessar as plataformas, pegar cada bloco com a tecla **E**, carregá-lo até a estação de alinhamento e entregá-lo no encaixe da ponte. Os blocos só são aceitos na ordem em que o Scanner leria o código, da esquerda para a direita: `int`, `x`, `=`, `10`, `;`.

Cada bloco entregue acende um segmento da ponte. Quando os cinco segmentos estão ativos, a ponte fica sólida, a barreira que bloqueava a passagem é removida e o portal de saída é ativado. A Fase 3 fica liberada.

A fase é um percurso único e contínuo em um mapa de 2560 x 720 px e a câmera acompanha o jogador. O cenário tem ainda um NPC, o estudante preso do outro lado da ponte.

### 1.2 Conceito de compiladores abordado

A fase ensina a análise léxica, ou scanning, a primeira etapa do processo de compilação:

| Conceito | Como aparece no jogo |
|---|---|
| **Token** | Cada bloco físico carregável é um token, exibido com seu lexema e sua classe. |
| **Lexema** | O texto escrito na face do bloco (`int`, `x`, `=`, `10`, `;`). |
| **Classe / Categoria do token** | Etiqueta colorida no bloco: `PAL` (palavra-chave), `ID` (identificador), `NUM` (número), `OP` (operador), `SIM` (símbolo). |
| **Leitura sequencial do fluxo de entrada** | A ponte só aceita o próximo token da sequência. O Scanner não "pula" nem lê fora de ordem. |
| **Saída do Scanner alimenta o Parser** | A tela de conclusão explica que os tokens reconhecidos seguem para o analisador sintático (Fase 3). |

As cores são definidas em `ScannerData.kind_color()` e valem para todo o jogo, de modo que o jogador identifica a categoria pela cor antes de ler o lexema:

| Classe | Sigla | Cor |
|---|---|---|
| Palavra-chave | `PAL` | `#58a6ff` (azul) |
| Identificador | `ID` | `#6ee7a8` (verde) |
| Número | `NUM` | `#c084fc` (roxo) |
| Operador | `OP` | `#fbbf24` (amarelo) |
| Símbolo | `SIM` | `#fb7185` (vermelho) |

### 1.3 Narrativa da fase

Depois do Reino dos Tokens, o jogador cruza um portal e chega ao Vale do Scanner, um desfiladeiro de pedra cortado por uma cachoeira.

Espalhados pelas plataformas do vale estão cinco blocos de rocha. São os pedaços em que o Scanner quebrou uma linha de código. Cada bloco tem gravado o seu lexema e, na etiqueta colorida, a categoria a que pertence.

No meio do caminho há um abismo. A ponte que o cruzava está incompleta e tem cinco encaixes vazios. Um estudante ficou preso do outro lado.

Os blocos só assentam na ordem em que o código é lido, da esquerda para a direita. Se o jogador força uma pedra fora de ordem, a ponte desaba e ele volta ao ponto de partida, porque um analisador léxico não retoma a leitura pelo meio.

Com o quinto bloco no lugar, a ponte fecha, a travessia libera e o portal de saída abre. Os tokens estão reconhecidos e ordenados para o Parser da fase seguinte.

Cada elemento da ficção corresponde a um elemento da teoria. A ponte incompleta é a saída do Scanner que ainda não foi produzida. A ordem obrigatória dos encaixes é a leitura sequencial do fluxo de entrada. O desabamento ao errar é o reinício da varredura. O jogador executa o algoritmo em vez de decorá-lo.

---

## 2. 📋 Especificação de Requisitos

### 2.1 Requisitos funcionais (RF)

| ID | Descrição | Prioridade |
|---|---|---|
| **RF-01** | O jogo deve permitir que o jogador se movimente pelo vale (A/D ou setas), pule (W/↑/Espaço) e desça de plataformas atravessáveis (S/↓). | Alta |
| **RF-02** | O jogador deve poder pegar e soltar um bloco de token com a tecla **E**, carregando-o acima da cabeça enquanto se move e pula. | Alta |
| **RF-03** | O sistema deve aceitar a entrega de um bloco no encaixe da ponte apenas se ele for o próximo token da sequência léxica correta. | Alta |
| **RF-04** | A cada bloco entregue corretamente, o segmento correspondente da ponte deve se tornar visível e sólido (colisão habilitada). | Alta |
| **RF-05** | Ao entregar um bloco na posição errada da sequência, o sistema deve penalizar o jogador (−5 pontos e −1 vida) e reiniciar a sequência de blocos. | Alta |
| **RF-06** | Com os cinco blocos entregues, a barreira de passagem deve ser removida, a superfície de travessia habilitada e o portal de saída ativado. | Alta |
| **RF-07** | O sistema deve calcular a pontuação com acerto (+10 e bônus de combo progressivo), erro (−5), dica (−5), conclusão da fase (+50), fase sem erros (+30) e bônus de velocidade. | Alta |
| **RF-08** | O HUD deve exibir em tempo real: código-fonte colorido, ordem esperada dos tokens, blocos entregues (`x/5`), pontuação, vidas, combo e tempo decorrido. | Alta |
| **RF-09** | O jogo deve permitir pausar a partida a qualquer momento com **ESC** ou pelo botão do HUD. | Média |
| **RF-10** | O jogador deve poder consultar o objetivo da fase e pedir uma dica a qualquer momento durante a partida. | Média |
| **RF-11** | Ao cair do mapa ou perder uma vida, o jogador deve renascer no ponto de spawn com a sequência de blocos e a ponte reiniciadas. | Alta |
| **RF-12** | Ao perder as três vidas, a fase deve exibir a tela de Game Over com opção de tentar novamente ou retornar ao menu. | Alta |
| **RF-13** | Ao concluir a fase, o sistema deve registrar a conclusão no `GameManager` e liberar o progresso global para a fase seguinte. | Alta |

### 2.2 Requisitos não funcionais (RNF)

| ID | Descrição | Categoria |
|---|---|---|
| **RNF-01** | A fase deve ser desenvolvida em Godot 4 com GDScript, seguindo os padrões de `docs/arquitetura.md`. | Padrão / Manutenção |
| **RNF-02** | A interface da fase deve reutilizar o HUD comum (`scenes/common/game_hud.tscn`) para manter a identidade visual do jogo. | Usabilidade |
| **RNF-03** | O jogador deve reutilizar a cena comum `scenes/common/player.tscn`, de modo que os controles sejam idênticos aos das demais fases. | Consistência |
| **RNF-04** | A pontuação, vidas e progressão devem ser controladas exclusivamente pelo autoload `GameManager`, sem estado duplicado na fase. | Arquitetura |
| **RNF-05** | Todo efeito sonoro deve ser disparado pelo autoload `SoundManager`, com assets de licença livre creditados em `audio/README.md`. | Padrão / Licenciamento |
| **RNF-06** | O encaixe do bloco deve ser tolerante (raio de 150 px ao soltar, 28 px por proximidade física) para não exigir precisão de pixel do jogador. | Usabilidade |
| **RNF-07** | A lógica de sequenciamento léxico deve ser testável sem interface gráfica (execução headless em CI/terminal). | Testabilidade |
| **RNF-08** | Plataformas e encaixes da ponte devem ser editáveis diretamente no editor 2D do Godot (`@tool`), sem exigir alteração de código. | Manutenção |
| **RNF-09** | A fase deve rodar em resolução 1280×720 mantendo a estética pixel art (`TEXTURE_FILTER_NEAREST`). | Desempenho / Visual |

### 2.3 Requisitos pedagógicos (RP)

| ID | Descrição | Mapeamento no Jogo |
|---|---|---|
| **RP-01** | O jogo deve apresentar a definição de token, lexema e categoria antes de exigir a ação do jogador. | Modal de introdução com a legenda `PAL / ID / NUM / OP / SIM` |
| **RP-02** | Cada token deve exibir sua categoria léxica de forma visual e permanente durante a partida. | Etiqueta colorida na face do bloco |
| **RP-03** | O jogo deve informar qual é o próximo token esperado após cada acerto, para que o jogador acompanhe a leitura sequencial. | Feedback no HUD: *"Bloco alinhado: int. Próximo: x."* |
| **RP-04** | O jogo deve sinalizar e explicar o erro quando o jogador entregar um token fora de ordem. | Mensagem no HUD + som de erro + reinício da sequência |
| **RP-05** | Deve existir um sistema de dicas com custo de pontuação, indicando o próximo bloco correto. | Botão "Pedir Dica" (−5 pontos) |
| **RP-06** | O objetivo pedagógico deve estar disponível para consulta a qualquer momento, sem penalidade. | Botão "Objetivo", que exibe o conceito e o código-fonte atual |
| **RP-07** | Ao concluir a fase, o jogo deve fechar o raciocínio ligando o Scanner à etapa seguinte da compilação. | Tela de conclusão: *"Os tokens agora estão prontos para o Parser!"* |
| **RP-08** | O código-fonte completo deve ficar visível e colorido por categoria durante toda a partida, servindo de referência. | Barra de código-fonte no HUD (`ScannerData.source_bbcode`) |

---

## 3. 🕹️ Game Design Document (GDD da Fase)

### 3.1 Identidade

- **Nome:** Vale do Scanner
- **Posição na campanha:** Fase 2 de 6
- **Tema visual:** vale rochoso com cachoeira, penhascos, plataformas de pedra e vegetação
- **Trilha e efeitos:** sons de passo, salto, coleta, confirmação, erro, dano e portal (via `SoundManager`)

### 3.2 Mecânica principal

Plataforma 2D com coleta e transporte sequencial de objetos. A física dos blocos usa `RigidBody2D`: eles caem, deslizam e podem ser derrubados. Ao serem carregados, ficam congelados e presos acima da cabeça do jogador.

### 3.3 Controles

| Ação | Tecla |
|---|---|
| Mover | `A` / `D` ou `←` / `→` |
| Pular | `W`, `↑` ou `Espaço` |
| Descer da plataforma | `S` / `↓` |
| Pegar / soltar bloco | `E` |
| Pausar | `ESC` |

### 3.4 Código-fonte do desafio

```c
int x = 10;
```

| Ordem | Lexema | Categoria | Explicação exibida ao jogador |
|:---:|---|---|---|
| 1 | `int` | Palavra-chave (`PAL`) | Palavra reservada utilizada para declarar uma variável inteira. |
| 2 | `x` | Identificador (`ID`) | Nome utilizado para identificar uma variável. |
| 3 | `=` | Operador (`OP`) | Operador que atribui um valor à variável. |
| 4 | `10` | Número (`NUM`) | Valor numérico inteiro encontrado no código. |
| 5 | `;` | Símbolo (`SIM`) | Símbolo que indica o final da instrução. |

> **Conteúdo adicional implementado.** `ScannerData.challenges()` define um segundo desafio, `if (x > 10) return x;`, com nove tokens e duas ocorrências do identificador `x`. A lógica de sequência e os testes automatizados cobrem esse desafio, mas ele não está ativo na build entregue: `main.gd` carrega apenas o primeiro, para manter o percurso único e a sessão curta o bastante para as oficinas. Para ativá-lo, basta incluir `ScannerData.challenges()[1]` no array `challenges`.

### 3.5 Regras de pontuação

Todas as regras são centralizadas no autoload `GameManager`.

| Evento | Efeito |
|---|---|
| Bloco entregue na ordem correta | **+10 pontos** + bônus de combo |
| Combo (acertos consecutivos) | 10, 12, 14, 18 ... pontos conforme a sequência avança |
| Bloco entregue fora de ordem | **−5 pontos** e **−1 vida** |
| Colisão com perigo / queda do mapa | **−5 pontos** e **−1 vida** |
| Uso de dica | **−5 pontos** (não custa vida) |
| Conclusão da fase | **+50 pontos** |
| Conclusão sem nenhum erro | **+30 pontos** adicionais |
| Bônus de velocidade | `max(120 − tempo_em_segundos, 0)` pontos |

A pontuação nunca fica negativa. Cada desafio cria um *checkpoint* no `GameManager`, permitindo `rollback` da pontuação ao reiniciar.

### 3.6 Condições de vitória e derrota

- **Vitória:** entregar os 5 blocos na ordem léxica correta, atravessar a ponte e entrar no portal de saída.
- **Derrota:** perder as 3 vidas (por entrega incorreta, perigo ou queda do mapa) → tela de Game Over.

### 3.7 Ciclo de recuperação

Ao perder uma vida e ainda restar pelo menos uma:

1. O bloco carregado é solto;
2. Todos os blocos retornam à posição inicial (`reset_to_start`);
3. A ponte é totalmente reiniciada (`reset_bridge`) e a barreira volta a bloquear;
4. O contador de entregas volta a `0/5` e a sequência recomeça pelo `int`;
5. O jogador renasce no spawn com 1 segundo de invulnerabilidade.

O reinício completo é intencional: o Scanner lê o fluxo de entrada desde o início e não retoma do meio.

---

## 4. 🏛️ Arquitetura e Modelagem no Godot

### 4.1 Árvore de cenas

```text
Fase2Scanner (Node2D)  -- scripts/fase2_scanner/main.gd
├── Background (Node2D)
│   └── ValleySky (Sprite2D)              # fundo único escalado para 2560x720
│       └── [decorações: penhasco, plataformas de pedra]
├── Terrain (Node2D)
│   └── LeftCliff (Sprite2D)
├── Platforms (Node2D)                    # colisões editáveis via CollisionPolygon2D
│   ├── PortalPlatformBody (StaticBody2D)
│   ├── WidePlatformLeftBody / UpperLeftBody / CenterBody / HighBody / RightBody
│   ├── SmallPlatformCenterBody
│   ├── CliffTopBody / TerrainCliffBody / MissingPlatformBody
│   ├── BridgeLeftTopBody
│   ├── BridgeRightSurfaceBody            # habilitada só com a ponte completa
│   └── BridgeGateBody                    # barreira; desabilitada com a ponte completa
├── Bridge (Node2D)
├── BridgeSlots (Node2D)
│   └── BridgeProgress (Node2D)           -- bridge_progress.gd
│       └── BridgeSlot01 .. BridgeSlot05  -- bridge_slot.tscn / bridge_slot.gd (@tool)
├── BridgeStudentNPC                      -- bridge_student_npc.tscn
├── Vines (Node2D) / Decorations (Node2D)
├── WorldBounds (StaticBody2D)
│   ├── LeftWall (CollisionShape2D)
│   └── RightWall (CollisionShape2D)
├── Portals (Node2D)
│   ├── EntryPortal                       -- portal.tscn ("ENTRADA")
│   └── ExitPortal                        -- portal.tscn (ativado ao fim)
├── Player                                -- res://scenes/common/player.tscn
│   └── Camera2D
├── AlignmentRack                         -- alignment_rack.tscn (indica o próximo token)
├── BlockContainer (Node2D)               # recebe os token_block.tscn instanciados
└── [HUD instanciado em runtime]          -- res://scenes/common/game_hud.tscn
```

### 4.2 Scripts da fase

| Arquivo | Linhas | Responsabilidade |
|---|:---:|---|
| `scripts/fase2_scanner/main.gd` | 365 | Orquestração da fase: máquina de estados, spawn de blocos, pontuação, HUD, portais, vidas e conclusão. |
| `scripts/fase2_scanner/scanner_data.gd` | 65 | Fonte de dados dos desafios: lexemas, categorias, explicações, cores e formatação BBCode do código-fonte. |
| `scripts/fase2_scanner/scanner_sequence.gd` | 34 | Validador puro da sequência léxica (`try_accept`, `matches_next`, `is_complete`), sem dependência de cena. |
| `scripts/fase2_scanner/token_block.gd` | 131 | Bloco físico (`RigidBody2D`): visual do token, carregar, soltar, encaixar, ocultar e reiniciar. |
| `scripts/fase2_scanner/bridge_progress.gd` | 29 | Controla a ativação dos 5 segmentos e emite `bridge_completed`. |
| `scripts/fase2_scanner/bridge_slot.gd` | 58 | Segmento da ponte (`@tool`): recorta a arte por índice e liga/desliga a colisão. |
| `scripts/fase2_scanner/alignment_rack.gd` | 20 | Estação de alinhamento: exibe o próximo token esperado no destino. |
| `scripts/fase2_scanner/portal.gd` | 56 | Portal de entrada e saída, com rótulo, estado ativo e sinal `entered`. |
| `scripts/fase2_scanner/editable_platform.gd` | 61 | Plataforma com colisão editável no editor 2D. |
| `scripts/fase2_scanner/level_art.gd` | 61 | Composição e escala da arte do cenário. |
| `scripts/fase2_scanner/bridge_student_npc.gd` | 19 | NPC ambiental do cenário. |
| `scripts/fase2_scanner/scanner_token.gd` | 57 | Token de cenário (variante visual). |

Total: 12 scripts, cerca de 956 linhas de GDScript.

### 4.3 Máquina de estados

Definida em `main.gd` como `enum PhaseState`:

```text
                    ┌──────────────────────────────────────┐
                    ▼                                      │
   [INTRO] --confirmar intro--> [PLAYING] --ESC--> [PAUSED]─┘
                                    │
                                    │ 5º bloco entregue + ponte completa
                                    ▼
                             [PORTAL_READY]
                                    │ jogador entra no portal de saída
                                    ▼
                              [TRANSITION]
                                    │
                                    ▼
                               [COMPLETE] --> menu / próxima fase

   Em qualquer ponto de PLAYING ou PORTAL_READY:
      erro / perigo / queda --> vidas > 0 --> volta a [PLAYING] (sequência reiniciada)
                           └--> vidas = 0 --> [GAME_OVER] --> retry / menu
```

### 4.4 Fluxo de uma entrega correta

```text
Jogador pressiona E perto do bloco
   └-> player.gd -> token_block.pick_up()      (freeze, reparent, offset da mão)
Jogador caminha até a estação e pressiona E
   └-> token_block.drop()
         └─ distância até o destino <= 150 px ?
              ├─ SIM e placement_enabled  -> _snap_into_slot() -> sinal "placed"
              ├─ SIM e NÃO habilitado     -> sinal "wrong_placement" -> penalidade
              └─ NÃO                      -> bloco cai no chão (sem penalidade)
   └-> main._on_block_placed()
         ├─ SoundManager.play_confirmation()
         ├─ BridgeProgress.activate_slot(n)   -> segmento visível + colisão ativa
         ├─ GameManager.register_correct_action()  -> +10 + combo
         ├─ HUD: progresso, ordem da ponte e próximo token
         └─ habilita apenas o próximo bloco da sequência
   └-> ao 5º slot: BridgeProgress emite "bridge_completed"
         ├─ BridgeRightSurfaceBody.disabled = false   (caminho liberado)
         ├─ BridgeGateBody.disabled = true            (barreira removida)
         └─ estado = PORTAL_READY, portal de saída ativado
```

### 4.5 Integração com os sistemas globais

| Sistema | Uso na Fase 2 |
|---|---|
| `GameManager` (autoload) | `begin_phase(2)`, `register_correct_action`, `register_mistake`, `register_hint`, `register_time_bonus`, `create_checkpoint`, `rollback_to`, `complete_phase(2, flawless)`, sinal `game_over`. |
| `SoundManager` (autoload) | `play_confirmation`, `play_error`, `play_hurt`, `play_portal`, `play_lift`, `play_jump`, `play_footstep`. |
| `scenes/common/game_hud.tscn` | HUD compartilhado: pontuação, vidas, combo, tempo, intro, pause, objetivo, dica, game over e conclusão. |
| `scenes/common/player.tscn` | Personagem comum, com animações de carregar bloco (`andar_carregando`, pose de transporte). |
| `scenes/menu/menu.tscn` | Retorno ao menu e desbloqueio da fase seguinte pelo progresso registrado. |

### 4.6 Decisões técnicas registradas

A validação da sequência é feita por habilitação e não por bloqueio. Qualquer bloco pode ser carregado, mas só o bloco correto tem `placement_enabled = true`. O jogador consegue tentar a entrega errada e ver o que acontece, em vez de a ação ser simplesmente impedida.

A tolerância de encaixe é ampla de propósito: 150 px de raio ao soltar o bloco e 28 px por proximidade física. A fase cobra o conceito, não a precisão de pixel.

Blocos já entregues continuam na árvore de nós. O método `hide_after_delivery()` apenas os oculta, para que um reinício por queda consiga restaurar a sequência inteira com `reset_to_start()`.

Os segmentos da ponte usam `@tool`, o que permite à equipe de Interface posicionar a arte e editar os polígonos de colisão direto no editor 2D, sem tocar em código.

As posições de spawn são associadas ao lexema e não ao índice. O dicionário `platform_starts` garante que cada bloco nasça sobre uma plataforma com colisão, independentemente da ordem do Scanner.

`ScannerSequence` estende `RefCounted` e não depende de nós de cena, o que permite testar toda a regra léxica em modo headless.

---

## 5. 🧪 Plano e Casos de Teste

### 5.1 Testes automatizados (headless)

Arquivo: [`tests/headless_scanner_test.gd`](../../tests/headless_scanner_test.gd)

```bash
godot --headless --script tests/headless_scanner_test.gd
```

Saída esperada: `PASS: scanner, pontuação, rollback e vidas`

Arquivo de captura visual: [`tests/visual_phase2_capture.gd`](../../tests/visual_phase2_capture.gd), que gera as capturas da fase para as evidências AEX.

### 5.2 Casos de teste

| ID Caso | Requisito | Ação Realizada | Resultado Esperado | Status |
|---|---|---|---|---|
| **CT-01** | RF-03, RP-03 | Entregar `int` como primeiro bloco | Slot 01 ativado, +10 pontos, feedback indica `x` como próximo | ✅ PASS |
| **CT-02** | RF-03 | Tentar entregar `x` antes de `int` | `try_accept` retorna `WRONG` e o índice esperado permanece em 0 | ✅ PASS *(automatizado)* |
| **CT-03** | RF-03 | Entregar os 5 blocos na ordem correta | Retorna `ACCEPTED` a cada passo e `COMPLETE` no quinto | ✅ PASS *(automatizado)* |
| **CT-04** | RF-05, RP-04 | Soltar bloco fora de ordem dentro do raio da estação | Som de erro, −5 pontos, −1 vida e sequência reiniciada em 0/5 | ✅ PASS |
| **CT-05** | RF-04 | Entregar bloco correto | Segmento da ponte fica visível e sua colisão é habilitada | ✅ PASS |
| **CT-06** | RF-06 | Completar os 5 encaixes | `bridge_completed` emitido, barreira removida, superfície liberada e portal de saída ativado | ✅ PASS |
| **CT-07** | RF-06 | Tentar entrar no portal de saída com a ponte incompleta | Portal permanece inativo e não dispara transição | ✅ PASS |
| **CT-08** | RF-02 | Pressionar `E` próximo a um bloco e caminhar/pular | Bloco fixado acima da cabeça, animação de transporte ativa, física congelada | ✅ PASS |
| **CT-09** | RF-11 | Cair fora do mapa | −1 vida, blocos e ponte reiniciados, respawn no ponto de entrada com 1s de invulnerabilidade | ✅ PASS |
| **CT-10** | RF-07 | Encadear 4 acertos consecutivos | Pontuação acumula 10 + 12 + 14 + 18 = 54 pontos | ✅ PASS *(automatizado)* |
| **CT-11** | RF-07 | Criar checkpoint, pontuar e executar rollback | Rollback remove apenas os pontos posteriores ao checkpoint | ✅ PASS *(automatizado)* |
| **CT-12** | RF-07 | Aplicar penalidade com a pontuação zerada | Pontuação nunca fica negativa | ✅ PASS *(automatizado)* |
| **CT-13** | RF-12 | Cometer 3 erros com custo de vida (e um quarto) | Vidas chegam a 0 e `game_over` é emitido uma única vez | ✅ PASS *(automatizado)* |
| **CT-14** | RF-09 | Pressionar `ESC` durante a partida | Menu de pause exibido, controles desabilitados e o estado anterior restaurado ao retomar | ✅ PASS |
| **CT-15** | RF-10, RP-05 | Acionar "Pedir Dica" | −5 pontos e mensagem indicando o bloco correto e a dica do desafio | ✅ PASS |
| **CT-16** | RF-10, RP-06 | Acionar "Objetivo" | Modal com o conceito do Scanner e o código-fonte atual, sem custo de pontuação | ✅ PASS |
| **CT-17** | RF-13, RP-07 | Concluir a fase | Bônus de velocidade e de fase aplicados, tela de conclusão citando o Parser e progresso registrado | ✅ PASS |
| **CT-18** | RP-01, RP-08 | Iniciar a fase | Modal de introdução com a legenda das 5 categorias e código-fonte colorido no HUD | ✅ PASS |
| **CT-19** | RNF-02, RNF-03 | Comparar HUD e controles com a Fase 1 | Mesmo HUD e mesmo esquema de controles | ✅ PASS |
| **CT-20** | RF-03 (desafio 2) | Validar `if (x > 10) return x;` com as duas ocorrências de `x` trocadas entre si | Sequência é aceita e concluída, porque identificadores de mesmo lexema e categoria são equivalentes | ✅ PASS *(automatizado)* |

Dos 20 casos, 7 são verificados pela bateria automatizada headless e 13 por teste manual conduzido pela equipe de QA. Todos foram aprovados.

---

## 6. 👥 Matriz RACI de Responsabilidades

A matriz abaixo define os papéis de cada função nos entregáveis da fase. Para a definição teórica do modelo, consulte [docs/engenharia_software.md](../engenharia_software.md).

### Definições dos papéis

- **R (Responsável / *Responsible*):** quem executa a tarefa ("mão na massa").
- **A (Aprovador / *Accountable*):** quem valida e responde pelo resultado final (apenas 1 por atividade).
- **C (Consultado / *Consulted*):** quem dá apoio técnico, pedagógico ou artístico antes/durante a tarefa.
- **I (Informado / *Informed*):** quem é notificado sobre a conclusão.

### Tabela de responsabilidades do grupo

| Atividade / Entregável | **Líder**<br>Pedro Carulla | **Conteúdo**<br>José Neres<br>Eduardo Mattos | **Interface**<br>Felipe Muraro<br>Richard Ribeiro | **Programação**<br>Heitor Vidal<br>Gustavo Favorin | **Testes**<br>Filipe Sudário | **Documentação**<br>Pedro Gomes<br>Caio Nogueira |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Planejamento e cronograma da fase | **R** / **A** | C | C | C | C | I |
| Definição do conceito léxico e do código-fonte | **A** | **R** | I | C | I | C |
| Redação dos textos didáticos (intro, dicas, feedback) | **A** | **R** | C | I | C | C |
| Arte e composição do cenário do vale | **A** | I | **R** | C | I | I |
| Design visual dos blocos de token e da ponte | **A** | C | **R** | C | C | I |
| Integração com o HUD comum | **A** | I | **R** | C | C | I |
| Modelagem da cena no Godot (`main.tscn`) | **A** | I | **R** | C | I | I |
| Programação da mecânica de carregar/entregar | **A** | I | C | **R** | C | I |
| Lógica de sequenciamento léxico (`ScannerSequence`) | **A** | C | I | **R** | C | I |
| Sistema de progresso da ponte e portais | **A** | I | C | **R** | C | I |
| Integração com `GameManager` e `SoundManager` | **A** | I | I | **R** | C | I |
| Elaboração do plano de testes | C | C | I | C | **R** / **A** | C |
| Execução dos testes automatizados (headless) | I | I | I | C | **R** / **A** | I |
| Execução dos testes manuais de jogabilidade | C | C | C | C | **R** / **A** | I |
| Balanceamento de dificuldade e pontuação | **A** | C | C | C | **R** | I |
| Documentação de engenharia da fase | **A** | C | C | C | C | **R** |
| Coleta e organização das evidências AEX | **A** | C | C | C | C | **R** |
| Versionamento e integração no GitHub (PRs) | **R** / **A** | I | C | C | I | I |

---

## 7. 📦 Entregáveis e Rastreabilidade

### 7.1 Artefatos produzidos pelo grupo

| Tipo | Caminho | Quantidade |
|---|---|---|
| Cenas Godot | `scenes/fase2_scanner/` | 8 |
| Scripts GDScript | `scripts/fase2_scanner/` | 12 (~956 linhas) |
| Assets visuais | `assets/fase2_scanner/` | 28 imagens (cenário, ponte, personagem carregando, NPC, portal) |
| Testes | `tests/headless_scanner_test.gd`, `tests/visual_phase2_capture.gd` (+ `.tscn`) | 3 |
| Documentação | `docs/fases/fase2_scanner.md`, `docs/evidencias_fase2.md` | 2 |

### 7.2 Rastreabilidade de requisito, implementação e teste

| Requisito | Implementado em | Verificado por |
|---|---|---|
| RF-01, RF-02 | `scripts/common/player.gd`, `token_block.gd` | CT-08 |
| RF-03 | `scanner_sequence.gd`, `main.gd::_set_active_sequence_block` | CT-01, CT-02, CT-03, CT-20 |
| RF-04 | `bridge_progress.gd`, `bridge_slot.gd` | CT-05 |
| RF-05 | `token_block.gd::drop`, `main.gd::_on_wrong_block_placed` | CT-04 |
| RF-06 | `main.gd::_on_bridge_completed`, `portal.gd` | CT-06, CT-07 |
| RF-07 | `game_manager.gd` | CT-10, CT-11, CT-12, CT-15 |
| RF-08 | `game_hud.gd`, `scanner_data.gd::source_bbcode` | CT-18, CT-19 |
| RF-09 | `main.gd::_pause_game / _resume_game` | CT-14 |
| RF-10 | `main.gd::_use_hint / _show_objective` | CT-15, CT-16 |
| RF-11 | `main.gd::_on_hazard_body_entered`, `token_block.gd::reset_to_start` | CT-09 |
| RF-12 | `main.gd::_on_game_over` | CT-13 |
| RF-13 | `main.gd::_complete_phase`, `game_manager.gd::complete_phase` | CT-17 |
| RP-01 a RP-08 | `scanner_data.gd`, `main.gd::_intro_text / _objective_text` | CT-01, CT-04, CT-15, CT-16, CT-17, CT-18 |

---

## 8. 📝 Histórico de Revisões e Modificações

| Data | Versão | Descrição da Alteração | Autor |
|---|---|---|---|
| 03/08/2026 | 0.0 | Início do projeto: repositório criado e grupos definidos | Prof. Luciano Rovanni |
| 11/08/2026 | 0.1 | Implementação inicial da Fase 2 Scanner e integração com a progressão global | Felipe Muraro (`gitmuraro`) |
| 13/08/2026 | 0.2 | Ajustes de cenário, plataformas e arte da fase | Felipe Muraro (`gitmuraro`) |
| 24/08/2026 | 0.3 | Revisão da mecânica de blocos, da ponte e dos portais; merge da branch `fase2` | Heitor Vidal (`Oaluah`) |
| 25/08/2026 | 1.0 | Versão final da Fase 2 entregue | Heitor Vidal (`Oaluah`) |
| 29/08/2026 | 1.1 | Criação da documentação de engenharia e das evidências AEX da fase | Pedro Gomes e Caio Nogueira |

---

## 9. 🔗 Referências

- [README principal do projeto](../../README.md)
- [Guia de Engenharia de Software](../engenharia_software.md)
- [Arquitetura Técnica](../arquitetura.md)
- [Diretrizes Pedagógicas](../pedagogico.md)
- [Guia de Testes](../guia_testes.md)
- [Guia de Evidências AEX](../aex_evidencias.md)
- [Evidências AEX da Fase 2](../evidencias_fase2.md)
