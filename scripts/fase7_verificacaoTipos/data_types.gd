## data_types.gd
##
## Definições compartilhadas de tipos e categorias usadas pela fase de
## Verificação de Tipos (TypeTris). Não depende de nenhum nó de cena —
## é só um dicionário de constantes/enums reutilizado por type_checker.gd,
## por LevelData e por qualquer script de UI que precise mostrar nomes
## de tipo pro jogador.
##
## Ver docs/GDD_TypeTris.md, seção 6.1 (tipos suportados) e seção 5.2
## (categorias de peça).
class_name DataTypes
extends RefCounted

## Os 5 tipos de dado no escopo desta fase (GDD seção 6.1).
enum Tipo {
	INT,
	FLOAT,
	STRING,
	BOOLEAN,
	CHAR,
}

## As 5 categorias de peça que caem no tabuleiro (GDD seção 5.2).
enum Categoria {
	TIPO,
	VALOR,
	VARIAVEL,
	OPERADOR,
	SIMBOLO,
}

## Nome do tipo como aparece no jogo (mesma grafia usada no GDD:
## "int", "float", "String", "boolean", "char").
static func nome_tipo(tipo: int) -> String:
	match tipo:
		Tipo.INT:
			return "int"
		Tipo.FLOAT:
			return "float"
		Tipo.STRING:
			return "String"
		Tipo.BOOLEAN:
			return "boolean"
		Tipo.CHAR:
			return "char"
		_:
			return "?"

## Nome da categoria, só para debug/labels de editor.
static func nome_categoria(categoria: int) -> String:
	match categoria:
		Categoria.TIPO:
			return "TIPO"
		Categoria.VALOR:
			return "VALOR"
		Categoria.VARIAVEL:
			return "VARIAVEL"
		Categoria.OPERADOR:
			return "OPERADOR"
		Categoria.SIMBOLO:
			return "SIMBOLO"
		_:
			return "?"
