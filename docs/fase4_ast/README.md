# Documento de Engenharia de Software — Fase 4: Floresta da AST

> **Grupo:** 6
> **Tema:** Árvore Sintática Abstrata (AST), precedência e hierarquia
> **Disciplina:** Compiladores — Ciência da Computação, UENP
> **Professor orientador:** Prof. Luciano Rovanni
> **Cena principal:** `res://scenes/fase4_ast/Main.tscn`
> **Última revisão:** 02/09/2026

## Identificação da equipe

O **Grupo 6**, responsável pela Fase 4, é composto por sete integrantes:

| Função | Responsável(is) |
|---|---|
| Líder | Marcelo Sousa |
| Interface | Nicolas Ribeiro e Gustavo do Valle |
| Programação | Arthur Francisco |
| Conteúdo | Pedro Selleti |
| Testes / QA | Gabriel Ramos |
| Documentação / AEX | Rafael Cunha |

**Integrantes:** Arthur Francisco, Rafael Cunha, Gabriel Ramos, Marcelo Sousa, Gustavo do Valle, Nicolas Ribeiro e Pedro Selleti.

---

## 1. Descrição geral e objetivos pedagógicos

### 1.1 Visão geral

A Floresta da AST é uma fase de plataforma 2D em que o jogador transforma uma expressão linear em uma Árvore Sintática Abstrata. Uma das quatro expressões é escolhida a cada rodada. O personagem recebe um token por vez, percorre plataformas alinhadas aos níveis da árvore, aproxima-se do nó correto e pressiona **E** para alocá-lo.

Um acerto preenche o nó, atualiza o progresso e entrega o próximo token. Um erro preserva o token, aplica a penalidade global e apresenta feedback sobre precedência e posição dos filhos. Quando os cinco nós são preenchidos, o portal final é ativado. A conclusão oferece acesso direto à introdução da Fase 5.

### 1.2 Conceitos abordados

| Conceito | Representação no jogo |
|---|---|
| Árvore Sintática Abstrata | Estrutura visual formada por nós e ligações hierárquicas. |
| Raiz | Operação avaliada por último na expressão completa. |
| Nó interno | Operador que agrupa uma subexpressão. |
| Folha | Identificador ou literal que não possui filhos. |
| Precedência | Operadores prioritários aparecem em subárvores mais profundas. |
| Hierarquia esquerda/direita | A posição dos filhos preserva a estrutura da expressão. |
| Parênteses | Alteram o agrupamento e, consequentemente, a raiz da AST. |

### 1.3 Objetivos de aprendizagem

Ao concluir a fase, espera-se que o estudante consiga:

1. identificar raiz, nós internos e folhas;
2. relacionar precedência de operadores com profundidade na árvore;
3. decompor expressões em subárvores esquerda e direita;
4. explicar como parênteses alteram o agrupamento;
5. diferenciar a escrita linear da representação hierárquica de uma expressão.

### 1.4 Metáfora visual

A árvore central representa a estrutura sintática; os caminhos iluminados representam relações entre pais e filhos; as plataformas transformam os níveis da AST em percurso físico; o token carregado é o elemento a ser inserido; e o portal desperta apenas quando a estrutura está completa.

---

## 2. Especificação de requisitos

### 2.1 Requisitos funcionais (RF)

