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
- Detecção e tratamento de erros sintáticos (quando a ordem dos tokens não respeita a gramática).

---

## 2. 📋 Especificação de Requisitos

### 2.1 Requisitos Funcionais (RF)
| ID | Descrição | Prioridade |
|---|---|---|
| **RF-01** | O jogador deve conseguir se movimentar em 4 direções (W, A, S, D ou Setas) e interagir com portais via tecla `E` ou `Enter`. | Alta |
| **RF-02** | O sistema deve gerar desafios com sequências de tokens embaralhados em placas de pressão. | Alta |
| **RF-03** | Ao pisar em todas as placas na ordem sintática correta, o jogador dispara um projétil contra o chefão. | Alta |
| **RF-04** | Se a sequência for inválida, o chefão contra-ataca disparando projéteis e o jogador perde vidas. | Alta |
| **RF-05** | Ao zerar a vida do chefão, a arena libera o portal de vitória para retornar à sala principal. | Alta |
| **RF-06** | O jogador pode alternar a exibição de dicas didáticas através do botão de dica. | Média |
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
| **RP-03** | Modo didático com dicas para apoiar alunos iniciantes. | Botão "Ativar Dica" |

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
└── scripts/fase3_parser/
    ├── main_room.gd         # Gerenciamento da sala principal e portais
    ├── boss_fight.gd        # Lógica de validação sintática e combate
    ├── player.gd            # Física de movimento, vida e animação
    ├── pressure_plate.gd    # Detecção de acionamento das placas
    ├── projectile.gd        # Movimentação e colisão de projéteis
    ├── boss_body.gd         # Receptor de dano dos chefões
    └── effect_helper.gd     # Utilitário para instanciação de efeitos visuais
```

---

## 5. 🧪 Plano e Casos de Teste

| ID Caso | Requisito Relacionado | Ação Realizada | Resultado Esperado | Status |
|---|---|---|---|:---:|
| **CT-01** | RF-01 | Selecionar Fase 3 no Menu Principal | Carrega a Sala Principal da Caverna do Parser | ✅ PASS |
| **CT-02** | RF-01, RF-07 | Pressionar ESC ou botão MENU na sala principal | Retorna ao Menu Principal | ✅ PASS |
| **CT-03** | RF-01 | Aproximar de um portal e pressionar E/Enter | Carrega a arena correspondente do Boss | ✅ PASS |
| **CT-04** | RF-03 | Pisar nas placas na sequência sintática correta | Projétil azul atinge o boss e reduz 1 de vida | ✅ PASS |
| **CT-05** | RF-04 | Pisar nas placas na ordem incorreta | Boss anima ataque e dispara projétil, player perde 1 vida | ✅ PASS |
| **CT-06** | RF-05 | Derrotar o chefão e entrar no portal de saída | Retorna à Sala Principal com vidas restauradas | ✅ PASS |
