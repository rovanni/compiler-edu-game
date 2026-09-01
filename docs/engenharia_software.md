# 🏗️ Guia de Engenharia de Software para os Grupos

Este documento orienta os estudantes sobre **quais artefatos de Engenharia de Software** cada grupo deve elaborar para documentar a fase sob sua responsabilidade no **Compiler Edu Game**.

A aplicação das práticas de Engenharia de Software garante que o desenvolvimento do jogo siga padrões acadêmicos e profissionais de qualidade, rastreabilidade e manutenibilidade.

---

## 📋 1. Visão Geral dos Artefatos Exigidos

Cada grupo (Grupos 1 a 6) deverá gerar e manter atualizado um **Documento de Engenharia da Fase** dentro de sua respectiva pasta em `docs/faseX_nome/README.md`, utilizando o [Template Padrão de Fase](templates/template_documentacao_fase.md).

Os artefatos dividem-se em 5 pilares principais:

```text
 ┌─────────────────────────────────────────────────────────────┐
 │                ARTEFATOS DE ENGENHARIA                      │
 └──────────────────────────────┬──────────────────────────────┘
                                │
   ┌───────────────┬────────────┴──┬───────────────┬───────────┐
   ▼               ▼               ▼               ▼           ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐ ┌──────────────┐
│ 1. Especifica-│ │ 2. Game   │ │ 3. Modelagem│ │ 4. Plano  │ │ 5. Matriz    │
│    ção de   │ │    Design   │ │    e Arqui- │ │    e Casos│ │    RACI e    │
│ Requisitos  │ │ (GDD Fase)  │ │    tetura   │ │ de Testes │ │ Histórico    │
└─────────────┘ └─────────────┘ └─────────────┘ └───────────┘ └──────────────┘
```

---

## 📑 2. Detalhamento dos Artefatos

### 1️⃣ Especificação de Requisitos (SRS adaptado)
Os requisitos definem o que a fase deve fazer. Devem ser numerados para permitir rastreabilidade.

- **Requisitos Funcionais (RF):** Comportamentos do sistema.
  - *Exemplo (RF-01):* O jogo deve permitir que o personagem salte entre plataformas para coletar tokens.
  - *Exemplo (RF-02):* O sistema deve decrementar 1 vida caso o jogador colete um token incorreto.
- **Requisitos Não-Funcionais (RNF):** Qualidade, desempenho e restrições.
  - *Exemplo (RNF-01):* A taxa de quadros deve manter-se a 60 FPS na resolução 1920x1080.
  - *Exemplo (RNF-02):* O código deve ser implementado em GDScript seguindo o padrão `snake_case`.
- **Requisitos Pedagógicos (RP):** Regras de ensino e feedback.
  - *Exemplo (RP-01):* Ao errar um token, uma janela deve ser exibida explicando por que o token escolhido não pertence àquela categoria.

---

### 2️⃣ Game Design Document da Fase (GDD Simplificado)
Descreve a experiência do jogador e as regras da fase.

- **Mecânica Principal:** (ex: Plataforma 2D, Drag & Drop, Alvo/Tiro, Quebra-cabeça).
- **Condições de Vitória e Derrota:** Quantos acertos avançam a fase? Quando o jogo termina?
- **Elementos Visuais e Sonoros:** Sprites dos tokens, background utilizado, áudio de acerto/erro.

---

### 3️⃣ Modelagem e Arquitetura de Software
Representações visuais que explicam a estrutura interna antes e durante a codificação.

- **Árvore de Cenas (Godot Hierarchy):** Hierarquia de nós (`Node2D`, `CharacterBody2D`, `Area2D`, `CanvasLayer`).
- **Diagrama de Estados (FSM - Finite State Machine):** Estados do jogador (Parado, Correndo, Pulando, Coletando) ou dos elementos pedagógicos.
- **Fluxograma da Fase:** Passo a passo lógico desde a entrada do jogador até a conclusão.
- *(Opcional)* **Diagrama de Casos de Uso:** Interações do jogador com a fase.

---

### 4️⃣ Plano e Casos de Teste (QA)
Tabela detalhada contendo as entradas, ações e resultados esperados.

| ID Teste | Descrição | Pré-condição | Ação do Testador | Resultado Esperado | Status |
|---|---|---|---|---|---|
| CT-01 | Coleta de Token Válido | Fase iniciada | Mover personagem até o token `int` | Pontuação aumenta +10 e token desaparece | PASS |
| CT-02 | Coleta de Token Inválido | Fase iniciada | Mover personagem até o símbolo `@` | Perde 1 vida e exibe modal pedagógico | PASS |

---

