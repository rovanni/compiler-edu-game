# 🧪 Guia e Checklists de Testes

Este guia orienta os testadores e desenvolvedores na validação do **Compiler Edu Game**, cobrindo os pilares funcional, pedagógico e de usabilidade.

---

## 🎯 1. Tipos de Testes Habilitados

```text
               ┌────────────────────────┐
               │    TESTES DO JOGO      │
               └───────────┬────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
  │  TÉCNICO /   │  │ PEDAGÓGICO / │  │ USABILIDADE /│
  │  FUNCIONAL   │  │ DIDÁTICO     │  │  EXPERIÊNCIA │
  └──────────────┘  └──────────────┘  └──────────────┘
```

---

## ✅ 2. Checklist Técnico e Funcional

Antes de enviar uma fase para a branch `develop`, a equipe de testes deve verificar:

- [ ] **Execução Sem Erros:** O Godot lança algum aviso (*warning*) ou erro (*script error*) no console ao iniciar ou finalizar a cena?
- [ ] **Controles:** O personagem responde aos comandos de teclado/gamepad sem *lag* ou travamentos?
- [ ] **Colisões:** O personagem atravessa paredes ou chãos indesejados?
- [ ] **Reinício:** Ao perder todas as vidas, o botão de "Tentar Novamente" recarrega a cena corretamente?
- [ ] **Transição:** Ao vencer a fase, o sinal para chamar a próxima fase através do `GameManager` é emitido com sucesso?
- [ ] **Pontuação:** O HUD reflete os pontos ganhos/perdidos imediatamente?

---

## 📚 3. Checklist Pedagógico

Garante a precisão do conteúdo didático e o alinhamento com a disciplina de Compiladores:

- [ ] **Conceitos Corretos:** Todos os tokens, gramáticas e exemplos de códigos exibidos estão teoricamente corretos segundo a literatura de Compiladores?
- [ ] **Clareza nos Erros:** As mensagens explicativas para respostas erradas são compreensíveis para um aluno sem conhecimento prévio profundo?
- [ ] **Dicas Úteis:** As dicas orientam o raciocínio sem entregar a resposta final?
- [ ] **Nível de Dificuldade:** A curva de aprendizado permite que o jogador aprenda antes de ser exigido em ritmo acelerado?

---

## ♿ 4. Checklist de Usabilidade e Acessibilidade

Garante que o jogo seja agradável e jogável por qualquer público:

- [ ] **Legibilidade:** O tamanho das fontes e o contraste das cores permitem ler as instruções facilmente?
- [ ] **Interface Limpa:** O HUD não polui a visualização do ambiente de jogo?
- [ ] **Feedback Sonoro:** Acertos e erros possuem efeitos sonoros nítidos e distintos?
- [ ] **Volume Configurável:** O jogo permite pausar e ajustar o volume dos áudios?
