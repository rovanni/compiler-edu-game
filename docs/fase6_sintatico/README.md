# 📑 Documento de Engenharia de Software – Fase 6: Fortaleza Sintática

—
#Integrantes do grupo
| Função | Responsável | Índice|
|---|---|---|
| Líder e direção de conteúdo | Pedro Augusto Marchisepe de Matos |
| Arte | Igor Lobo Trabaquini |
| Programação | Felipe Augusto Santos Oliveira & João Francisco Patelli |
| Testes |Carlos Eduardo Costa Nardon |
| Documentação | Carlos Eduardo Costa Nardon & Felipe Augusto Santos Oliveira |

## 1. 🎯 Descrição Geral e Objetivos Pedagógicos

### 1.1 Visão Geral da Fase
A fase apresenta um cenário de fortaleza, em que o jogador é apresentado uma expressão de código, na cena caem vários balões que possuem vários símbolos da linguagem, o jogador deve deixar os caracteres presentes na expressão caírem na ordem correta, montando de forma correta a expressão e evitando erros sintáticos, os balões que representam caracteres que não estão na expressão ou que estão fora de ordem devem ser estourados com o canhão presenta na parte inferior da tela. O jogo é inspirado pelo clássico Space Invaders e o jogo mobile Magic Touch.

### 1.2 Conceito de Compiladores Abordado
O jogo procura ensinar conceitos básicos de análise sintática, com cada balão representando um token e o jogador deve realizar a análise do que deve ser permitido passar e em qual ordem, o ensinando os fundamentos de erros sintáticos e como evitá-los, dado que cabe ao jogador evitar esses erros, ao evitar os caracteres errados.

---

## 2. 📋 Especificação de Requisitos

### 2.1 Requisitos Funcionais (RF)
| ID | Descrição | Prioridade |
|---|---|---|
| **RF-01** | O jogo não deve ser longo. | Alta |
| **RF-02** | O jogo não deve ser difícil mas deve ter algum nível de desafio. | Alta |
| **RF-03** | O jogo deve permitir pausar a qualquer momento. | Média |
| **RF-04** | O jogo deve permitir sair a qualquer momento. | Alta |
| **RF-05** | O jogo deve ter gameplay e objetivos fáceis de entender. | Alta |
| **RF-06** | O jogo deve ter feedback imediato de erro e acerto. | Média |


### 2.2 Requisitos Não-Funcionais (RNF)
| ID | Descrição | Categoria |
|---|---|---|
| **RNF-01** | A fase deve ser desenvolvida utilizando Godot 4 em GDScript. | Desempenho / Padrão |
| **RNF-02** | A interface da fase deve manter a mesma identidade visual do HUD principal e outras fases. | Usabilidade |
| **RNF-03** | A arte e identidade visual da fase devem se manter parecidas ou as mesmas das outras fases. | Usabilidade |
| **RFN-04** | O jogo deve ter feedback imediato de erro e acerto. | Usabilidade |

---

## 3. 🕹️ Game Design Document (GDD da Fase)

- **Mecânica Principal:** O jogo é inspirado pela gameplay de Space Invaders e Magic Touch, a mecânica principal é atirar e estourar os balões que não pertencem à expressão antes que caiam ao chão.
- **Regras de Pontuação:** Cada balão estourado corretamente dá 1 ponto e 1 ponto de combo, quando o jogador estoura um balão que não deveria é perdido 1 ponto e o combo é quebrado. O combo serve somente para contabilizar quantos balões o jogador estourou corretamente de forma contínua.
  - Acerto: 1 ponto.
  - Erro (Balão errado cai): -10 pontos e -1 vida.
  - Erro (Balão estourado errado): -5 pontos e quebra de combo.
- **Condição de Vitória:** Completar a expressão deixando os balões corretos caírem na ordem correta.
- **Condição de Derrota:** Perder as 3 vidas (deixar 3 balões errados caírem).

---

## 4. 🏛️ Arquitetura e Modelagem no Godot

### 4.1 Árvore de Cenas (Godot Node Hierarchy)
```text
Main (Node2D) — scenes/fase6_sintatico/Main.tscn
├── GerenciadorExpressao (Node)
│   └── Controla a expressão-objetivo e o próximo símbolo esperado
├── SpawnerBaloes (Node2D)
│   ├── Timer (criado em runtime)
│   └── Balao (Area2D, instâncias criadas durante a partida)
├── Chao (Area2D)
│   ├── CollisionShape2D
│   └── ColorRect
├── Canhao (Node2D)
│   ├── Base (Polygon2D)
│   ├── Aro (Polygon2D)
│   ├── Tubo (Polygon2D)
│   └── Boca (Polygon2D)
├── UI (CanvasLayer)
│   ├── LabelExpressao
│   ├── LabelProgresso
│   ├── LabelMensagem
│   ├── LabelControles
│   └── OverlayMecanica
│       ├── Escurecer (ColorRect)
│       ├── AlertaFundo e AlertaExclamacoes (Label)
│       └── Painel com título, explicação e botão de confirmação
└── HUD (CanvasLayer, instanciado em runtime)
    └── scenes/common/game_hud.tscn

Elementos criados durante o jogo:
├── Projetil (Area2D) — filho de Main, criado pelo Canhao
└── EfeitoEstouro (AnimatedSprite2D) — criado ao resolver um balão
```

### 4.2 Fluxo Logico / Máquina de Estados
Jogador escolhe a fase 6 no menu -> É apresentado o tutorial -> Joga 3 fases -> Finaliza

---

## 5. 🧪 Plano e Casos de Teste

| ID Caso | Requisito Relacionado | Ação Realizada | Resultado Esperado | Status (PASS/FAIL) |
|---|---|---|---|---|
| **CT-01** | RF-01 | Várias runs de teste com estimativas de tempo  | Jogo não deve ser longo, sem condição fixa de tempo | PASS |
| **CT-02** | RF-02, RF-05| Várias runs de teste e teste com pessoas de fora da área jogando | Jogador deve entender a jogabilidade e objetivos de forma fácil e clara| PASS |
| **CT-03** | RF-03 | Pressionar botão ESC | Menu de pausa é exibido e jogo congela o tempo | PASS |
| **CT-04** | RF-04 | Pressionar botão ESC e clicar em voltar ao menu | Fase fecha e o jogador volta ao menu | PASS |
| **CT-05** | RF-06 | Cometer erros e completar objetivos | Jogo exibe mensagens de acerto ou erro| PASS |

---


## 6. 📝 Histórico de Revisões e Modificações

| Data | Versão | Descrição da Alteração | Autor |
|---|---|---|---|
| 31/08/2026 | 1.0 | Criação inicial do documento de engenharia da fase | [Carlos Eduardo e Felipe Augusto] |
| 01/09/2026 | 1.1 | Finalização | [Carlos Eduardo e Felipe Augusto] |