### 5️⃣ Matriz RACI e Registro de Contribuições

A **Matriz RACI** é uma ferramenta de gestão usada na Engenharia de Software para atribuir responsabilidades claras a cada membro da equipe durante o ciclo de vida do projeto. Ela garante transparência, evita retrabalho e permite ao professor/orientador avaliar a participação individual de cada estudante.

#### O Significado do Acrônimo RACI:

| Letra | Papel em Inglês | Função no Projeto | Explicação Detalhada | Exemplo no Compiler Edu Game |
|:---:|---|---|---|---|
| **R** | **Responsible** | **Responsável (Mão na Massa)** | Quem efetivamente **executa a tarefa** ou escreve o código/artefato. | O aluno que programa a movimentação do personagem ou constrói a cena da fase no Godot. |
| **A** | **Accountable** | **Aprovador / Autoridade** | Quem **responde pelo resultado final** e tem autoridade para aprovar a entrega. **Regra de Ouro:** Deve existir apenas **1 Aprovador** por tarefa para evitar conflito de decisões. | O Líder do Grupo ou o responsável pelo Code Review que valida o Pull Request na branch `develop`. |
| **C** | **Consulted** | **Consultado** | Especialista ou colega que deve ser **consultado antes ou durante** a tarefa para dar orientações técnicas, pedagógicas ou de design. | O aluno responsável pelo conteúdo pedagógico, consultado pelo programador para confirmar se os tokens estão corretos. |
| **I** | **Informed** | **Informado** | Pessoas que **precisam ser avisadas** quando a tarefa for concluída ou alterada, mas não precisam opinar diretamente. | Os membros de outros grupos que precisam ser notificados quando a interface comum for atualizada. |

#### Regras Práticas para Montar a Matriz RACI no Grupo:
1. **Pelo menos 1 Responsável (R):** Toda atividade precisa ter ao menos um executor.
2. **Exatamente 1 Aprovador (A):** Nenhuma tarefa pode ter dois aprovadores finais. Alguém precisa ser a palavra final.
3. **Não exagere nos Consultados (C):** Consultar pessoas demais pode atrasar o desenvolvimento.
4. **Uma pessoa pode acumular papéis:** Em grupos menores, um aluno pode ser **R/A** (Responsável e Aprovador) de uma tarefa específica.

#### Exemplo de Aplicação Prática:

| Atividade do Projeto | Aluno A (Programador) | Aluno B (Líder) | Aluno C (Pedagógico) | Aluno D (Designer) |
|---|:---:|:---:|:---:|:---:|
| Criar Layout da Cena no Godot | C | A | I | **R** |
| Programar Coleta e Validação de Tokens | **R** | A | C | I |
| Escrever Explicações Didáticas de Erros | I | A | **R** | C |
| Executar Testes Funcionais e de Usabilidade | C | A | C | **R** |

---

## 📂 3. Organização dos Arquivos nos Repositórios
 
 Cada grupo deve salvar a documentação no seguinte caminho:
 
 ```text
 docs/
 ├── fase1_tokens/
 │   ├── README.md            # Documentação de Eng. de Software do Grupo 1
 │   ├── evidencias_aex.md    # Evidências e oficinas da Fase 1
 │   └── img/                 # Prints e diagramas da Fase 1
 ├── fase2_scanner/
 │   ├── README.md            # Documentação de Eng. de Software do Grupo 2
 │   ├── evidencias_aex.md    # Evidências e oficinas da Fase 2
 │   └── img/                 # Prints e diagramas da Fase 2
 ├── fase3_parser/
 │   ├── README.md            # Documentação de Eng. de Software do Grupo 3
 │   ├── evidencias_aex.md    # Evidências e oficinas da Fase 3
 │   └── img/                 # Prints e diagramas da Fase 3
 ├── fase4_ast/
 │   ├── README.md            # Documentação de Eng. de Software do Grupo 4
 │   ├── evidencias_aex.md    # Evidências e oficinas da Fase 4
 │   └── img/                 # Prints e diagramas da Fase 4
 ├── fase5_erroLexico/
 │   ├── README.md            # Documentação de Eng. de Software do Grupo 5
 │   ├── evidencias_aex.md    # Evidências e oficinas da Fase 5
 │   └── img/                 # Prints e diagramas da Fase 5
 ├── fase6_sintatico/
 │   ├── README.md            # Documentação de Eng. de Software do Grupo 6
 │   ├── evidencias_aex.md    # Evidências e oficinas da Fase 6
 │   └── img/                 # Prints e diagramas da Fase 6
 └── templates/
     └── template_documentacao_fase.md  # Template base para copiar
 ```
