## defense_visual_assets.gd
##
## Ponto único de referência entre "tipo de defesa" (DataTypes.Tipo ou
## TowerDefenseSystem.DEFESA_ERRO) e o arquivo de arte da torre (GDD seção
## 5-B.5) — pra quando a cena visual da Torre de Defesa for montada, não
## ficar um `match` de caminho espalhado pelo controller. Puramente
## utilitário: nenhuma lógica de jogo aqui, só o mapeamento tipo -> asset.
class_name DefenseVisualAssets
extends RefCounted

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TowerDefenseSystem = preload("res://scripts/fase7_verificacaoTipos/tower_defense_system.gd")

const _CAMINHOS := {
	DataTypes.Tipo.INT: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_int.png",
	DataTypes.Tipo.FLOAT: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_float.png",
	DataTypes.Tipo.STRING: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_string.png",
	DataTypes.Tipo.BOOLEAN: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_boolean.png",
	DataTypes.Tipo.CHAR: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_char.png",
}
const _CAMINHO_ERRO := "res://assets/fase7_verificacaoTipos/sprites/towers/torre_erro_tipo.png"

# v2.12 (animação das torres, sprites recebidos do Anibal): mapeamento
# tipo -> SpriteFrames com as animações "parado" (1 quadro) e "ataque" (5
# quadros: parado -> carregando -> disparo -> pico -> volta ao normal, GDD
# seção 5-B.5). Mesmo padrão de "ponto único de mapeamento" de cima, só que
# pra animação em vez de textura estática — quem monta a torre construída
# no campo usa isto; a paleta continua com o ícone estático de
# `textura_torre()` (não faz sentido animar um ícone de seleção de 60x60).
const _ANIMACOES := {
	DataTypes.Tipo.INT: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_int_anim.tres",
	DataTypes.Tipo.FLOAT: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_float_anim.tres",
	DataTypes.Tipo.STRING: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_string_anim.tres",
	DataTypes.Tipo.BOOLEAN: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_boolean_anim.tres",
	DataTypes.Tipo.CHAR: "res://assets/fase7_verificacaoTipos/sprites/towers/torre_char_anim.tres",
}
const _ANIMACAO_ERRO := "res://assets/fase7_verificacaoTipos/sprites/towers/torre_erro_tipo_anim.tres"

# Cor pra recolorir (via `modulate`) o inimigo genérico (GDD 5-B.5 —
# "recolorir no código") de acordo com a defesa correta pra ele. Validado
# visualmente no screenshot de composição (torres + caminho + inimigo
# recolorido) antes de montar a cena de verdade.
const _CORES := {
	DataTypes.Tipo.INT: Color(0.35, 0.6, 1.0),
	DataTypes.Tipo.FLOAT: Color(0.3, 0.9, 0.75),
	DataTypes.Tipo.STRING: Color(1.0, 0.82, 0.25),
	DataTypes.Tipo.BOOLEAN: Color(1.0, 0.5, 0.15),
	DataTypes.Tipo.CHAR: Color(0.78, 0.35, 1.0),
}
const _COR_ERRO := Color(1.0, 0.25, 0.2)

## Caminho `res://` do ícone da torre pro `tipo_defesa` dado (um
## DataTypes.Tipo ou TowerDefenseSystem.DEFESA_ERRO). Retorna "" se o tipo
## não tiver arte mapeada (não deveria acontecer com os 6 tipos válidos).
static func caminho_torre(tipo_defesa) -> String:
	if tipo_defesa == TowerDefenseSystem.DEFESA_ERRO:
		return _CAMINHO_ERRO
	return _CAMINHOS.get(tipo_defesa, "")

## Carrega a Texture2D já pronta pro `tipo_defesa` dado (ou null se não
## encontrar o tipo ou o arquivo).
static func textura_torre(tipo_defesa) -> Texture2D:
	var caminho := caminho_torre(tipo_defesa)
	if caminho == "":
		return null
	return load(caminho)

## Caminho `res://` do recurso SpriteFrames (animações "parado"/"ataque")
## da torre pro `tipo_defesa` dado. Retorna "" se não tiver animação
## mapeada pra esse tipo.
static func caminho_animacao_torre(tipo_defesa) -> String:
	if tipo_defesa == TowerDefenseSystem.DEFESA_ERRO:
		return _ANIMACAO_ERRO
	return _ANIMACOES.get(tipo_defesa, "")

## Carrega o SpriteFrames já pronto (animações "parado" e "ataque") pro
## `tipo_defesa` dado, ou null se não encontrar.
static func sprite_frames_torre(tipo_defesa) -> SpriteFrames:
	var caminho := caminho_animacao_torre(tipo_defesa)
	if caminho == "":
		return null
	return load(caminho)

## Cor (pra `modulate`) do inimigo cuja defesa correta é `tipo_defesa` — o
## mesmo inimigo genérico recolorido por tipo (GDD 5-B.5), inclusive pro
## caso especial de expressão inválida (TowerDefenseSystem.DEFESA_ERRO).
## Retorna branco (sem recolorir) se o tipo não tiver cor mapeada.
static func cor_defesa(tipo_defesa) -> Color:
	if tipo_defesa == TowerDefenseSystem.DEFESA_ERRO:
		return _COR_ERRO
	return _CORES.get(tipo_defesa, Color(1, 1, 1))
