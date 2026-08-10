# 🎮 Compiler Edu Game

> **Aprenda Compiladores Jogando!**

Jogo educativo desenvolvido como **Atividade Curricular de Extensão (AEX)** do curso de **Ciência da Computação da UENP**, com o objetivo de ensinar conceitos fundamentais de **Compiladores** de forma interativa, lúdica e acessível.

O jogador entra no universo de um compilador e precisa superar diferentes desafios relacionados à análise léxica e sintática para avançar pelas fases.

---

## 🎯 Objetivo

O **Compiler Edu Game** busca transformar conceitos tradicionalmente abstratos da disciplina de Compiladores em experiências práticas de aprendizagem.

Durante o jogo, o jogador poderá aprender conceitos como:

- Tokens;
- Análise léxica;
- Scanner;
- Parser;
- Análise sintática;
- Árvore Sintática Abstrata (AST);
- Erros léxicos;
- Erros sintáticos.

A proposta é utilizar elementos de jogos de plataforma, ação e quebra-cabeças para tornar o aprendizado mais intuitivo e divertido.

---

## 🎓 Projeto de Extensão

O projeto possui caráter extensionista e será desenvolvido para utilização com a comunidade externa, especialmente:

- estudantes do Ensino Fundamental e Médio;
- estudantes de cursos técnicos;
- estudantes iniciantes em programação;
- professores interessados em utilizar recursos lúdicos no ensino de Computação.

O jogo poderá ser utilizado em:

- oficinas;
- eventos de extensão;
- feiras de ciências;
- atividades em escolas;
- minicursos;
- demonstrações acadêmicas.

---

# 🕹️ Conceito do Jogo

O jogador controla um personagem que foi transportado para dentro de um compilador.

Para conseguir avançar, deverá atravessar diferentes mundos relacionados às etapas do processo de compilação.

```text
                    COMPILER EDU GAME

                           ↓

                  ┌─────────────────┐
                  │ Reino dos Tokens│
                  └────────┬────────┘
                           ↓
                  ┌─────────────────┐
                  │  Vale do Scanner│
                  └────────┬────────┘
                           ↓
                  ┌─────────────────┐
                  │  Caverna Parser │
                  └────────┬────────┘
                           ↓
                  ┌─────────────────┐
                  │   Floresta AST  │
                  └────────┬────────┘
                           ↓
                  ┌─────────────────┐
                  │ Castelo Léxico  │
                  └────────┬────────┘
                           ↓
                  ┌─────────────────┐
                  │ Fortaleza       │
                  │ Sintática       │
                  └─────────────────┘
```

Cada fase apresenta uma mecânica diferente relacionada ao conteúdo estudado.

---

# 🗺️ Fases

## 1️⃣ Reino dos Tokens

### Caça aos Tokens

O jogador percorre uma fase de plataforma e deve identificar corretamente os diferentes tipos de tokens.

Exemplos:

- palavras-chave;
- identificadores;
- números;
- operadores.

### Mecânica

O jogador pode pular sobre ou coletar os tokens corretos.

Por exemplo:

```text
int soma = a + 10;
```

O desafio pode solicitar:

> Colete apenas os operadores.

O jogador deverá identificar:

```text
=
+
```

Acertos geram pontos e erros podem resultar na perda de vidas.

---

## 2️⃣ Vale do Scanner

### Organizando os Tokens

O jogador precisa compreender como o scanner transforma o código-fonte em uma sequência de tokens.

Uma das mecânicas propostas é organizar os tokens na ordem correta.

Exemplo:

```text
int soma = a + b;
```

Transformação:

```text
KEYWORD
   ↓
IDENTIFIER
   ↓
ASSIGN
   ↓
IDENTIFIER
   ↓
OPERATOR
   ↓
IDENTIFIER
```

Outra possibilidade é utilizar uma mecânica de ação na qual o jogador deve atingir os tokens na sequência correta.

---

## 3️⃣ Caverna do Parser

### Desafio da Gramática

O jogador deverá verificar se uma sequência de tokens está de acordo com as regras da linguagem.

Exemplo:

```text
if ( x > 0 )
```

O jogador deverá decidir se a sequência é válida.

A fase poderá utilizar:

- quebra-cabeças;
- cartas;
- blocos;
- organização de tokens;
- desafios de múltipla escolha.

---

## 4️⃣ Floresta da AST

### Construindo a Árvore Sintática

O jogador deverá montar uma **Árvore Sintática Abstrata (AST)**.

Exemplo:

```text
a + b * c
```

Uma representação simplificada:

```text
        +
       / \
      a   *
         / \
        b   c
```

O desafio consiste em posicionar corretamente os nós da árvore.

---

## 5️⃣ Castelo dos Erros Léxicos

### Encontre os caracteres inválidos!

O jogador deverá identificar caracteres que não pertencem ao conjunto válido da linguagem.

Exemplo:

```c
int @idade = 10;
```

O caractere:

```text
@
```

pode ser apresentado como um inimigo.

A mecânica pode utilizar:

- plataforma;
- combate;
- tiro;
- obstáculos;
- coleta;
- identificação de caracteres.

