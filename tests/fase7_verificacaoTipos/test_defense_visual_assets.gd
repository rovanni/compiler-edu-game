## test_defense_visual_assets.gd
##
## Teste dos 6 ícones de torre recebidos do Anibal (GDD seção 5-B.5) — todos
## carregam, e o mapeamento tipo -> arte (DefenseVisualAssets) bate certo,
## inclusive a torre especial "Erro de Tipo" (TowerDefenseSystem.DEFESA_ERRO).
##
## Como rodar (na pasta do projeto):
##   godot --headless --script res://scripts/tests/test_defense_visual_assets.gd
extends SceneTree

const DataTypes = preload("res://scripts/fase7_verificacaoTipos/data_types.gd")
const TowerDefenseSystem = preload("res://scripts/fase7_verificacaoTipos/tower_defense_system.gd")
const DefenseVisualAssets = preload("res://scripts/fase7_verificacaoTipos/defense_visual_assets.gd")

var _total := 0
var _falhas := 0


func _check(descricao: String, condicao: bool) -> void:
	_total += 1
	if condicao:
		print("  ✓ %s" % descricao)
	else:
		_falhas += 1
		print("  ✗ FALHOU: %s" % descricao)


func _init() -> void:
	print("=== Teste: ícones de torre da Torre de Defesa (GDD 5-B.5) ===\n")

	var tipos := [
		[DataTypes.Tipo.INT, "int"], [DataTypes.Tipo.FLOAT, "float"],
		[DataTypes.Tipo.STRING, "String"], [DataTypes.Tipo.BOOLEAN, "boolean"],
		[DataTypes.Tipo.CHAR, "char"], [TowerDefenseSystem.DEFESA_ERRO, "Erro de Tipo"],
	]

	var tamanho_referencia := Vector2.ZERO
	for par in tipos:
		var tipo = par[0]
		var nome: String = par[1]
		var textura := DefenseVisualAssets.textura_torre(tipo)
		_check("torre '%s' carrega uma textura" % nome, textura != null)
		if textura != null:
			if tamanho_referencia == Vector2.ZERO:
				tamanho_referencia = textura.get_size()
			_check("torre '%s' tem o mesmo tamanho das outras (%s)" % [nome, tamanho_referencia], textura.get_size() == tamanho_referencia)

	_check("tipo sem defesa mapeada retorna null (não quebra)", DefenseVisualAssets.textura_torre(999) == null)

	# Uso real: um Sprite2D pegando a torre certa por tipo, igual a cena vai fazer.
	var sprite := Sprite2D.new()
	sprite.texture = DefenseVisualAssets.textura_torre(DataTypes.Tipo.FLOAT)
	root.add_child(sprite)
	_check("Sprite2D aceita a textura da torre sem erro", sprite.texture != null)
	sprite.queue_free()

	print("")
	if _falhas == 0:
		print("✓ TODOS OS %d TESTES PASSARAM" % _total)
	else:
		print("✗ %d de %d TESTES FALHARAM" % [_falhas, _total])

	quit(1 if _falhas > 0 else 0)
