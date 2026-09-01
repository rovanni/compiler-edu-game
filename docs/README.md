# 📚 Central de Documentação do Compiler Edu Game

Bem-vindo à central de documentação do **Compiler Edu Game**, um jogo educativo desenvolvido como **Atividade Curricular de Extensão (AEX)** do curso de Ciência da Computação da **Universidade Estadual do Norte do Paraná (UENP)**.

---

> [!IMPORTANT]
> ## ⚠️ DIRETRIZ OBRIGATÓRIA DE ORGANIZAÇÃO PARA OS GRUPOS
> 
> **Cada grupo de estudantes é responsável por UMA FASE do jogo.**
> 
> Para manter o repositório limpo, padronizado e sem conflitos no Git:
> 1. **NÃO SALVE ARQUIVOS SOLTOS NA RAIZ DE `docs/`**: Todos os documentos, relatórios, atas e evidências da sua fase devem ficar **estritamente dentro da subpasta da respectiva fase** (`docs/faseX_nome/`).
> 2. **IMAGENS E PRINTS NA SUBPASTA LOCAL**: Nenhuma imagem deve ser salva na raiz ou em pastas genéricas. Todas as capturas de tela, diagramas e fotos da sua fase devem ficar na pasta `docs/faseX_nome/img/`.
> 3. **PADRÃO DE NOMES DE ARQUIVOS**:
>    - Documentação técnica e de engenharia de software da fase: `docs/faseX_nome/README.md`
>    - Relatórios e evidências de extensão AEX: `docs/faseX_nome/evidencias_aex.md`
>    - Imagens e capturas: `docs/faseX_nome/img/`

---

## 🗂️ Estrutura de Diretórios da Documentação

```text
docs/
├── README.md                      # Central de documentação (este arquivo)
│
├── 🏛️ DOCUMENTOS GLOBAIS (Coordenação / Transversais)
│   ├── arquitetura.md             # Arquitetura no Godot 4, autoloads, cenas e sinais
│   ├── engenharia_software.md     # Diretrizes gerais de Engenharia de Software
│   ├── manual_equipes.md          # Manual de trabalho em equipe, fluxo Git e branches
│   ├── pedagogico.md              # Mapeamento pedagógico e didática de compiladores
│   ├── aex_evidencias.md          # Guia geral e modelos de coleta de evidências da AEX
│   ├── guia_testes.md             # Checklists globais de testes e QA
│   ├── creditos_assets.md         # Créditos gerais de arte, áudio e fontes
│   └── templates/                 # Modelos padronizados para cópia
│       └── template_documentacao_fase.md
│
└── 🎮 PASTAS DEDICADAS POR FASE (Grupos 1 a 6)
    ├── fase1_tokens/              # Grupo 1: Reino dos Tokens (Análise Léxica)
    │   ├── README.md              # Documentação técnica e pedagógica da Fase 1
    │   ├── evidencias_aex.md      # Registro de evidências e oficinas da Fase 1
    │   └── img/                   # Imagens e diagramas exclusivos da Fase 1
    │
    ├── fase2_scanner/             # Grupo 2: Vale do Scanner (Autômatos & Scanner)
    │   ├── README.md              # Documentação técnica e pedagógica da Fase 2
    │   ├── evidencias_aex.md      # Registro de evidências e oficinas da Fase 2
    │   └── img/                   # Imagens e diagramas exclusivos da Fase 2
    │
    ├── fase3_parser/              # Grupo 3: Caverna do Parser (Análise Sintática)
    │   ├── README.md              # Documentação técnica e pedagógica da Fase 3
    │   ├── evidencias_aex.md      # Registro de evidências e oficinas da Fase 3
    │   └── img/                   # Imagens e diagramas exclusivos da Fase 3
    │
    ├── fase4_ast/                 # Grupo 4: Floresta AST (Árvores Sintáticas)
    │   ├── README.md              # Documentação técnica e pedagógica da Fase 4
    │   ├── evidencias_aex.md      # Registro de evidências e oficinas da Fase 4
    │   └── img/                   # Imagens e diagramas exclusivos da Fase 4
    │
    ├── fase5_erroLexico/          # Grupo 5: Castelo Léxico (Erros Léxicos)
    │   ├── README.md              # Documentação técnica e pedagógica da Fase 5
    │   ├── evidencias_aex.md      # Registro de evidências e oficinas da Fase 5
    │   └── img/                   # Imagens e diagramas exclusivos da Fase 5
    │
    └── fase6_sintatico/           # Grupo 6: Fortaleza Sintática (Erros Sintáticos)
        ├── README.md              # Documentação técnica e pedagógica da Fase 6
        ├── evidencias_aex.md      # Registro de evidências e oficinas da Fase 6
        └── img/                   # Imagens e diagramas exclusivos da Fase 6
```

---

## 🗺️ Tabela de Documentação das Fases

