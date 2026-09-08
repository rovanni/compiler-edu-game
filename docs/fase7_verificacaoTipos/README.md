# 📑 Documento de Engenharia de Software – Fase 7: Torre da Verificação de Tipos

—
#Integrantes do grupo
| Função | Responsável | Índice|
|---|---|---|
| Programação, arquitetura e testes | Anibal Neto |
| Designer UI/UX | [Nome do Aluno] |
| Conteúdo Pedagógico | [Nome do Aluno] |
| Testes / QA & Documentação | [Nome do Aluno] |

## 1. 🎯 Descrição Geral e Objetivos Pedagógicos

### 1.1 Visão Geral da Fase

A Torre da Verificação de Tipos é o **Mundo 7** do Compiler Edu Game, cobrindo a etapa de **Análise Semântica / Verificação de Tipos** do pipeline de um compilador — a parte que confere se as operações do programa fazem sentido em termos de tipos, antes de o código virar algo executável.

A fase é dividida em 4 níveis com duas mecânicas:

- **Nível 1 — "TypeTris":** peças com valores literais (`25`, `"Ana"`, `true`, `7.5`, `'A'`) caem em uma tela no estilo Tetris e o jogador direciona cada uma para a coluna do tipo correto (`INT`, `FLOAT`, `String`, `BOOLEAN`, `CHAR`) antes que ela chegue ao fundo.
- **Níveis 2, 3 e 4 — "Torre de Defesa dos Tipos":** inspirada em jogos como Bloons TD. Inimigos (um valor, uma atribuição ou uma expressão, dependendo do nível) andam por um caminho até o portão do compilador. O jogador constrói e arrasta **torres de tipo** (`int`, `float`, `String`, `boolean`, `char`, "Erro de Tipo") nos slots ao longo do caminho — cada torre só destrói o inimigo cujo "veredito de tipo" bate com o dela. Um inimigo que chega ao fim sem ser destruído consome uma fatia da barra do compilador (a "vida" da Torre); vitória é sobreviver a todas as ondas.

Em ambas as mecânicas, quem decide "qual é o tipo certo" nunca é uma regra escrita à mão por nível — é sempre a mesma engine central de verificação de tipos (`type_checker.gd`).

### 1.2 Conceito de Compiladores Abordado

**Análise Semântica — Verificação de Tipos.** A fase ensina: identificação do tipo de um valor literal; compatibilidade de atribuição entre tipo declarado e tipo do valor; conversão implícita (*widening* `int → float`, e por que o inverso não vale); a diferença entre `char` (aspas simples) e `String` (aspas duplas) — a "armadilha" pedagógica central da fase; e o tipo resultante de uma expressão com operador.

---

## 2. 📋 Especificação de Requisitos

### 2.1 Requisitos Funcionais (RF)

| ID | Descrição | Prioridade |
|---|---|---|
| **RF-01** | O jogo deve permitir identificar o tipo de um valor literal direcionando uma peça em queda para a coluna correta (Nível 1). | Alta |
| **RF-02** | O sistema deve permitir construir uma torre de defesa de um tipo escolhido em um slot vazio, por clique ou por arrastar-e-soltar. | Alta |
| **RF-03** | O sistema deve permitir **trocar** uma torre já construída por outra de tipo diferente, cobrando o custo cheio do novo tipo (sem reembolso). | Média |
| **RF-04** | Uma torre só destrói um inimigo cujo tipo "correto" bata com o tipo dela; inimigos incompatíveis passam ilesos. | Alta |
| **RF-05** | O sistema deve calcular pontuação com base em acertos e erros, com recompensa/custo específicos por nível e tipo. | Alta |
| **RF-06** | Os inimigos dos Níveis 2-4 devem ser organizados em **ondas** sucessivas. | Alta |
| **RF-07** | A barra do compilador deve reduzir a cada fuga/erro e declarar derrota ao chegar a 0%. | Alta |
| **RF-08** | O jogo deve declarar vitória quando todas as ondas de um nível forem resolvidas sem a barra zerar. | Alta |
| **RF-09** | Ao eliminar um inimigo, deve tocar uma animação de explosão e a animação de "ataque" da torre, sem afetar dano/pontuação/remoção. | Média |
| **RF-10** | *(Integração)* Ao concluir um nível (2 ou 3), o jogador deve poder avançar para o próximo; ao concluir o Nível 4, a Fase 7 deve ser marcada como concluída no menu principal. | Alta |
| **RF-11** | *(Integração)* O jogador deve poder pausar a fase a qualquer momento e, a partir daí, continuar, reiniciar o nível atual ou sair para o menu principal. | Média |

### 2.2 Requisitos Não-Funcionais (RNF)