| ID | Descrição | Prioridade |
|---|---|---|
| **RF-01** | Selecionar uma das quatro expressões cadastradas ao iniciar ou rejogar. | Alta |
| **RF-02** | Exibir a expressão e uma explicação da precedência antes da rodada. | Alta |
| **RF-03** | Criar os nós de raiz, filhos e folhas usados pela AST sorteada. | Alta |
| **RF-04** | Entregar um token por vez e mostrá-lo nas mãos e no HUD. | Alta |
| **RF-05** | Permitir movimento, salto e descida por plataformas semissólidas. | Alta |
| **RF-06** | Permitir alocação com **E** quando o jogador estiver próximo de um nó vazio. | Alta |
| **RF-07** | Aceitar o token apenas no nó correto e não consumi-lo em caso de erro. | Alta |
| **RF-08** | Atualizar nó, progresso, pontuação e token atual após um acerto. | Alta |
| **RF-09** | Penalizar nó incorreto, queda e tempo esgotado conforme as regras globais. | Alta |
| **RF-10** | Oferecer dica que ilumina o nó correto ao custo de pontos. | Média |
| **RF-11** | Mostrar vidas, pontos, tempo, expressão, token, instrução e progresso. | Alta |
| **RF-12** | Permitir pausar, retomar, tentar novamente, rejogar e voltar ao menu. | Média |
| **RF-13** | Ativar o portal final somente quando todos os nós estiverem preenchidos. | Alta |
| **RF-14** | Concluir a fase quando o personagem atravessar o portal ativo. | Alta |
| **RF-15** | Oferecer transição direta para a introdução da Fase 5. | Alta |
| **RF-16** | Animar a entrada do personagem pelo portal antes de liberar os controles. | Média |
| **RF-17** | Tocar ambiente noturno e efeitos de passo, salto, acerto, erro, dano e portal. | Média |

### 2.2 Requisitos não funcionais (RNF)

| ID | Descrição | Categoria |
|---|---|---|
| **RNF-01** | Utilizar Godot 4 e GDScript. | Tecnologia |
| **RNF-02** | Operar em resolução lógica de 1280 × 720. | Compatibilidade visual |
| **RNF-03** | Preservar a estética pixel art e a legibilidade do HUD. | Visual / Usabilidade |
| **RNF-04** | Centralizar vidas, pontos, combo e progresso no `GameManager`. | Arquitetura |
| **RNF-05** | Acionar efeitos compartilhados pelo `SoundManager`. | Arquitetura / Áudio |
| **RNF-06** | Manter a lógica da AST separada da interface e testável em modo headless. | Testabilidade |
| **RNF-07** | Alinhar a colisão das plataformas à superfície visual. | Usabilidade |
| **RNF-08** | Renderizar personagem e token à frente dos portais. | Legibilidade visual |
| **RNF-09** | Restringir o ambiente em loop à cena da Fase 4 e mantê-lo abaixo dos efeitos. | Áudio |
| **RNF-10** | Concentrar a implementação nos diretórios específicos da Fase 4. | Manutenção |

### 2.3 Requisitos pedagógicos (RP)

| ID | Descrição | Mapeamento no jogo |
|---|---|---|
| **RP-01** | Apresentar expressão e regra de precedência antes do início. | Modal introdutório. |
| **RP-02** | Identificar raiz, filhos e folhas explicitamente. | Cabeçalhos e caminhos dos nós. |
| **RP-03** | Exigir aplicação prática da hierarquia. | Percurso e alocação em cada nó. |
| **RP-04** | Explicar o erro sem entregar toda a solução. | Feedback didático; token permanece na mão. |
| **RP-05** | Oferecer ajuda opcional com custo. | Dica ilumina o nó correto e custa 5 pontos. |
| **RP-06** | Trabalhar multiplicação antes da soma. | `a + b * c` e `a * b + c`. |
| **RP-07** | Trabalhar atribuição como operação de menor precedência. | `x = y + 1`. |
| **RP-08** | Trabalhar mudança de agrupamento por parênteses. | `( a + b ) * c`. |
| **RP-09** | Reforçar o conceito ao concluir. | Modal explica que a raiz é a última operação avaliada. |

---

## 3. Game Design Document (GDD)

### 3.1 Identidade

- **Nome:** Floresta da Árvore Sintática
- **Posição:** Fase 4 da campanha
- **Gênero:** plataforma 2D com puzzle educacional
- **Tema:** floresta noturna, árvore ancestral, plataformas gramadas e portais arcanos
- **Tempo por tentativa:** 180 segundos
- **Vidas:** 3, compartilhadas pelo `GameManager`

### 3.2 Mecânica principal

A sequência contém os cinco tokens da expressão em ordem embaralhada. Para cada token, o jogador interpreta a expressão, alcança o nível adequado da árvore e escolhe o nó previsto pela associação `slot → token` do desafio.

