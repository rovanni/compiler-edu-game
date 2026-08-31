# 📑 Documento de Engenharia de Software – Fase 3: A Caverna do Parser

> **Grupo:** 3  
> **Fase:** A Caverna do Parser (Análise Sintática)  
> **Tema:** Gramática, Regras de Produção e Construção de Sentenças  

---

## 1. 🎯 Descrição Geral e Objetivos Pedagógicos

### 1.1 Visão Geral da Fase
A **Caverna do Parser** é uma fase de exploração top-down e combate estratégico com chefões (Gosma, Fantasma e o Rei Parser). O jogador explora uma sala principal de lava com múltiplos portais que levam a arenas de chefões. Dentro de cada arena, o jogador precisa pisar em placas de pressão (*pressure plates*) na ordem sintática correta para montar expressões e comandos válidos de programação, disparando ataques contra os chefões e evitando contra-ataques causados por erros sintáticos.

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
| **RF-07** | O jogador pode retornar ao Menu Principal ou à Sala Principal pressionando `ESC` ou clicando nos botões de retorno. | Alta |

### 2.2 Requisitos Não-Funcionais (RNF)
| ID | Descrição | Categoria |
|---|---|---|
| **RNF-01** | Desenvolvido no Godot Engine 4 com GDScript. | Padrão Tecnológico |
| **RNF-02** | Responsivo em resolução 1280x720 / canvas_items. | Interface / Resolução |
| **RNF-03** | Animações fluidas de sprites para o jogador, efeitos e chefões. | Usabilidade |

### 2.3 Requisitos Pedagógicos (RP)
| ID | Descrição | Mapeamento no Jogo |
|---|---|---|
| **RP-01** | Exercitar a construção sintática correta de declarações, condicionais e laços. | Placas de Pressão ordenadas |
| **RP-02** | Exibir mensagens de sucesso e erro sintático contextualizadas. | Feedback no painel de descrição |
| **RP-03** | Modo didático com dicas que destacam o próximo token válido em verde. | Botão "Ativar Dica" (destaque visual) |

---

## 3. 🕹️ Game Design Document (GDD da Fase)

- **Mecânica Principal:** Ação e puzzle top-down 2D.
- **Vidas:** 3 corações exibidos no HUD com animações de dano e restauração ao vencer.
- **Condição de Vitória:** Derrotar o chefão completando as sequências sintáticas corretas até zerar seus pontos de vida.
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
│   ├── boss_fight.gd        # Lógica de validação sintática, combate, audio ducking e áudio
│   ├── player.gd            # Física de movimento, vida, animação e áudio de dano
│   ├── pressure_plate.gd    # Detecção de acionamento das placas
│   ├── projectile.gd        # Movimentação e colisão de projéteis
│   ├── boss_body.gd         # Receptor de dano dos chefões
│   └── effect_helper.gd     # Utilitário para instanciação de efeitos visuais
└── tests/
    └── headless_fase3_parser_test.gd # Testes unitários de regras sintáticas e integridade de áudio
```

---

## 5. 🧪 Plano e Casos de Teste

| ID Caso | Requisito Relacionado | Ação Realizada | Resultado Esperado | Status |
|---|---|---|---|:---:|
| **CT-01** | RF-01 | Selecionar Fase 3 no Menu Principal | Carrega a Sala Principal da Caverna do Parser | ✅ PASS |
| **CT-02** | RF-01, RF-07 | Pressionar ESC ou botão MENU na sala principal | Retorna ao Menu Principal | ✅ PASS |
| **CT-03** | RF-01 | Aproximar de um portal e pressionar E/Enter | Carrega a arena correspondente do Boss, toca BGM e som de entrada com ducking | ✅ PASS |
| **CT-04** | RF-03 | Pisar nas placas na sequência sintática correta | Toca som de ataque do Edu (abaixa o volume da BGM temporariamente), projeta projétil azul e boss sofre dano | ✅ PASS |
| **CT-05** | RF-04 | Pisar nas placas na ordem incorreta e zerar as vidas | Player morre (som de morte do Edu), chefão celebra (som de vitória do Boss) e retorna à sala | ✅ PASS |
| **CT-06** | RF-05 | Derrotar o chefão (ou Rei Parser) | Toca som de derrota do boss, vitória do Edu, e no Rei Parser encerra BGM para a cutscene | ✅ PASS |
| **CT-07** | RF-02, RP-01 | Execução do teste headless de tokens (`headless_fase3_parser_test.gd`) | Todas as sentenças de 3, 4, 5 e 6 tokens são validadas sem falhas | ✅ PASS |
| **CT-08** | RF-03, RF-04, RF-05 | Validação de integridade de arquivos de áudio | Todos os 23 arquivos de áudio dos chefões e jogador carregam perfeitamente | ✅ PASS |