O jogador deve eliminar os caracteres inválidos sem atingir os válidos.

---

## 6️⃣ Fortaleza dos Erros Sintáticos

### Derrote o Compiler Bug!

Nesta fase o jogador deverá identificar e corrigir erros sintáticos.

Exemplo:

```c
if (x > 0
```

Problema:

```text
Parêntese não fechado.
```

Outro exemplo:

```c
while {
```

Problema:

```text
Condição ausente.
```

O jogador poderá encontrar os erros durante a exploração da fase e corrigi-los para abrir portas, derrotar inimigos ou avançar pelo castelo.

### 🐉 Chefe Final

Como desafio final, o jogador poderá enfrentar o:

> **Compiler Bug**

O chefe apresenta diferentes códigos contendo erros.

Para derrotá-lo, o jogador precisa identificar e corrigir os problemas.

---

# 🎮 Mecânicas

O projeto poderá utilizar diferentes mecânicas de jogos:

- 🏃 Plataforma 2D;
- 🦘 Pulo;
- 🎯 Tiro;
- 🧩 Quebra-cabeças;
- 🃏 Cartas;
- 🧱 Blocos;
- 🖱️ Drag & Drop;
- ⚔️ Combate;
- 🏆 Pontuação;
- ❤️ Sistema de vidas;
- ⏱️ Cronômetro;
- 💡 Sistema de dicas;
- ⭐ Combos;
- 🏅 Conquistas.

A mecânica deve estar sempre relacionada ao **objetivo pedagógico da fase**.

---

# 🧠 Aprendizagem

O jogo não deve apenas testar o jogador.

Cada erro deverá gerar algum tipo de feedback.

Por exemplo:

> ❌ Resposta incorreta!

> `@` não é um símbolo válido para um identificador nessa linguagem.

Dessa forma, o jogador aprende enquanto joga.

---

# 🏆 Sistema de Pontuação

Uma sugestão inicial:

| Ação | Pontos |
|---|---:|
| Resposta correta | +10 |
| Conclusão da fase | +20 |
| Concluir sem erros | +30 |
| Combo de acertos | Bônus |
| Erro | -5 |
| Usar dica | -5 |
| Pular desafio | -20 |

Os valores poderão ser ajustados durante os testes.

---

# 🛠️ Tecnologias

## Godot Engine

O jogo será desenvolvido utilizando a **Godot Engine**, uma engine gratuita e open source adequada para desenvolvimento de jogos 2D.