### 3.3 Controles

| Ação | Teclas |
|---|---|
| Mover | `A` / `D` ou `←` / `→` |
| Pular | `W`, `↑` ou `Espaço` |
| Descer da plataforma | `S` ou `↓` |
| Alocar token | `E` |
| Pausar | `ESC` ou botão do HUD |

### 3.4 Desafios implementados

| Expressão | Raiz | Estrutura | Conceito |
|---|---|---|---|
| `a + b * c` | `+` | `a` à esquerda; `*` à direita com `b` e `c` | Multiplicação antes da soma. |
| `x = y + 1` | `=` | `x` à esquerda; `+` à direita com `y` e `1` | Atribuição avaliada por último. |
| `a * b + c` | `+` | `*` à esquerda com `a` e `b`; `c` à direita | Subárvore prioritária à esquerda. |
| `( a + b ) * c` | `*` | `+` à esquerda com `a` e `b`; `c` à direita | Parênteses alteram a raiz. |

### 3.5 Pontuação

| Evento | Resultado |
|---|---|
| 1º acerto consecutivo | +10 pontos |
| 2º acerto consecutivo | +12 pontos |
| 3º acerto consecutivo | +14 pontos |
| 4º acerto consecutivo em diante | +18 pontos |
| Nó incorreto ou queda | −5 pontos, combo zerado e −1 vida |
| Tempo esgotado | Rollback da tentativa, −5 pontos e −1 vida |
| Dica | −5 pontos e combo zerado |
| Conclusão | +50 pontos |
| Conclusão sem erros/dicas | +30 pontos adicionais |

A pontuação global nunca fica negativa.

### 3.6 Vitória, derrota e recuperação

- **Vitória:** preencher os cinco nós e atravessar o portal final.
- **Derrota:** perder as três vidas.
- **Queda:** respawn no portal inicial, se ainda houver vida.
- **Tempo esgotado:** reinício da expressão após a penalidade.
- **Rejogar:** seleciona a expressão seguinte.
- **Próxima fase:** abre `res://scenes/fase5_erroLexico/introducao.tscn`.

### 3.7 Feedback

- Operadores são roxos, números amarelos e identificadores azuis.
- O nó próximo exibe a ação de interação.
- Erro usa vermelho; dica usa amarelo; acerto assume a cor do token.
- Mensagens textuais acompanham as cores para não depender só delas.

---

## 4. Arquitetura e modelagem no Godot

### 4.1 Árvore de cenas

```text
Main (Node2D)                         -- main.gd
├── Background (Sprite2D)
├── Platforms (Node2D)               -- plataformas criadas em runtime
├── Nodes (Node2D)                   -- nós AST criados em runtime
├── Jogador (CharacterBody2D)        -- jogador.tscn / jogador.gd
│   ├── AnimatedSprite2D
│   ├── CarryPose / CarryWalk / CarryJump
│   ├── CollisionShape2D
│   └── HeldToken
├── HUD (CanvasLayer)                -- hud.tscn / hud.gd
└── ForestAmbience (AudioStreamPlayer)

Criados por main.gd:
├── EntryPortal / ExitPortal         -- ast_portal.gd
├── 9 plataformas                    -- ast_platform.gd
└── até 5 nós AST                    -- no_ast.tscn / no_ast.gd
```

### 4.2 Scripts e responsabilidades

| Script | Responsabilidade |
|---|---|
| `main.gd` | Estados, desafios, mundo, HUD, tempo, pontuação, portais e transição. |
| `ast_session.gd` | Token atual, associação esperada, nós preenchidos e validação pura. |
| `no_ast.gd` | Proximidade e estados visuais de cada nó. |
| `jogador.gd` | Física, controles, respawn e animações. |
| `ast_platform.gd` | Colisão e desenho das plataformas gramadas. |
| `ast_portal.gd` | Sprite, shader, partículas, colisão e sinal do portal. |
| `hud.gd` | HUD, modais, botões, expressão, token, feedback e progresso. |