| ID | Descrição | Categoria |
|---|---|---|
| **RNF-01** | Godot 4.7 em GDScript puro (sem Mono/.NET). | Desempenho / Padrão |
| **RNF-02** | Interface mantendo a fonte (`Friend Bestie`) e a paleta do restante do jogo. | Usabilidade |
| **RNF-03** | Toda a lógica de regras (verificação de tipos, torre de defesa) é `RefCounted` puro, sem depender de nós de cena — testável via `godot --headless --script`. | Testabilidade |
| **RNF-04** | Nenhuma animação depende de `Timer`/`Tween` — todo controle de tempo usa `delta` acumulado com margem de segurança contra engasgos de frame. | Confiabilidade |
| **RNF-05** | Resolução de referência 1280×720, fundos escalados por proporção para não distorcer o pixel art. | Usabilidade |
| **RNF-06** | Toda "defesa correta" em dados de nível é calculada pela engine de tipos real, nunca hardcoded. | Manutenibilidade |

### 2.3 Requisitos Pedagógicos (RP)

| ID | Descrição | Mapeamento no Jogo |
|---|---|---|
| **RP-01** | Destacar visualmente `char` (aspas simples) vs. `String` (aspas duplas). | Peças/inimigos usando `'A'` vs. `"A"` |
| **RP-02** | Linguagem simples e não-técnica nos erros de tipo. | Mensagens do `type_checker.gd` |
| **RP-03** | Dificuldade progressiva: reconhecimento → compatibilidade/conversão → expressões. | Nível 2 → 3 → 4 |
| **RP-04** | Permitir revisitar a explicação da mecânica a qualquer momento. | Painel de explicação minimizável |
| **RP-05** | Progresso/derrota comunicados por um único indicador (barra do compilador), sem punição severa. | Barra "COMPILADOR" + reinício do nível |

---

## 3. 🕹️ Game Design Document (GDD da Fase)

- **Mecânica Principal:** Nível 1 — encaixe de peças em queda por coluna de tipo. Níveis 2-4 — Tower Defense: construir torres de tipo para destruir inimigos que avançam por um caminho.
- **Regras de Pontuação (valores reais de `defense_level_data_factory.gd`):**
  - Nível 2: 300 pontos iniciais; torres custam 80; recompensa por inimigo: 60; dano ao escapar: 12%.
  - Nível 3: 350 iniciais; torres custam 90, "Erro de Tipo" custa 130; recompensa: 80; dano: 15%.
  - Nível 4: 400 iniciais; torres custam 100, "Erro de Tipo" custa 150; recompensa: 100; dano: 18%.
  - Trocar uma torre cobra o custo cheio do tipo novo, sem reembolso.
  - *(Integração)* Ao concluir um nível 2 ou 3, `GameManager.award_sub_phase_bonus()` soma um bônus à pontuação geral da sessão (mesmo padrão da Fase 6); ao concluir o Nível 4, `GameManager.complete_phase(7, ...)` marca a fase como concluída.
- **Condição de Vitória:** todas as ondas resolvidas sem a barra chegar a 0%.
- **Condição de Derrota:** barra do compilador chega a 0% — "A compilação falhou / GAME OVER", com opção de tentar o nível de novo.

---

## 4. 🏛️ Arquitetura e Modelagem no Godot

### 4.1 Árvore de Cenas (Godot Node Hierarchy) — Torre de Defesa (Níveis 2-4)

```text
Level2 / Level3 / Level4 (Control)   — script: tower_defense_level_controller.gd
├── Fundo (TextureRect)              — mundo7_torre_fundo.png
├── CaminhoVisual (TextureRect)      — caminho_trilha.png
├── SlotsContainer (Node2D)          — marcador "+" / torre construída (AnimatedSprite2D)
├── InimigosContainer (Node2D)       — um AnimatedSprite2D + Label por inimigo ativo
├── ExplosoesContainer (Node2D)      — uma explosão por eliminação, remove-se sozinha
├── Portao (TextureRect)             — portao_compilador.png
├── Paleta (HBoxContainer)           — ícone + custo + nome por tipo de defesa
├── PainelExplicacao (Control)       — expande/minimiza sozinho
├── HUD (CanvasLayer)                — pontos, barra do compilador, onda
├── ExplosaoDerrota / TextoDerrota   — reaproveitados do Nível 1
└── [runtime] Botão "☰" (pausa) / painel de pausa (CONTINUAR, REINICIAR,
    SAIR PARA O MENU) / PRÓXIMO NÍVEL / TENTAR NOVAMENTE — criados em
    código na integração com o menu principal (ver seção 7)
```

