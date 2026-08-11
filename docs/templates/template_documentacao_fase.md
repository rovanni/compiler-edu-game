# 📑 Documento de Engenharia de Software – Fase [X]: [Nome da Fase]

> **Grupo:** [Número do Grupo]  
> **Fase:** [Nome da Fase, ex: Reino dos Tokens]  
> **Integrantes e Funções:**  
> - [Nome do Aluno 1] – Líder / Programador  
> - [Nome do Aluno 2] – Designer UI/UX  
> - [Nome do Aluno 3] – Conteúdo Pedagógico  
> - [Nome do Aluno 4] – Testes / QA & Documentação  

---

## 1. 🎯 Descrição Geral e Objetivos Pedagógicos

### 1.1 Visão Geral da Fase
[Breve resumo sobre como a fase funciona e a história/cenário no jogo.]

### 1.2 Conceito de Compiladores Abordado
[Explique qual conceito teórico da disciplina de Compiladores esta fase ensina ao aluno (ex: Análise Léxica, Tokens, Scanner, Parser, AST).]

---

## 2. 📋 Especificação de Requisitos

### 2.1 Requisitos Funcionais (RF)
| ID | Descrição | Prioridade |
|---|---|---|
| **RF-01** | O jogo deve permitir que o jogador... | Alta |
| **RF-02** | O sistema deve calcular a pontuação com base em... | Alta |
| **RF-03** | O jogo deve permitir pausar a partida a qualquer momento. | Média |

### 2.2 Requisitos Não-Funcionais (RNF)
| ID | Descrição | Categoria |
|---|---|---|
| **RNF-01** | A fase deve ser desenvolvida utilizando Godot 4 em GDScript. | Desempenho / Padrão |
| **RNF-02** | A interface da fase deve manter a mesma identidade visual do HUD principal. | Usabilidade |

### 2.3 Requisitos Pedagógicos (RP)
| ID | Descrição | Mapeamento no Jogo |
|---|---|---|
| **RP-01** | O jogo deve explicar o motivo do erro sempre que o jogador selecionar um token incorreto. | Pop-up de Feedback Didático |
| **RP-02** | Oferecer um sistema de dicas com custo de pontuação. | Botão "Pedir Dica" |

---

## 3. 🕹️ Game Design Document (GDD da Fase)

- **Mecânica Principal:** [ex: Plataforma 2D / Coleta seletiva / Drag and Drop]
- **Regras de Pontuação:**
  - Acerto: +10 pontos
  - Erro: -5 pontos e perda de 1 vida
  - Dica: -5 pontos
- **Condição de Vitória:** [ex: Coletar 5 tokens válidos e atingir o portal de saída]
- **Condição de Derrota:** [ex: Perder todas as 3 vidas ou o tempo esgotar]

---

## 4. 🏛️ Arquitetura e Modelagem no Godot

### 4.1 Árvore de Cenas (Godot Node Hierarchy)
```text
FaseX_Nome (Node2D)
├── Map (TileMap)
├── Player (CharacterBody2D)
│   ├── CollisionShape2D
│   └── Sprite2D
├── TokenContainer (Node2D)
│   ├── Token1 (Area2D)
│   └── Token2 (Area2D)
├── HUD (CanvasLayer) -> Instância do res://scenes/common/hud.tscn
└── FeedbackModal (CanvasLayer)
```

### 4.2 Fluxo Logico / Máquina de Estados
[Descreva ou insira um diagrama do fluxo de estados da fase: Inicio -> Jogando -> Validação -> Vitória/Derrota.]

---

## 5. 🧪 Plano e Casos de Teste

| ID Caso | Requisito Relacionado | Ação Realizada | Resultado Esperado | Status (PASS/FAIL) |
|---|---|---|---|---|
| **CT-01** | RF-01, RP-01 | Colidir com token correto | Pontuação aumenta +10 e som de acerto toca | [ ] Pendente |
| **CT-02** | RF-02, RP-01 | Colidir com token incorreto | Vida reduz -1 e modal de erro didático é exibido | [ ] Pendente |
| **CT-03** | RF-03 | Pressionar botão ESC | Menu de pause é exibido e jogo congela o tempo | [ ] Pendente |

---

## 6. 👥 Matriz RACI de Responsabilidades

| Atividade / Entregável | Aluno 1 (Líder) | Aluno 2 (UI) | Aluno 3 (Pedagógico) | Aluno 4 (QA) |
|---|:---:|:---:|:---:|:---:|
| Modelagem da Cena no Godot | C | **R** / **A** | I | I |
| Programação da Mecânica | **R** / **A** | C | I | C |
| Elaboração dos Textos Didáticos | I | I | **R** / **A** | C |
| Execução dos Casos de Teste | I | C | C | **R** / **A** |

> *Legenda:* **R** = Responsável por executar | **A** = Aprovador final | **C** = Consultado | **I** = Informado

---

## 7. 📝 Histórico de Revisões e Modificações

| Data | Versão | Descrição da Alteração | Autor |
|---|---|---|---|
| DD/MM/2026 | 1.0 | Criação inicial do documento de engenharia da fase | [Nome do Aluno] |