### 4.3 Máquina de estados

```text
INTRO ── começar ──► PLAYING ── árvore completa ──► PORTAL_READY
                       │                                  │
                       ├─ pausa ─► PAUSED ─► retomar      │ atravessar portal
                       ├─ tempo ─► RESETTING ─► INTRO     ▼
                       └─ vidas = 0 ───────────────► GAME_OVER

                                      COMPLETE ─► rejogar / menu / Fase 5
```

### 4.4 Fluxo de validação

1. `main.gd` envia o dicionário de nós a `AstSession.configure()`.
2. A sessão embaralha os tokens e expõe `current_token`.
3. O jogador entra na área de um nó e pressiona **E**.
4. `AstSession.try_place(slot_id)` retorna `WRONG`, `ACCEPTED` ou `COMPLETE`.
5. O controlador aplica feedback, pontos e atualização visual.

### 4.5 Dependências compartilhadas

| Dependência | Uso |
|---|---|
| `GameManager` | Vidas, pontos, combo, checkpoint, conclusão e início da Fase 5. |
| `SoundManager` | Passos, salto, confirmação, erro, dano e portal. |
| Assets das Fases 1 e 2 | Sprites base e poses do personagem carregando. |

---

## 5. Plano e casos de teste

### 5.1 Execução automatizada

```powershell
godot --headless --path . --script res://tests/headless_ast_test.gd
godot --headless --path . res://tests/phase4_collision_test.tscn
```

Resultados obtidos em 02/09/2026 com Godot 4.7:

```text
PASS: lógica da AST, precedência e alocação de tokens
PASS: colisões e pousos da Fase 4
```

### 5.2 Casos

| ID | Requisitos | Ação | Resultado esperado | Status |
|---|---|---|---|---|
| **CT-01** | RF-03, RF-07 | Montar `a + b * c` na ordem correta | Cinco posições aceitas e AST concluída | ✅ Automatizado |
| **CT-02** | RF-07, RP-04 | Colocar `=` no filho esquerdo | Rejeição sem consumir token ou progresso | ✅ Automatizado |
| **CT-03** | RF-05, RNF-07 | Soltar o jogador sobre cada superfície | Pouso e pés alinhados ao topo | ✅ Automatizado |
| **CT-04** | RF-05 | Posicionar jogador nos dois vãos | Queda entre as plataformas | ✅ Automatizado |
| **CT-05** | RF-05 | Pressionar `S`/`↓` em plataforma semissólida | Travessia para baixo | ✅ Automatizado |
| **CT-06** | RF-16, RNF-08 | Iniciar a fase | Mesma arte nos portais; jogador termina no spawn | ✅ Automatizado |
| **CT-07** | RF-01, RF-02 | Iniciar várias rodadas | Uma das quatro expressões e sua lição são exibidas | ☐ Manual |
| **CT-08** | RF-04, RF-08 | Alocar token correto | Nó e progresso atualizados; próximo token entregue | ☐ Manual |
| **CT-09** | RF-09, RP-04 | Alocar token incorreto | Penalidade, som, feedback e token preservado | ☐ Manual |
| **CT-10** | RF-10, RP-05 | Pedir dica | Nó correto iluminado e 5 pontos descontados | ☐ Manual |
| **CT-11** | RF-09 | Esgotar o tempo | Penalidade e reinício | ☐ Manual |
| **CT-12** | RF-12 | Pausar e retomar | Tempo e controles retomam o estado anterior | ☐ Manual |
| **CT-13** | RF-13 | Preencher quatro nós | Portal final continua inativo | ☐ Manual |
| **CT-14** | RF-13, RF-14 | Preencher quinto nó e entrar no portal | Conclusão exibida | ☐ Manual |
| **CT-15** | RF-15 | Clicar “PRÓXIMA FASE” | Introdução da Fase 5 é carregada | ✅ Destino validado |
| **CT-16** | RF-17, RNF-09 | Ouvir mais que a duração do WAV | Ambiente repete e efeitos continuam audíveis | ☐ Auditivo |

---