A cena é **única e compartilhada pelos 3 níveis** — o que muda é só o `DefenseLevelData` (`DefenseLevelDataFactory.nivel_2/3/4()`), nunca lógica de jogo duplicada.

### 4.2 Fluxo Lógico / Máquina de Estados

```
Menu principal → clique no card "7 · TORRE DA VERIFICAÇÃO"
      │
      ▼
GameManager.begin_phase(7) → Level1.tscn (Reconhecimento de Tipos)
      │
      ├── "PRÓXIMO NÍVEL →" (sempre disponível, Nível 1 não tem derrota bloqueante)
      ▼
Level2.tscn → onda a onda → vitória → GameManager.award_sub_phase_bonus() → Level3.tscn
      │                                                                        │
      └── derrota → "TENTAR NOVAMENTE" (recarrega o próprio nível)             ▼
                                                            Level3.tscn → vitória → Level4.tscn
                                                                                       │
                                                                                       ▼
                                                          Level4.tscn → vitória → GameManager
                                                          .complete_phase(7, ...) → menu (card
                                                          marcado "✓ CONCLUÍDA")
```

Botão "☰" (pausa) sempre disponível em qualquer nível, a qualquer momento — abre um painel com "▶ CONTINUAR", "REINICIAR" (recarrega o nível atual) e "SAIR PARA O MENU" (chama `GameManager.abandon_phase()`, exceto se a fase já tiver sido concluída, e volta pro menu).

---

## 5. 🧪 Plano e Casos de Teste

Suíte automatizada (`godot --headless --script`, sem editor nem tela) — **392 testes passando** em 10 arquivos, verificados após a integração ao `compiler-edu-game` (rodados dentro deste projeto, não só no projeto isolado original).

| ID Caso | Requisito Relacionado | Ação Realizada | Resultado Esperado | Status (PASS/FAIL) |
|---|---|---|---|---|
| **CT-01** | RF-01, RP-01 | Direcionar `"A"` (aspas duplas) para a coluna CHAR | Recusado — `"A"` é `String`, mesmo com 1 caractere | PASS |
| **CT-02** | RF-02 | Arrastar uma torre `int` da paleta até um slot vazio | Torre construída, pontos descontados pelo custo | PASS |
| **CT-03** | RF-03 | Clicar em slot ocupado por `int` com `String` selecionada | Torre trocada, custo cheio de `String` debitado | PASS |
| **CT-04** | RF-04 | Inimigo `float` passa pelo alcance de uma torre `int` | Inimigo não é afetado | PASS |
| **CT-05** | RF-06, RF-07 | Inimigo chega ao fim do caminho sem ser destruído | Barra do compilador reduz pelo dano daquele inimigo | PASS |
| **CT-06** | RF-08 | Todas as ondas do Nível 4 resolvidas sem a barra zerar | Tela de vitória exibida | PASS |
| **CT-07** | RF-09 | Três inimigos eliminados em sequência | As três explosões renderizam corretamente, cada uma independente | PASS |
| **CT-08** | RF-10, RF-11 *(integração, verificado manualmente com screenshot renderizado)* | Vencer o Nível 4 | `GameManager.complete_phase(7, ...)` chamado; card da Fase 7 no menu passa a "✓ CONCLUÍDA" | PASS |
| **CT-09** | RF-11 *(verificado manualmente com screenshot renderizado)* | Clicar em "☰" em qualquer nível | Painel de pausa aparece por cima do HUD, com CONTINUAR/REINICIAR/SAIR PARA O MENU; simulação para de avançar enquanto aberto | PASS |

Ver `docs/fase7_verificacaoTipos/evidencias_aex.md` para as capturas de tela reais.

---

## 6. 👥 Matriz RACI de Responsabilidades

| Atividade / Entregável | Anibal (Programador) | [Aluno 2] | [Aluno 3] | [Aluno 4] |
|---|:---:|:---:|:---:|:---:|
| Modelagem da Cena no Godot | **R** / **A** | C | I | I |
| Programação da Mecânica GDScript | **R** / **A** | I | I | C |
| Elaboração dos Textos Didáticos | C | I | **R** / **A** | I |
| Integração de Assets Visuais | **R** / **A** | C | I | I |
| Integração com o `compiler-edu-game` (menu, GameManager) | **R** / **A** | I | I | I |
| Execução do Plano de Testes | **R** / **A** | I | I | C |
| Coleta de Evidências AEX | **R** | I | C | **A** |

*(Preencha as colunas dos demais integrantes conforme a divisão real de trabalho.)*

---

## 7. 🔀 Notas da Integração com o Jogo Principal

Esta fase foi desenvolvida e testada num projeto Godot isolado (392 testes) antes de ser integrada a este repositório. A integração trouxe:

