# 📑 Documento de Engenharia de Software – Fase 3: A Caverna do Parser

> **Grupo:** 3  
> **Fase:** A Caverna do Parser (Análise Sintática)  
> **Tema:** Gramática, Regras de Produção e Construção de Sentenças  
> **Integrantes e Funções:**  
> - Gustavo Alexandro Pelissari: Desenvolvedor/Líder Técnico – Programação, Integração e Mecânicas  
> - Anna Flávia Guenta Tsurushima, Giovanna Beatriz Ramos e Letícia Aparecida Fernandes: Designer UI/UX – Sprites, Shaders, UI de Chefões e Identidade Visual  
> - Igor Henrique Koga Vigato: Analista de QA – Correção de Bugs, Testes de Integração e Assets  
> - Igor Henrique Koga Vigato: Pesquisador Pedagógico – Mapeamento da Gramática e Casos de Uso Sintáticos  

---

## 1. 🎯 Descrição Geral e Objetivos Pedagógicos

### 1.1 Visão Geral da Fase
A **Caverna do Parser** é uma fase de exploração top-down e combate estratégico com chefões (Gosma, Fantasma e o Rei Parser). O jogador explora uma sala principal de lava com múltiplos portais que levam a arenas de chefões. Dentro de cada arena, o jogador precisa pisar em placas de pressão (*pressure plates*) na ordem sintática correta para montar expressões e comandos válidos de programação, disparando ataques contra os chefões e evitando contra-ataques causados por erros sintáticos. Ao vencer o chefe final, o jogador assiste a uma cutscene com botão de "Pular" estilizado.

### 1.2 Conceito de Compiladores Abordado
Esta fase ensina os fundamentos da **Análise Sintática (Parsing)**:
- Ordem e precedência de símbolos e palavras-chave em uma linguagem de programação.
- Validação de regras gramaticais e estruturas de controle (`if`, `while`, declaração de variáveis `var x = 10`, etc.).
- Categorias de sentenças sintáticas por dificuldade:
  - **4 Placas (Boss Gosma)**: Declarações (`var`, `let`, `const`, tipos), condicionais e laços básicos (`if`, `while`), chamadas de função (`print`, `draw`, `play`), retornos e métodos de objetos.
  - **5 Placas (Boss Fantasma)**: Declarações terminadas com `;`, condicionais relacionais (`==`, `!=`, `<`, `>`), laços controlados, operações aritméticas e manipulações de estruturas do compilador (`parser.next_token()`, `stack.push(val)`).
  - **6 Placas (Boss Rei Parser)**: Estruturas completas com corpos de bloco, condicionais lógicas compostas, laços `for/while`, manipulação de nós na AST (`ast.add_child(node)`), consumo de tokens (`parser.consume(TOKEN_ID)`) e herança/classes.
- Detecção e tratamento de erros sintáticos (quando a ordem dos tokens não respeita a gramática).

---

## 2. 📋 Especificação de Requisitos

### 2.1 Requisitos Funcionais (RF)
| ID | Descrição | Prioridade |
|---|---|---|
| **RF-01** | O jogador deve conseguir se movimentar em 4 direções (W, A, S, D ou Setas) e interagir com portais via tecla `E` ou `Enter`. | Alta |
| **RF-02** | O sistema deve gerar desafios com sequências de tokens embaralhados em placas de pressão. | Alta |
| **RF-03** | Ao pisar em todas as placas na ordem sintática correta, o jogador dispara um projétil contra o chefão. | Alta |
| **RF-04** | Se o jogador pisar em qualquer placa fora de ordem (mesmo no 1º elemento), o erro é detectado imediatamente, o chefão contra-ataca e o jogador perde vida. | Alta |
| **RF-05** | Ao zerar a vida do chefão, a arena libera o portal de vitória para retornar à sala principal. | Alta |
| **RF-06** | O jogador pode alternar a exibição de dicas: quando ativada, a placa do próximo token esperado é iluminada em verde dinamicamente. | Média |
| **RF-07** | O jogador pode pular a cutscene final através de um botão estilizado na interface. | Média |
| **RF-08** | O jogador pode retornar ao Menu Principal ou à Sala Principal pressionando `ESC` ou clicando nos botões de retorno. | Alta |