## 6. Matriz RACI

| Atividade | Marcelo Sousa<br>Liderança | Arthur Francisco<br>Programação | Nicolas Ribeiro e Gustavo do Valle<br>Interface | Pedro Selleti<br>Conteúdo | Gabriel Ramos<br>QA | Rafael Cunha<br>Documentação |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Planejamento | **A/R** | C | C | C | I | I |
| Expressões e ASTs | **A** | C | I | **R** | C | I |
| Implementação da AST | **A** | **R** | I | C | C | I |
| Movimento, colisões e portais | **A** | **R** | C | I | C | I |
| HUD e identidade visual | **A** | C | **R** | C | C | I |
| Textos pedagógicos | **A** | C | C | **R** | C | C |
| Plano e execução de testes | C | C | C | C | **A/R** | I |
| Documento de engenharia | **A** | C | C | C | C | **R** |
| Evidências e oficina AEX | **A** | I | C | C | C | **R** |
| Integração no GitHub | **A/R** | C | I | I | C | I |

---

## 7. Entregáveis e rastreabilidade

### 7.1 Artefatos

| Tipo | Caminho | Conteúdo |
|---|---|---|
| Cenas | `scenes/fase4_ast/` | 4 cenas específicas |
| Scripts | `scripts/fase4_ast/` | 7 scripts GDScript |
| Arte | `assets/fase4_ast/` | Fundo e portal da AST |
| Áudio | `assets/audio/phase4_forest_at_night.wav` | Ambiente exclusivo da fase |
| Testes | `tests/headless_ast_test.gd`, `phase4_collision_test.gd`, `visual_phase4_capture.gd` | Lógica, colisões e evidências |
| Documentação | `docs/fase4_ast/` | Documento, relatório AEX e imagens |

### 7.2 Rastreabilidade

| Requisitos | Implementação | Testes |
|---|---|---|
| RF-01 a RF-04 | `CHALLENGES`, `_start_challenge`, `_update_held_token` | CT-01, CT-07 |
| RF-05 | `jogador.gd`, `ast_platform.gd` | CT-03 a CT-05 |
| RF-06 a RF-08 | `no_ast.gd`, `ast_session.gd`, `_try_place_current_token` | CT-01, CT-02, CT-08 |
| RF-09 a RF-10 | Tratadores de erro, tempo, queda e dica em `main.gd` | CT-09 a CT-11 |
| RF-11 a RF-12 | `hud.gd`, pausa e retomada em `main.gd` | CT-07, CT-12 |
| RF-13 a RF-15 | `ast_portal.gd`, `_on_portal_entered`, `_go_to_next_phase` | CT-13 a CT-15 |
| RF-16 a RF-17 | Animação do jogador, `ForestAmbience`, `SoundManager` | CT-06, CT-16 |
| RP-01 a RP-09 | `CHALLENGES`, HUD, nós e sessão AST | CT-01, CT-02, CT-07 a CT-14 |

---

## 8. Histórico de revisões

| Data | Versão | Alteração | Autor identificado no Git |
|---|---|---|---|
| 11/08/2026 | 0.1 | Implementação inicial da Floresta da AST | Ozeias Junior |
| 13/08/2026 | 1.0 | Reformulação como desafio de construção de AST | Pedro Selleti (`pselleti`) |
| 27/08/2026 | 1.1 | Áudio, portais, animações, card e jogabilidade | Pedro Selleti (`pselleti`) |
| 01/09/2026 | 1.2 | Integrações e estrutura inicial de documentação | Histórico do repositório |
| 02/09/2026 | 1.3 | Ligação Fase 4 → Fase 5 e documentação completa | Trabalho local pendente de commit |

---

## 9. Referências

- [README principal](../../README.md)
- [Engenharia de Software](../engenharia_software.md)
- [Arquitetura](../arquitetura.md)
- [Diretrizes pedagógicas](../pedagogico.md)
- [Guia de testes](../guia_testes.md)
- [Guia de evidências AEX](../aex_evidencias.md)
- [Evidências da Fase 4](evidencias_aex.md)