- `scripts/fase7_verificacaoTipos/` e `scenes/fase7_verificacaoTipos/` — código e cenas da fase, com todos os `res://` reapontados pra estrutura deste projeto (a fonte `Friend Bestie.otf` passou a apontar pro `fonts/` compartilhado em vez de uma cópia própria).
- `assets/fase7_verificacaoTipos/` — sprites e efeitos da fase.
- Card "7 · TORRE DA VERIFICAÇÃO" no `scenes/menu/menu.tscn`, ligado a `_on_card_fase_7_pressed()` em `scripts/menu/menu.gd`.
- **Navegação entre níveis** (não existia no projeto isolado, onde cada nível era aberto manualmente pelo editor): "PRÓXIMO NÍVEL →" (Níveis 1→2→3→4) e "TENTAR NOVAMENTE" (na derrota), criados em runtime em `level1_controller.gd` e `tower_defense_level_controller.gd`.
- **Pausar/sair/reiniciar** (pedido do Anibal, adicionado após a integração inicial): um botão "☰" compacto, sempre visível no canto superior esquerdo de qualquer nível, abre um painel de pausa — mesma ideia visual do `show_pause()` do HUD compartilhado (`scripts/common/game_hud.gd`, usado por fase1/fase2/fase5/fase6: fundo escurecido + painel central), escrito à mão nos dois controllers da Fase 7 em vez de instanciar o `GameHud` compartilhado, porque a fase já tem seu próprio HUD (barra do compilador/pontos) e depender dos painéis internos do `GameHud` (privados, pensados pro layout dele) seria frágil. O painel oferece "▶ CONTINUAR" (fecha e retoma), "REINICIAR" (`reload_current_scene()`) e "SAIR PARA O MENU" (`GameManager.abandon_phase()` — só quando a fase ainda não foi concluída de verdade, checado via `GameManager.is_phase_completed(7)` — e `change_scene_to_file` pro menu), mesmo padrão comportamental de `fase1_tokens/main.gd:_voltar_menu()`. `_process()` de ambos os controllers agora checa uma flag `_pausado` no início e não avança a simulação enquanto o painel estiver aberto.
- **Correção de layout:** o botão de pausa (antes um botão "☰ MENU" mais largo) cobria o início do texto de pontuação ("PONTOS: 0" / "NÍVEL N · PONTOS: ...") nas 4 cenas — bug pré-existente da integração original, só percebido ao comparar contra os screenshots reais. Corrigido deslocando os labels `HUD/Pontuacao` (Nível 1) e `HUD/Info` (Níveis 2-4) 44px pra direita nas 4 cenas.
- **`GameManager`**: `begin_phase(7)` ao entrar na fase; `award_sub_phase_bonus()` ao concluir os Níveis 1-3; `complete_phase(7, sem_erros)` só ao concluir o Nível 4 (mesmo padrão da Fase 6: sub-etapas dão bônus, só a última marca "✓ concluída" no card do menu). A Fase 7 **não** usa o sistema de vidas do `GameManager` — mantém sua própria barra do compilador como vida, decisão de design já registrada no GDD original da fase (seção 13).
- **Pendência conhecida:** o card da Fase 7 no menu usa `mundo7_torre_fundo.png` (a arte de fundo) como imagem provisória, com um rótulo de texto sobreposto ("7 · TORRE DA VERIFICAÇÃO") pra ficar identificável. O ícone correto — `assets/sprites/world_icons/mundo7_torre_icone.png`, já desenhado com a moldura/número/faixa no mesmo padrão dos outros mundos (ver GDD, seção 15) — não pôde ser copiado nesta integração porque o computador de origem ficou offline durante o processo. Trocar o `ext_resource` da textura `PreviewFase7` em `menu.tscn` por esse ícone (e então remover o `RotuloFallback`) é o único passo visual que falta.

Ver o changelog completo, versão a versão, no GDD original da fase (mantido junto ao histórico de desenvolvimento) para o detalhe de cada correção de bug e decisão de design tomada antes da integração.

---

## 8. 📝 Histórico de Revisões e Modificações

| Data | Versão | Descrição da Alteração | Autor |
|---|---|---|---|
| 02/09/2026 | 1.0 | Integração da fase (392 testes) ao `compiler-edu-game`: migração de código/assets, card no menu, navegação entre níveis, `GameManager` | Anibal Neto |
| 08/09/2026 | 1.1 | Painel de pausa (CONTINUAR/REINICIAR/SAIR PARA O MENU) em todos os níveis, substituindo o botão "☰ MENU" fixo; correção do layout do HUD (rótulo de pontuação sobreposto pelo botão) | Anibal Neto |
