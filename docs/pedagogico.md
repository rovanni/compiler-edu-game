# 🧠 Diretrizes Pedagógicas e Design de Aprendizagem

O **Compiler Edu Game** tem como objetivo transformar o ensino de **Compiladores** em uma experiência gamificada, acessível a estudantes da educação básica, técnica e acadêmica.

---

## 🎯 1. Objetivos Pedagógicos por Fase

| Fase | Título | Conceito Acadêmico | Mecânica do Jogo | Objetivo de Aprendizagem |
|---|---|---|---|---|
| **Fase 1** | Reino dos Tokens | Análise Léxica / Tipos de Tokens | Plataforma 2D / Coleta seletiva | Identificar e diferenciar Palavras-chave, Identificadores, Operadores e Literais. |
| **Fase 2** | Vale do Scanner | Funcionamento do Scanner | Sequenciamento / Drag & Drop / Alvo | Compreender que o código-fonte é lido caractere por caractere para formar uma fita de tokens. |
| **Fase 3** | Caverna do Parser | Análise Sintática / Regras Gramaticais | Quebra-cabeça / Seleção de caminhos | Diferenciar sequências de tokens válidas e inválidas de acordo com regras de produção. |
| **Fase 4** | Floresta da AST | Árvores Sintáticas Abstratas | Construção visual de árvore (Drag & Drop) | Entender a hierarquia e precedência dos operadores na montagem da AST. |
| **Fase 5** | Castelo dos Erros Léxicos | Tratamento de Erros Léxicos | Combate / Destruição de alvos | Reconhecer símbolos e caracteres não pertencentes ao alfabeto da linguagem. |
| **Fase 6** | Fortaleza dos Erros Sintáticos | Erros Sintáticos / Boss Final | Resolução de enigmas / Debugging | Identificar falhas de estrutura (ex: parênteses desbalanceados, comandos incompletos) e corrigi-los. |

---

## 💡 2. Sistema de Feedback Educativo

Um princípio fundamental do jogo é que **o erro é uma oportunidade de aprendizado**. O jogo nunca deve apenas punir o jogador sem explicar o motivo.

### Padrão de Feedback por Erro:
1. **Notificação Visual:** Animação de erro amigável (ex: balão de dúvida ou aviso).
2. **Explicação Clara:** Exibir uma mensagem simples e sem termos excessivamente complexos.
   - *Exemplo Ruim:* "Erro sintático na linha 1: Esperado token RPAREN."
   - *Exemplo Bom:* "Ops! Falta fechar o parêntese `)` para indicar onde a condição do `if` termina."
3. **Dica Construtiva:** Oferecer o botão "Ver Dica" que orienta o jogador a encontrar a solução correta sem dar a resposta direta.

---

## 🏆 3. Sistema de Pontuação e Recompensas

A tabela abaixo define os critérios padrão para incentivar a precisão e o aprendizado contínuo:

| Ação do Jogador | Ajuste na Pontuação | Impacto |
|---|---|---|
| Resposta/Ação Correta | **+10 pontos** | Ganha experiência |
| Conclusão da Fase | **+50 pontos** | Desbloqueia próxima fase |
| Concluir sem cometer erros | **+30 bônus** | Estrela de Ouro |
| Combo de acertos seguidos | **Bônus progressivo (+2, +4, +8)** | Multiplicador |
| Resposta Incorreta | **-5 pontos** | Perde 1 vida (se aplicável) |
| Solicitar Dica Pedagógica | **-5 pontos** | Permite avançar |
| Pular Desafio | **-20 pontos** | Progresso sem bônus |