| Fase | Tema / Conceito | Grupo Responsável | Documento Técnico | Evidências AEX | Imagens |
|---|---|:---:|:---:|:---:|:---:|
| **Fase 1: Reino dos Tokens** | Análise Léxica & Classificação de Tokens | **Grupo 1** | [fase1_tokens/README.md](fase1_tokens/README.md) | [fase1_tokens/evidencias_aex.md](fase1_tokens/evidencias_aex.md) | `fase1_tokens/img/` |
| **Fase 2: Vale do Scanner** | Autômatos, Buffer e Montagem de Tokens | **Grupo 2** | [fase2_scanner/README.md](fase2_scanner/README.md) | [fase2_scanner/evidencias_aex.md](fase2_scanner/evidencias_aex.md) | `fase2_scanner/img/` |
| **Fase 3: Caverna do Parser** | Análise Sintática, Regras e Produções | **Grupo 3** | [fase3_parser/README.md](fase3_parser/README.md) | [fase3_parser/evidencias_aex.md](fase3_parser/evidencias_aex.md) | `fase3_parser/img/` |
| **Fase 4: Floresta AST** | Árvore Sintática Abstrata (AST) e Expressões | **Grupo 4** | [fase4_ast/README.md](fase4_ast/README.md) | [fase4_ast/evidencias_aex.md](fase4_ast/evidencias_aex.md) | `fase4_ast/img/` |
| **Fase 5: Castelo Léxico** | Identificação e Tratamento de Erros Léxicos | **Grupo 5** | [fase5_erroLexico/README.md](fase5_erroLexico/README.md) | [fase5_erroLexico/evidencias_aex.md](fase5_erroLexico/evidencias_aex.md) | `fase5_erroLexico/img/` |
| **Fase 6: Fortaleza Sintática** | Diagnóstico e Correção de Erros Sintáticos | **Grupo 6** | [fase6_sintatico/README.md](fase6_sintatico/README.md) | [fase6_sintatico/evidencias_aex.md](fase6_sintatico/evidencias_aex.md) | `fase6_sintatico/img/` |

---

## 📖 Documentos Globais do Projeto

Estes arquivos ficam na raiz de `docs/` e servem como referência para todos os participantes:

| Documento | Descrição | Público Principal |
|---|---|---|
| [📐 Engenharia de Software](engenharia_software.md) | Especificação de requisitos (RF/RNF/RP), modelagem, testes e matriz RACI. | **Todos os Grupos / Alunos** |
| [📑 Template de Documentação](templates/template_documentacao_fase.md) | Modelo base para preenchimento da documentação técnica da fase. | **Alunos / Grupos 1 a 6** |
| [📖 Arquitetura Técnica](arquitetura.md) | Estrutura no Godot 4, padrão de cenas, autoloads, sinais e padronização GDScript. | Programadores & Designers |
| [👥 Manual das Equipes](manual_equipes.md) | Divisão de funções, fluxo Git, regras de contribuição e convenções de branches. | Todos os estudantes da AEX |
| [🧠 Diretrizes Pedagógicas](pedagogico.md) | Mapeamento de conteúdos de Compiladores por fase, feedback didático e pontuação. | Conteúdo & Professores |
| [📸 Guia de Evidências AEX](aex_evidencias.md) | Orientações e templates para coleta de evidências extensionistas (oficinas, fotos, questionários). | Líderes & Documentadores |
| [🧪 Guia de Testes](guia_testes.md) | Checklists de testes funcionais, de usabilidade e pedagógicos para cada fase. | Equipes de Teste & QA |
| [🎨 Créditos de Assets](creditos_assets.md) | Licenças e atribuições de artes, fontes e efeitos sonoros utilizados no projeto. | Todos |

---

## 🛠️ Passo a Passo para os Grupos

### 1. Iniciar ou Atualizar a Documentação da sua Fase
1. Acesse a pasta da sua fase (ex: `docs/faseX_nome/`).
2. Se ainda não preencheu, copie o conteúdo de [templates/template_documentacao_fase.md](templates/template_documentacao_fase.md) para o arquivo `README.md` da sua pasta.
3. Preencha todos os tópicos:
   - Integrantes e funções (Líder, Programador, Designer, QA, Pedagógico);
   - Requisitos Funcionais (RF), Não-Funcionais (RNF) e Pedagógicos (RP);
   - Game Design (GDD da fase, pontuações, vidas, vitória e derrota);
   - Árvore de nós do Godot e scripts utilizados;
   - Casos de teste e plano de validação.

### 2. Adicionar Imagens e Diagramas
- Salve todas as imagens em `docs/faseX_nome/img/nome_da_imagem.png`.
- No seu `README.md` ou `evidencias_aex.md`, faça o link relativo:
  ```markdown
  ![Tela de Gameplay](img/gameplay.png)
  ```

### 3. Registrar Evidências da AEX
- Sempre que realizar uma sessão de testes, oficina com alunos do Ensino Médio ou validação externa, atualize o arquivo `docs/faseX_nome/evidencias_aex.md`.
- Inclua data, local, número de participantes, feedbacks recebidos e fotos da atividade (em `img/`).

---

## ✅ Checklist de Entrega da Fase

Antes de abrir um Pull Request (PR) ou concluir uma sprint, certifique-se de que:

- [ ] A documentação em `docs/faseX_nome/README.md` está atualizada com as mecânicas reais implementadas.
- [ ] Não há arquivos soltos na raiz de `docs/`.
- [ ] Todas as imagens referenciadas estão dentro de `docs/faseX_nome/img/`.
- [ ] O arquivo `docs/faseX_nome/evidencias_aex.md` contém os registros de testes e oficinas.
- [ ] O código segue os padrões descritos em [arquitetura.md](arquitetura.md).
