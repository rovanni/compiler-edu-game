# 📑 Documento de Engenharia de Software – Fase 5: Castelo Léxico

> **Grupo:** 5  
> **Fase:** Fase 5 – Castelo Léxico (Erros Léxicos)  
> **Tema:** Identificação, Recuperação e Tratamento de Erros Léxicos  

---

## 1. 🎯 Descrição Geral e Objetivos Pedagógicos

### 1.1 Visão Geral da Fase
No **Castelo Léxico**, o jogador deve defender o castelo enfrentando monstros e códigos corrompidos, identificando caracteres inválidos, delimitadores malformados e tokens ilegais que violam as regras do analisador léxico.

### 1.2 Conceito de Compiladores Abordado
- **Erros Léxicos**: Símbolos não reconhecidos pelo alfabeto da linguagem (ex: `@`, `~`, `$`), strings não fechadas (`"texto`), caracteres de escape inválidos, números mal formatados (`12.34.56`).
- **Pânico e Recuperação Léxica**: Descarte de caracteres inválidos até encontrar um delimitador conhecido.

---

> [!TIP]
> **Atenção Grupo 5:** Utilizem o [Template Base de Documentação](../templates/template_documentacao_fase.md) para completar as seções de Requisitos (RF/RNF/RP), Casos de Teste e Modelagem do Godot. Salvem imagens e diagramas na subpasta local `docs/fase5_erroLexico/img/`.
