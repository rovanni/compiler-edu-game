# 🛠️ Arquitetura Técnica e Padrões de Projeto

Este documento especifica a estrutura técnica do **Compiler Edu Game**, desenvolvido utilizando a **Godot Engine 4 (GDScript)**.

---

## 🏗️ 1. Organização do Projeto

A estrutura de arquivos do Godot deve respeitar estritamente a seguinte hierarquia:

```text
compiler-edu-game/
├── scenes/                  # Cenas do jogo (.tscn)
│   ├── menu/                # Menu Principal, Créditos, Seleção de Fases
│   ├── common/              # Componentes reutilizáveis (HUD, Pause Menu, DialogBox)
│   ├── fase1_tokens/        # Recursos específicos do Grupo 1
│   ├── fase2_scanner/       # Recursos específicos do Grupo 2
│   ├── fase3_parser/        # Recursos específicos do Grupo 3
│   ├── fase4_ast/           # Recursos específicos do Grupo 4
│   ├── fase5_lexico/        # Recursos específicos do Grupo 5
│   └── fase6_sintatico/     # Recursos específicos do Grupo 6
├── scripts/                 # Scripts GDScript globais e gerenciadores (.gd)
│   ├── autoload/            # Singletons registrados no Godot (GameManager, SoundManager)
│   └── helpers/             # Utilitários compartilhados (ParserUtils, TokenUtils)
├── assets/                  # Recurso visuais (PNG, SVG)
│   ├── characters/          # Sprites do jogador e inimigos/bugs
│   ├── environments/        # Tilesets e backgrounds
│   ├── tokens/              # Ícones e sprites pedagógicos
│   └── ui/                  # Elementos de interface (botões, painéis)
├── audio/                   # Efeitos sonoros (SFX) e músicas de fundo (BGM)
├── fonts/                   # Fontes TTF/OTF personalizadas
└── docs/                    # Documentação do projeto
```

---

## 🔄 2. Fluxo de Cenas e Comunicação (Autoloads)

Para garantir a coesão entre as fases desenvolvidas por diferentes equipes, o jogo utiliza o padrão **Singleton / Autoload** do Godot.

### Singletons Globais Recomendados:

1. **`GameManager.gd` (`res://scripts/autoload/game_manager.gd`)**
   - Controla o estado atual do jogo (fase atual, pontuação acumulada, vidas restantes).
   - Gerencia transições de cena de forma padronizada.
   - Sinais globais:
     - `score_updated(new_score: int)`
     - `player_lives_changed(current_lives: int)`
     - `level_completed(level_id: int)`

2. **`AudioManager.gd` (`res://scripts/autoload/audio_manager.gd`)**
   - Toca efeitos sonoros (acertos, erros, pulos, cliques) e músicas de fundo sem interromper as transições de cena.

3. **`PedagogicalFeedback.gd` (`res://scripts/autoload/pedagogical_feedback.gd`)**
   - Modal global para exibição de explicações didáticas em caso de erro ou ao interagir com dicas.

---

## 📝 3. Padronização de Nomenclatura

Para evitar conflitos durante a integração de código:

- **Pastas e Arquivos:** `snake_case` (ex: `fase1_tokens.tscn`, `token_manager.gd`).
- **Nós da Cena (Nodes):** `PascalCase` (ex: `Player`, `TokenContainer`, `ScoreLabel`).
- **Variáveis e Funções:** `snake_case` (ex: `var player_score`, `func check_token_type()`).
- **Constantes:** `UPPER_SNAKE_CASE` (ex: `MAX_LIVES = 3`, `TOKEN_TYPE_KEYWORD = "KEYWORD"`).
- **Sinais:** `snake_case` no passado (ex: `token_collected`, `answer_submitted`).

---

## 🎨 4. Diretrizes de Interface, HUD e Protótipo Visual

- **Instanciação Comum:** Todas as fases devem instanciar a cena comum do HUD (`res://scenes/common/hud.tscn`) em vez de recriar barras de vida e pontuação próprias.
- **Resolução Base:** A resolução base do projeto deve seguir **1920x1080** ou **1280x720** com modo de estiramento `canvas_items` habilitado no `project.godot`.
- **Esquema Visual do Menu Principal (Conforme Protótipo Oficial):**
  - **Título estilizado:** `COMPILER` (Branco com contorno) + `{</>}` (Verde `#34A853`) + `EDU` (Amarelo `#FBBC05`) + `GAME` (Azul `#4285F4`).
  - **Faixa Roxa (Ribbon Banner):** `APRENDA COMPILADORES JOGANDO!` sob o título.
  - **Botões Coloridos com Ícone + Título + Subtítulo:**
    - 🟢 **JOGAR:** Verde (`#34A853`) | *INICIAR A AVENTURA*
    - 🔵 **FASES:** Azul (`#4285F4`) | *ESCOLHER FASE*
    - 🟣 **APRENDER:** Roxo (`#8A2BE2`) | *CONCEITOS*
    - 🟠 **CRÉDITOS:** Laranja (`#E67E22`) | *SOBRE A EQUIPE*
  - **Painel de Mundos (Cards Didáticos 1 a 6):**
    - Card 1 (Verde) - *Reino dos Tokens*
    - Card 2 (Azul) - *Vale do Scanner*
    - Card 3 (Amarelo) - *Caverna do Parser*
    - Card 4 (Roxo) - *Floresta da Árvore Sintática*
    - Card 5 (Vermelho Alerta) - *Castelo dos Erros Léxicos*
    - Card 6 (Vinho Sombrio) - *Fortaleza dos Erros Sintáticos*
  - **Barra Superior (TopBar):** Botões escuros arredondados (`⚙️ CONFIGURAÇÕES`, `🏆 RANKING`, `📖 TUTORIAL`).
  - **Rodapé:** Banner inferior identificando o projeto da AEX UENP e versão (`v1.0.0`).