### 2.2 Requisitos Não-Funcionais (RNF)
| ID | Descrição | Categoria |
|---|---|---|
| **RNF-01** | Desenvolvido no Godot Engine 4 com GDScript. | Padrão Tecnológico |
| **RNF-02** | Responsivo em resolução 1280x720 / canvas_items. | Interface / Resolução |
| **RNF-03** | Animações fluidas de sprites para o jogador, efeitos e chefões. | Usabilidade |
| **RNF-04** | Uso de Shaders e `CanvasItemMaterial` com Blend Mode Additive para transparência visual dos portais. | Gráficos/Visuais |
| **RNF-05** | Rotação vetorial matemática dos projéteis animados para apontarem para os alvos (180º graus de calibração). | Física / Renderização |


### 2.3 Requisitos Pedagógicos (RP)
| ID | Descrição | Mapeamento no Jogo |
|---|---|---|
| **RP-01** | Exercitar a construção sintática correta de declarações, condicionais e laços. | Placas de Pressão ordenadas |
| **RP-02** | Exibir mensagens de sucesso e erro sintático contextualizadas. | Feedback no painel de descrição |
| **RP-03** | Modo didático com dicas que destacam o próximo token válido em verde. | Botão "Ativar Dica" (destaque visual) |

---

## 3. 🕹️ Game Design Document (GDD da Fase)

- **Mecânica Principal:** Ação e puzzle top-down 2D. Arena Boss-fight baseada em ordenação sintática.
- **Vidas:** 3 corações exibidos no HUD.
- **Progressão Visual:** A barra de vida dos Bosses possui cor e assets distintos. Projéteis de ataque são sprites animados distintos.
- **Condição de Vitória:** Derrotar o chefão completando as sequências sintáticas corretas até zerar seus pontos de vida. Boss tem animação de morte.
- **Condição de Derrota:** Perder todas as 3 vidas por erros sintáticos sucessivos (reinicia a arena).

---

## 4. 🏛️ Arquitetura e Modelagem no Godot

### 4.1 Estrutura de Arquivos
```text
res://
├── assets/fase3_parser/
│   ├── audio/               # Trilhas e efeitos sonoros dos chefões e jogador
│   │   ├── edu/             # Sons do jogador (ataque, morte, vitória)
│   │   ├── fantasma/        # BGM, entrada, dano, meia vida, morte e vitória do Fantasma
│   │   ├── reiParser/       # BGM, entrada, dano, morte e vitória do Rei Parser
│   │   ├── slime/           # BGM, entrada, dano, meia vida, morte e vitória da Gosma
│   │   └── escolha_boss.mp3 # Música tema da Sala Principal / Escolha de Chefão
│   ├── backgrouds/          # Imagens de fundo das arenas e sala principal
│   └── sprites/             # Spritesheets de animações (jogador, monstros, efeitos)
│       └── health_bars/     # Barras de vida temáticas segmentadas (Gosma, Fantasma, Rei Parser)
├── scenes/fase3_parser/
│   ├── main_room.tscn       # Sala principal com portais de acesso
│   ├── boss_fight.tscn      # Arena base de combate
│   ├── boss_gosma.tscn      # Arena do Boss Gosma
│   ├── boss_fantasma.tscn   # Arena do Boss Fantasma
│   ├── boss_final.tscn      # Arena do Rei Parser (Boss Final)
│   ├── player.tscn          # Jogador com movimentação top-down e câmera
│   ├── pressure_plate.tscn  # Placas de pressão com tokens
│   ├── projectile.tscn      # Projétil de ataque/dano
│   └── boss_entrance.tscn   # Portal de teleporte para as arenas
├── scripts/fase3_parser/
│   ├── main_room.gd         # Gerenciamento da sala principal e portais
│   ├── boss_fight.gd        # Lógica de validação sintática, combate, barras de vida e áudio
│   ├── player.gd            # Física de movimento, vida, animação e áudio de dano
│   ├── pressure_plate.gd    # Detecção de acionamento das placas
│   ├── projectile.gd        # Movimentação e colisão de projéteis
│   ├── boss_body.gd         # Receptor de dano dos chefões
│   └── effect_helper.gd     # Utilitário para instanciação de efeitos visuais
└── tests/
    └── headless_fase3_parser_test.gd # Testes unitários de regras sintáticas, integridade de áudio e barras de vida
```

