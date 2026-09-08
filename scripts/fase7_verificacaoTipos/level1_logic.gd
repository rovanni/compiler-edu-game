## level1_logic.gd
##
## A lógica pura do Nível 1 — Reconhecimento de Tipos (GDD seção 7, linha
## "Nível 1"). Diferente das linhas de instrução dos Níveis 2-4, aqui não
## tem tabuleiro/grid_system: é só "esse valor caiu na coluna certa?" —
## então este script não usa GridSystem, só TypeChecker.
##
## Como type_checker.gd e grid_system.gd, é um componente de DADOS: não
## sabe de Sprite/Control/input/queda visual. Quem controla a cena
## (scripts/levels/level1_controller.gd) chama `julgar()` quando a peça
## chega embaixo na coluna escolhida pelo jogador, e escuta os sinais
## pra atualizar pontuação, barra e mensagem na tela.
class_name Level1Logic
extends RefCounted

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TypeChecker = preload("res://scripts/fase7_verificacaoTipos/type_checker.gd")

## Emitido a cada peça julgada (acertou ou errou).
signal peca_avaliada(resultado: Dictionary)

## Emitido sempre que a barra do compilador muda.
signal compilador_atualizado(percentual: float)

## Emitido quando a barra chega a 0% — GDD 8.3, "COMPILATION FAILED".
signal compilacao_falhou

## As colunas do Nível 1, na mesma ordem da tabela do GDD seção 7:
## INT | FLOAT | String | BOOLEAN | CHAR.
const COLUNAS := [
	DataTypes.Tipo.INT,
	DataTypes.Tipo.FLOAT,
	DataTypes.Tipo.STRING,
	DataTypes.Tipo.BOOLEAN,
	DataTypes.Tipo.CHAR,
]

## Regras de pontuação/barra deste nível (GDD 8.1/8.2 adaptado — o Nível 1
## não tem tabuleiro/linhas, então a barra aqui é simulada por acerto/erro
## em vez de "linhas livres / total". Valores ajustáveis; documentados
## para ficar fácil rebalancear depois de testar com o público-alvo.)
const PONTOS_ACERTO := 100
const BARRA_GANHO_ACERTO := 10.0
const BARRA_PERDA_ERRO := 20.0

var pontuacao: int = 0
var percentual_barra: float = 100.0


## As colunas disponíveis neste nível, na ordem em que devem aparecer na tela.
func colunas_disponiveis() -> Array:
	return COLUNAS.duplicate()

## Julga se `texto_peca` (ex.: "18", "\"Maria\"", "true", "7.5", "'A'") foi
## solto na coluna certa. `coluna_escolhida` é um DataTypes.Tipo — a coluna
## onde o jogador soltou a peça. Atualiza pontuação/barra e devolve:
##   { "acertou": bool, "tipo_correto": DataTypes.Tipo (-1 se inválido),
##     "coluna_escolhida": DataTypes.Tipo, "texto": String, "mensagem": String }
func julgar(coluna_escolhida: int, texto_peca: String) -> Dictionary:
	var identificado := TypeChecker.identificar_tipo(texto_peca)
	var tipo_correto: int = identificado["tipo"] if identificado["valido"] else -1
	var acertou: bool = identificado["valido"] and coluna_escolhida == tipo_correto

	var resultado := {
		"acertou": acertou,
		"tipo_correto": tipo_correto,
		"coluna_escolhida": coluna_escolhida,
		"texto": texto_peca,
		"mensagem": "",
	}

	if acertou:
		resultado["mensagem"] = "✓ Tipo válido"
		pontuacao += PONTOS_ACERTO
		percentual_barra = min(100.0, percentual_barra + BARRA_GANHO_ACERTO)
	else:
		if not identificado["valido"]:
			resultado["mensagem"] = identificado.get("erro", "não reconheci esse valor")
		else:
			resultado["mensagem"] = "%s é %s, não %s" % [
				texto_peca, DataTypes.nome_tipo(tipo_correto), DataTypes.nome_tipo(coluna_escolhida)
			]
		percentual_barra = max(0.0, percentual_barra - BARRA_PERDA_ERRO)

	peca_avaliada.emit(resultado)
	compilador_atualizado.emit(percentual_barra)

	if percentual_barra <= 0.0:
		compilacao_falhou.emit()

	return resultado
