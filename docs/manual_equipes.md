# 👥 Manual das Equipes e Fluxo de Trabalho

Este manual estabelece as diretrizes de trabalho em equipe, papéis dos integrantes e fluxo de controle de versão (Git) para o desenvolvimento do **Compiler Edu Game** na AEX da UENP.

---

## 🎭 1. Distribuição dos Grupos e Papéis

O projeto é dividido em **6 grupos**, onde cada grupo é responsável por uma fase do jogo correspondente a uma etapa ou conceito da compilação:

| Grupo | Fase | Tema Pedagógico | Pasta no Projeto |
|---|---|---|---|
| **Grupo 1** | Reino dos Tokens | Análise e classificação de Tokens | `scenes/fase1_tokens/` |
| **Grupo 2** | Vale do Scanner | Sequenciamento e fluxo do Scanner | `scenes/fase2_scanner/` |
| **Grupo 3** | Caverna do Parser | Validação sintática e gramáticas | `scenes/fase3_parser/` |
| **Grupo 4** | Floresta da AST | Construção de Árvores Sintáticas | `scenes/fase4_ast/` |
| **Grupo 5** | Castelo dos Erros Léxicos | Identificação de caracteres inválidos | `scenes/fase5_lexico/` |
| **Grupo 6** | Fortaleza dos Erros Sintáticos | Correção de erros sintáticos / Compiler Bug | `scenes/fase6_sintatico/` |

---

## 🛠️ 2. Papéis dentro de cada Grupo

Cada integrante do grupo deve assumir uma ou mais funções específicas:

1. **Líder de Equipe:** Garante as entregas no prazo, faz a ponte com o professor/orientador e organiza as reuniões.
2. **Programador GDScript:** Implementa a lógica das mecânicas, controle de nós e integração com os Autoloads do Godot.
3. **Designer de Interface (UI/UX):** Desenvolve e organiza a cena visual no Godot, layout das telas e usabilidade.
4. **Responsável Pedagógico:** Elabora as questões, desafios teóricos, explicações de erros e mensagens didáticas.
5. **Testador / QA:** Executa a fase, valida comportamentos inesperados e garante que não haja bugs travando o progresso.
6. **Documentador:** Registra reuniões, prepara os relatos de AEX e atualiza a documentação da fase.

---

## 🔀 3. Fluxo de Trabalho no Git e GitHub

Para evitar conflitos nos arquivos do Godot (`.tscn` e `.godot`), siga rigorosamente as regras abaixo:

### Convenção de Branches
- `main`: Branch estável e testada. Ninguém faz commit diretamente na `main`.
- `develop`: Branch de integração das fases.
- `feature/faseX-nome-do-recurso`: Branches de trabalho de cada grupo.
  - *Exemplo:* `feature/fase1-sistema-colecao` ou `feature/fase4-arrastar-nos`.

### Regras de Ouro
1. **Isolamento de Arquivos:** Trabalhe **somente** dentro da pasta atribuída ao seu grupo (ex: `scenes/fase1_tokens/`). Não edite scripts globais ou arquivos de outros grupos sem combinar previamente.
2. **Commits Pequenos e Frequentes:** Escreva mensagens claros no imperativo (ex: `Adiciona mecanica de pulo na fase 1` ou `Corrige colisao do token operador`).
3. **Pull Requests (PR):**
   - Ao concluir uma funcionalidade, abra um Pull Request da sua branch para a `develop`.
   - O PR deve ser revisado por pelo menos 1 membro de outra equipe ou pelo líder geral antes de ser aceito.