### 4.2 Estrutura de Diretórios e Scripts
- `scenes/fase3_parser/`: Contém as salas (Main Room, Bosses, Player, Projectile, Outro Cutscene).
- `scripts/fase3_parser/`:
  - `main_room.gd`: Gerenciamento da sala principal de seleção de chefões e portais de acesso.
  - `boss_fight.gd`: Core do gerenciador de batalhas, UI da vida dos chefões, controle de corações (AtlasTexture), cálculo de `death_scale_factor` e spawn direcional de projéteis.
  - `player.gd`: Física de movimento top-down, vida, e animação do jogador.
  - `pressure_plate.gd`: Lógica de detecção de acionamento das placas e tokens durante o combate.
  - `projectile.gd`: Movimento direcional angular (`rotation_degrees = 180`) e renderização por matriz de frames dinâmicos (`set_ghost_attack_sprite`, `set_player_attack_sprite`).
  - `boss_body.gd`: Receptor de colisões e sinais de dano dos chefões.
  - `boss_entrance.gd`: Lógica de transição/teleporte entre a arena e a sala principal.
  - `outro_cutscene.gd`: Gerenciamento do vídeo final, contendo lógica do botão de pular estilizado.
  - `effect_helper.gd`: Script utilitário (`class_name EffectHelper`) para carregar dinamicamente texturas e frames de efeitos no jogo.
  - `remove_bg.gdshader`: Shader para remover cores de fundo e lidar com a transparência (ex: efeitos de porta/ataques).

### 4.3 Fluxo Lógico (Máquina de Estados Simplificada)
1. **Idle**: Esperando input do jogador nas placas de pressão.
2. **Avaliação Sintática**: Analisa ordem do array de tokens.
3. **Acerto**: Toca `player_attack_sprite`, retira 1 vida da `BossHealthBar`, verifica morte do Boss.
4. **Erro**: Toca boss attack sprite (ex: `ghost_attack_sprite`), jogador perde 1 vida, atualiza corações de interface, verifica morte do Jogador.

---

## 5. 🧪 Plano e Casos de Teste

| ID Caso | Requisito Relacionado | Ação Realizada | Resultado Esperado | Status |
|---|---|---|---|:---:|
| **CT-01** | RF-01, RF-07 | Pressionar ESC ou botão MENU na sala principal | Retorna ao Menu Principal | ✅ PASS |
| **CT-02** | RNF-02 | Visualizar os Portais na Arena | Portal tem transparência e blend correto (fundo preto retirado). | ✅ PASS |
| **CT-03** | RF-03, RNF-04 | Pisar na ordem correta das placas | Projétil do jogador gerado, usando `player-attack.png` rotacionado para o chefão. | ✅ PASS |
| **CT-04** | RF-04, RNF-04 | Pisar na placa errada (Erro sintático) | Projétil do chefão (Gosma, Fantasma ou Final) gerado, animado e atinge jogador. | ✅ PASS |
| **CT-05** | RF-05 | Zerar vida do chefão | Chefão toca animação "dying" reduzida em 10%, portal é liberado. | ✅ PASS |
| **CT-06** | RF-06 | Pressionar o botão "Pular >>" | O botão exibe layout cinza opaco escuro customizado e pula a cutscene. | ✅ PASS |
| **CT-07** | RNF-03 | Visualizar HUD de Vidas | Corações escalados (25% maiores) e utilizam os frames corretos do spritesheet. | ✅ PASS |

---