[Godot Engine](https://godotengine.org/pt-br/?utm_source=chatgpt.com)

### Linguagem

**GDScript**

---

# 📚 Material de Apoio

Tutorial utilizado como apoio para aprendizagem da Godot:

[Playlist – Tutorial Godot do Zero 2025](https://www.youtube.com/playlist?list=PLNlPErl_v81vNINVVotsh0nYBBSp4LEgY&utm_source=chatgpt.com)

---

# 📁 Estrutura do Projeto

A estrutura proposta para o projeto é:

```text
compiler-edu-game/
│
├── scenes/
│   ├── menu/
│   ├── fase1_tokens/
│   ├── fase2_scanner/
│   ├── fase3_parser/
│   ├── fase4_ast/
│   ├── fase5_lexico/
│   └── fase6_sintatico/
│
├── scripts/
│
├── assets/
│   ├── characters/
│   ├── environments/
│   ├── tokens/
│   └── ui/
│
├── audio/
│
├── fonts/
│
├── docs/
│
└── README.md
```

---

# 👥 Organização das Equipes

Cada grupo é responsável pelo desenvolvimento de uma fase.

| Grupo | Fase | Responsabilidade |
|---|---|---|
| Grupo 1 | Caça aos Tokens | Análise de Tokens |
| Grupo 2 | Scanner | Organização e identificação de Tokens |
| Grupo 3 | Erro Léxico | Identificação de erros léxicos |
| Grupo 4 | Erro Sintático | Identificação de erros sintáticos |
| Grupo 5 | Parser | Análise sintática |
| Grupo 6 | AST | Construção da árvore sintática |

---

# 👨‍💻 Organização do Trabalho

Cada grupo possui responsabilidades distribuídas como em uma equipe de desenvolvimento de software.

| Função | Responsabilidade |
|---|---|
| Líder | Organização e acompanhamento |
| Interface | Desenvolvimento da interface |
| Programação | Implementação da lógica |
| Conteúdo | Conteúdo pedagógico |
| Testes | Testes e validação |
| Documentação | Registro do desenvolvimento |

Um mesmo estudante poderá exercer mais de uma função quando necessário.

---

# 🔀 Integração entre as Equipes

Como todos os grupos trabalham no mesmo projeto, algumas regras devem ser seguidas.

### Cada grupo deve:

- trabalhar preferencialmente dentro da pasta da sua fase;
- evitar modificar arquivos de outros grupos sem comunicação;
- utilizar nomes de arquivos padronizados;
- documentar alterações importantes;
- testar a própria fase antes da integração;
- comunicar mudanças que afetem outras fases.

### Padrão de nomes

Utilizar `snake_case`:

```text
fase1_tokens.tscn
token_manager.gd
player_controller.gd
game_manager.gd
```

---

# 🌳 Fluxo de Cenas

A estrutura geral deverá seguir uma lógica semelhante a:

```text
Main Menu
    │
    ├── Tutorial
    │
    ├── Fase 1
    │
    ├── Fase 2
    │
    ├── Fase 3
    │
    ├── Fase 4
    │
    ├── Fase 5
    │
    └── Fase 6
             │
             ↓
        Resultado Final
```

---

# 🎨 Identidade Visual

Todas as fases devem manter uma identidade visual comum.

Recomendações:

- mesma fonte;
- padrão semelhante de botões;
- HUD consistente;
- sistema de cores coerente;
- mesmo personagem principal;
- estilo visual 2D;
- feedback visual para acertos e erros.

Cada grupo poderá criar o cenário e os elementos próprios de sua fase.

---

# 🧪 Testes

Cada grupo deverá testar sua fase considerando:

### Funcionalidade

- O jogo inicia corretamente?
- O personagem responde aos comandos?
- As colisões funcionam?
- A pontuação está correta?
- A fase pode ser concluída?

### Pedagógico

- O conteúdo está correto?
- O jogador entende o objetivo?
- O feedback explica os erros?
- A mecânica realmente ensina o conceito?

### Usabilidade

- Os textos são legíveis?
- Os controles são fáceis de entender?
- O jogador sabe o que fazer?
- A dificuldade é adequada ao público?

---

# 📸 Evidências da AEX

Durante o desenvolvimento e aplicação do projeto deverão ser registradas evidências, como:

- screenshots do jogo;
- vídeos;
- fotos das oficinas;
- lista de participantes;
- materiais didáticos;
- versões do software;
- relatórios;
- feedback dos participantes.

Esses registros poderão ser utilizados na documentação da atividade extensionista.

---

# 🚀 Roadmap

## Fase 1 – Planejamento

- [x] Definição do tema
- [x] Divisão dos grupos
- [x] Definição das fases
- [x] Escolha da Godot
- [ ] Definição da identidade visual

## Fase 2 – Protótipos

- [ ] Protótipo da Fase 1
- [ ] Protótipo da Fase 2
- [ ] Protótipo da Fase 3
- [ ] Protótipo da Fase 4
- [ ] Protótipo da Fase 5
- [ ] Protótipo da Fase 6

## Fase 3 – Desenvolvimento

- [ ] Implementação das fases
- [ ] Personagem
- [ ] Interface
- [ ] Sistema de pontuação
- [ ] Sistema de vidas
- [ ] Sistema de fases
- [ ] Sons e efeitos

## Fase 4 – Integração

- [ ] Menu principal
- [ ] Integração das fases
- [ ] Sistema de progressão
- [ ] Tela final
- [ ] Créditos

## Fase 5 – Testes

- [ ] Testes técnicos
- [ ] Testes de jogabilidade
- [ ] Testes pedagógicos
- [ ] Correção de problemas

## Fase 6 – Extensão

- [ ] Oficina com comunidade
- [ ] Coleta de feedback
- [ ] Registro das atividades
- [ ] Relatório final

---

# 🌟 Desafios Extras

Os grupos poderão adicionar funcionalidades além do mínimo necessário:

- 🏅 Sistema de conquistas;
- ⭐ Ranking;
- 💡 Sistema de dicas;
- 🎵 Música e efeitos sonoros;
- 🎬 Cutscenes;
- 🎨 Animações;
- 🌎 Tradução para inglês;
- 📊 Estatísticas do jogador;
- 🧠 Modo desafio;
- ⏱️ Modo contra o tempo;
- 👾 Novos inimigos;
- 🐉 Chefes;
- 📚 Glossário de Compiladores.

---

# 🤝 Contribuição

Este é um projeto colaborativo.

Antes de realizar alterações que afetem outras fases:

1. Converse com o grupo responsável.
2. Faça as alterações em sua branch.
3. Teste localmente.
4. Registre um commit descritivo.
5. Abra um Pull Request.
6. Solicite revisão quando necessário.

---

# 📌 Repositório

Projeto desenvolvido no GitHub:

**compiler-edu-game**

---

# 🎓 Contexto Acadêmico

**Curso:** Ciência da Computação  
**Instituição:** Universidade Estadual do Norte do Paraná – UENP  
**Atividade:** Atividade Curricular de Extensão – AEX  
**Área:** Ciência da Computação / Compiladores

---

# 👨‍🏫 Equipe

Projeto desenvolvido pelos estudantes da disciplina de Compiladores, sob orientação docente.

Os nomes dos integrantes e respectivas funções serão registrados na documentação do projeto.

---

# 📄 Licença

A licença do projeto será definida pela equipe responsável pelo projeto.

---

## 💡 Ideia central

> **Transformar Compiladores em uma aventura.**

O objetivo do projeto não é apenas criar um jogo.

É utilizar o desenvolvimento de software para **ensinar Computação à comunidade**, aproximando a universidade das escolas e tornando conceitos complexos mais acessíveis por meio da gamificação.